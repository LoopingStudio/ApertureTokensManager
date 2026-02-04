import SwiftUI
import ComposableArchitecture
import UniformTypeIdentifiers

@ViewAction(for: CompareFeature.self)
struct CompareView: View {
  @Bindable var store: StoreOf<CompareFeature>
  
  var body: some View {
    VStack(spacing: 0) {
      header
      if store.changes != nil {
        comparisonContent
      } else {
        fileSelectionArea
      }
    }
    .animation(.easeInOut, value: store.isOldFileLoaded && store.isNewFileLoaded)
  }
  
  private var header: some View {
    VStack(spacing: 12) {
      HStack {
        Text("Comparaison de Tokens")
          .font(.title)
          .fontWeight(.bold)
        
        Spacer()
        
        if store.changes != nil {
          Button("Nouvelle Comparaison") { send(.resetComparison) }
            .controlSize(.small)
          
          Button("Exporter pour Notion") { send(.exportToNotionTapped) }
            .controlSize(.small)
            .buttonStyle(.borderedProminent)
        }
      }
      
      if let error = store.loadingError {
        Text(error)
          .foregroundStyle(.red)
          .font(.caption)
      }
      
      Divider()
    }
    .padding()
  }
  
  private var fileSelectionArea: some View {
    VStack(spacing: 24) {
      HStack(spacing: 24) {
        DropZone(
          title: "Ancienne Version",
          subtitle: "Glissez le fichier JSON de l'ancienne version ici",
          isLoaded: store.isOldFileLoaded,
          isLoading: store.isLoadingOldFile,
          primaryColor: .blue,
          onDrop: { providers in
            guard let provider = providers.first else { return false }
            send(.fileDroppedWithProvider(.old, provider))
            return true
          },
          onSelectFile: { send(.selectFileTapped(.old)) },
          onRemove: store.isOldFileLoaded ? { send(.removeFile(.old)) } : nil,
          metadata: store.oldFileMetadata
        )
        
        VStack(spacing: 8) {
          Image(systemName: "arrow.right")
            .font(.title2)
            .foregroundStyle(.secondary)
          
          if store.isOldFileLoaded && store.isNewFileLoaded {
            Button {
              send(.switchFiles)
            } label: {
              Image(systemName: "arrow.left.arrow.right")
                .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Échanger les fichiers")
          }
        }
        .frame(width: 32)

        DropZone(
          title: "Nouvelle Version", 
          subtitle: "Glissez le fichier JSON de la nouvelle version ici",
          isLoaded: store.isNewFileLoaded,
          isLoading: store.isLoadingNewFile,
          primaryColor: .green,
          onDrop: { providers in
            guard let provider = providers.first else { return false }
            send(.fileDroppedWithProvider(.new, provider))
            return true
          },
          onSelectFile: { send(.selectFileTapped(.new)) },
          onRemove: store.isNewFileLoaded ? { send(.removeFile(.new)) } : nil,
          metadata: store.newFileMetadata
        )
      }
      .overlay(alignment: .bottom) {
        if store.isOldFileLoaded && store.isNewFileLoaded {
          Button("Comparer les fichiers") {
            send(.compareButtonTapped)
          }
          .buttonStyle(.borderedProminent)
          .controlSize(.large)
          .offset(y: 48)
          .transition(.push(from: .top).combined(with: .opacity))
        }
      }
    }
    .padding()
    .frame(maxHeight: .infinity)
  }
  
  private var comparisonContent: some View {
    VStack(spacing: 0) {
      // Tabs
      tabs
      Divider()
      // Content area
      if let changes = store.changes {
        tabContent(for: store.selectedTab, changes: changes)
      }
    }
  }

  private var tabs: some View {
    HStack {
      ForEach(CompareFeature.ComparisonTab.allCases, id: \.self) { tab in
        Button(action: { send(.tabTapped(tab)) }) {
          VStack(spacing: 4) {
            Text(tab.rawValue)
              .font(.headline)
              .foregroundStyle(store.selectedTab == tab ? .primary : .secondary)

            if let changes = store.changes {
              Text(countForTab(tab, changes: changes))
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
          .contentShape(.rect)
          .background(
            RoundedRectangle(cornerRadius: 8)
              .fill(store.selectedTab == tab ? Color.accentColor.opacity(0.1) : Color.clear)
          )
          .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
      }

      Spacer()
    }
    .padding(.horizontal)
  }

  private func countForTab(_ tab: CompareFeature.ComparisonTab, changes: ComparisonChanges) -> String {
    switch tab {
    case .overview:
      return "Résumé"
    case .added:
      return "\(changes.added.count)"
    case .removed:
      return "\(changes.removed.count)"
    case .modified:
      return "\(changes.modified.count)"
    }
  }
  
  private func tabContent(for tab: CompareFeature.ComparisonTab, changes: ComparisonChanges) -> some View {
    Group {
      switch tab {
      case .overview:
        overviewContent(changes: changes)
      case .added:
        addedTokensList(tokens: changes.added)
      case .removed:
        removedTokensList(tokens: changes.removed)
      case .modified:
        modifiedTokensList(modifications: changes.modified)
      }
    }
    .padding()
  }
  
  private func overviewContent(changes: ComparisonChanges) -> some View {
    VStack(alignment: .leading, spacing: 20) {
      Text("Résumé des changements")
        .font(.title2)
        .fontWeight(.semibold)
      
      // Informations sur les fichiers
      HStack(spacing: 20) {
        fileInfoCard(
          title: "Ancienne Version",
          metadata: store.oldFileMetadata,
          color: .blue
        )
        
        Image(systemName: "arrow.right")
          .font(.title2)
          .foregroundStyle(.secondary)
        
        fileInfoCard(
          title: "Nouvelle Version",
          metadata: store.newFileMetadata,
          color: .green
        )
      }
      .padding(.bottom, 8)
      
      LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
        summaryCard(
          title: "Tokens Ajoutés",
          count: changes.added.count,
          color: .green,
          icon: "plus.circle.fill"
        ) {
          send(.tabTapped(.added))
        }

        summaryCard(
          title: "Tokens Supprimés", 
          count: changes.removed.count,
          color: .red,
          icon: "minus.circle.fill"
        ) {
          send(.tabTapped(.removed))
        }

        summaryCard(
          title: "Tokens Modifiés",
          count: changes.modified.count,
          color: .orange,
          icon: "pencil.circle.fill"
        ) {
          send(.tabTapped(.modified))
        }
      }
      
      Spacer()
    }
  }
  
  private func summaryCard(
    title: String,
    count: Int,
    color: Color,
    icon: String,
    onTap: @escaping () -> Void
  ) -> some View {
    VStack(spacing: 8) {
      Image(systemName: icon)
        .font(.largeTitle)
        .foregroundStyle(color)
      
      Text("\(count)")
        .font(.title)
        .fontWeight(.bold)
        .foregroundStyle(color)
      
      Text(title)
        .font(.headline)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, minHeight: 120)
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(color.opacity(0.1))
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(color.opacity(0.3), lineWidth: 1)
        )
    )
    .onTapGesture { onTap() }
  }
  
  private func fileInfoCard(title: String, metadata: TokenMetadata?, color: Color) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.headline)
        .foregroundStyle(color)
      
      if let metadata = metadata {
        VStack(alignment: .leading, spacing: 4) {
          Text("Exporté le: \(formatFrenchDate(metadata.exportedAt))")
            .font(.caption)
            .foregroundStyle(.primary)
          
          Text("Version: \(metadata.version)")
            .font(.caption)
            .foregroundStyle(.secondary)
          
          Text("Générateur: \(metadata.generator)")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      } else {
        Text("Pas de métadonnées")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(color.opacity(0.1))
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(color.opacity(0.3), lineWidth: 1)
        )
    )
  }
  
  private func formatFrenchDate(_ dateString: String) -> String {
    // Try to parse common date formats and convert to French format
    let inputFormatter = DateFormatter()
    let outputFormatter = DateFormatter()
    outputFormatter.locale = Locale(identifier: "fr_FR")
    outputFormatter.dateStyle = .medium
    outputFormatter.timeStyle = .short
    
    // Try different input formats
    let formats = [
      "yyyy-MM-dd HH:mm:ss",
      "yyyy-MM-dd'T'HH:mm:ss",
      "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
      "yyyy-MM-dd"
    ]
    
    for format in formats {
      inputFormatter.dateFormat = format
      if let date = inputFormatter.date(from: dateString) {
        return outputFormatter.string(from: date)
      }
    }
    
    // If no format matches, return original string
    return dateString
  }
  
  private func addedTokensList(tokens: [TokenSummary]) -> some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 8) {
        ForEach(tokens) { token in
          tokenSummaryListItem(
            token: token,
            badgeColor: .green,
            badgeText: "AJOUTÉ"
          )
        }
      }
    }
  }
  
  private func removedTokensList(tokens: [TokenSummary]) -> some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 8) {
        ForEach(tokens) { token in
          tokenSummaryListItem(
            token: token,
            badgeColor: .red,
            badgeText: "SUPPRIMÉ"
          )
        }
      }
    }
  }
  
  private func modifiedTokensList(modifications: [TokenModification]) -> some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 8) {
        ForEach(modifications) { modification in
          modificationListItem(modification: modification)
        }
      }
    }
  }
  
  private func tokenSummaryListItem(token: TokenSummary, badgeColor: Color, badgeText: String) -> some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text(token.name)
          .font(.subheadline)
          .fontWeight(.medium)
        
        Text(token.path)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      
      Spacer()
      
      // Prévisualisation des couleurs si disponibles
      if let modes = token.modes {
        VStack(alignment: .trailing, spacing: 8) {
          if let legacy = modes.legacy, let lightValue = legacy.light {
            colorInfoBlock(
              value: lightValue,
              brand: "Legacy"
            )
          }
          if let newBrand = modes.newBrand, let lightValue = newBrand.light {
            colorInfoBlock(
              value: lightValue,
              brand: "New Brand"
            )
          }
        }
      }
      
      Text(badgeText)
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(badgeColor)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(Color(nsColor: .controlBackgroundColor))
    )
  }
  
  private func colorPreview(color: Color, size: CGFloat) -> some View {
    RoundedRectangle(cornerRadius: 4)
      .fill(color)
      .frame(width: size, height: size)
      .overlay(
        RoundedRectangle(cornerRadius: 4)
          .stroke(Color.secondary.opacity(0.3), lineWidth: 0.5)
      )
  }
  
  private func modificationListItem(modification: TokenModification) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text(modification.tokenName)
            .font(.subheadline)
            .fontWeight(.medium)
          
          Text(modification.tokenPath)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        
        Spacer()
        
        Text("MODIFIÉ")
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(.white)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(Color.orange)
          .clipShape(RoundedRectangle(cornerRadius: 4))
      }
      
      VStack(alignment: .leading, spacing: 6) {
        ForEach(modification.colorChanges) { change in
          colorChangeRow(change: change)
        }
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(Color(nsColor: .controlBackgroundColor))
    )
  }
  
  private func colorChangeRow(change: ColorChange) -> some View {
    HStack(spacing: 8) {
      Text("\(change.brandName) • \(change.theme):")
        .font(.caption)
        .fontWeight(.medium)
        .frame(width: 100, alignment: .leading)
      
      // Ancienne couleur
      HStack(spacing: 4) {
        RoundedRectangle(cornerRadius: 4)
          .fill(Color(hex: change.oldColor))
          .frame(width: 20, height: 20)
        Text(change.oldColor)
          .font(.caption)
      }
      
      Image(systemName: "arrow.right")
        .font(.caption)
        .foregroundStyle(.secondary)
      
      // Nouvelle couleur  
      HStack(spacing: 4) {
        RoundedRectangle(cornerRadius: 4)
          .fill(Color(hex: change.newColor))
          .frame(width: 20, height: 20)
        Text(change.newColor)
          .font(.caption)
      }
    }
  }
  
  private func colorInfoBlock(value: TokenValue, brand: String) -> some View {
    VStack(alignment: .trailing, spacing: 2) {
      Text(brand)
        .font(.caption2)
        .fontWeight(.medium)
        .foregroundStyle(.primary)
      
      HStack(spacing: 6) {
        VStack(alignment: .trailing, spacing: 2) {
          Text(value.hex)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
          
          Text(value.primitiveName)
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .lineLimit(1)
        }
        
        RoundedRectangle(cornerRadius: 4)
          .fill(Color(hex: value.hex))
          .frame(width: 24, height: 24)
          .overlay(
            RoundedRectangle(cornerRadius: 4)
              .stroke(Color.secondary.opacity(0.3), lineWidth: 0.5)
          )
      }
    }
  }
}
