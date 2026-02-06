import SwiftUI
import ComposableArchitecture
import UniformTypeIdentifiers

@ViewAction(for: CompareFeature.self)
struct CompareView: View {
  @Bindable var store: StoreOf<CompareFeature>
  @Namespace private var tabNamespace

  var body: some View {
    VStack(spacing: 0) {
      header
      if store.changes != nil {
        comparisonContent
      } else {
        fileSelectionArea
      }
    }
    .animation(.easeInOut, value: store.oldFile.isLoaded && store.newFile.isLoaded)
    .animation(.easeInOut(duration: 0.25), value: store.selectedTab)
  }

  // MARK: - Header

  private var header: some View {
    VStack(spacing: 12) {
      HStack {
        Text("Comparaison de Tokens")
          .font(.title)
          .fontWeight(.bold)

        Spacer()

        if store.changes != nil {
          HStack(spacing: 8) {
            Button("Nouvelle Comparaison") { send(.resetComparison) }
              .controlSize(.small)
            Button("Exporter pour Notion") { send(.exportToNotionTapped) }
              .controlSize(.small)
              .buttonStyle(.borderedProminent)
          }
          .transition(.asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .opacity
          ))
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

  // MARK: - File Selection Area

  private var fileSelectionArea: some View {
    VStack(spacing: 24) {
      HStack(spacing: 24) {
        DropZone(
          title: "Ancienne Version",
          subtitle: "Glissez le fichier JSON de l'ancienne version ici",
          isLoaded: store.oldFile.isLoaded,
          isLoading: store.oldFile.isLoading,
          primaryColor: .blue,
          isFromBase: store.oldFile.isFromBase,
          fileName: store.oldFile.fileName,
          onDrop: { providers in
            guard let provider = providers.first else { return false }
            send(.fileDroppedWithProvider(.old, provider))
            return true
          },
          onSelectFile: { send(.selectFileTapped(.old)) },
          onRemove: store.oldFile.isLoaded ? { send(.removeFile(.old)) } : nil,
          metadata: store.oldFile.metadata
        )

        VStack(spacing: 8) {
          Image(systemName: "arrow.right")
            .font(.title2)
            .foregroundStyle(.secondary)

          if store.oldFile.isLoaded && store.newFile.isLoaded {
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
          isLoaded: store.newFile.isLoaded,
          isLoading: store.newFile.isLoading,
          primaryColor: .green,
          fileName: store.newFile.fileName,
          onDrop: { providers in
            guard let provider = providers.first else { return false }
            send(.fileDroppedWithProvider(.new, provider))
            return true
          },
          onSelectFile: { send(.selectFileTapped(.new)) },
          onRemove: store.newFile.isLoaded ? { send(.removeFile(.new)) } : nil,
          metadata: store.newFile.metadata
        )
      }
      .overlay(alignment: .bottom) {
        if store.oldFile.isLoaded && store.newFile.isLoaded {
          Button("Comparer les fichiers") {
            send(.compareButtonTapped)
          }
          .buttonStyle(.borderedProminent)
          .controlSize(.large)
          .offset(y: 48)
          .transition(.push(from: .top).combined(with: .opacity))
        }
      }
      
      if !store.comparisonHistory.isEmpty && !store.oldFile.isLoaded && !store.newFile.isLoaded {
        ComparisonHistoryView(
          history: store.comparisonHistory,
          onEntryTapped: { send(.historyEntryTapped($0)) },
          onRemove: { send(.removeHistoryEntry($0)) },
          onClear: { send(.clearHistory) }
        )
        .frame(maxWidth: 600)
        .padding(.top, 16)
      }
    }
    .padding()
    .frame(maxHeight: .infinity)
    .onAppear { send(.onAppear) }
  }

  // MARK: - Comparison Content

  private var comparisonContent: some View {
    VStack(spacing: 0) {
      tabs
      Divider()
      if let changes = store.changes {
        tabContent(for: store.selectedTab, changes: changes)
          .padding()
          .id(store.selectedTab)
          .transition(.opacity.combined(with: .scale(scale: 0.95)))
//          .transition(.asymmetric(
//            insertion: .opacity.combined(with: .move(edge: .trailing)),
//            removal: .opacity.combined(with: .move(edge: .leading))
//          ))
      }
    }
    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: store.selectedTab)
  }

  // MARK: - Tabs

  private var tabs: some View {
    HStack {
      ForEach(CompareFeature.ComparisonTab.allCases, id: \.self) { tab in
        Button {
          send(.tabTapped(tab))
        } label: {
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
          .background {
            if store.selectedTab == tab {
              RoundedRectangle(cornerRadius: 8)
                .fill(Color.accentColor.opacity(0.1))
                .matchedGeometryEffect(id: "activeTab", in: tabNamespace)
            }
          }
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
    case .overview: "Résumé"
    case .added: "\(changes.added.count)"
    case .removed: "\(changes.removed.count)"
    case .modified: "\(changes.modified.count)"
    }
  }

  // MARK: - Tab Content

  @ViewBuilder
  private func tabContent(for tab: CompareFeature.ComparisonTab, changes: ComparisonChanges) -> some View {
    switch tab {
    case .overview:
      OverviewView(
        changes: changes,
        oldFileMetadata: store.oldFile.metadata,
        newFileMetadata: store.newFile.metadata,
        onTabTapped: { send(.tabTapped($0)) }
      )

    case .added:
      AddedTokensView(tokens: changes.added)

    case .removed:
      RemovedTokensView(
        tokens: changes.removed,
        changes: store.changes,
        newVersionTokens: store.newFile.tokens,
        onSuggestReplacement: { removedPath, replacementPath in
          send(.suggestReplacement(removedTokenPath: removedPath, replacementTokenPath: replacementPath))
        },
        onAcceptAutoSuggestion: { removedPath in
          send(.acceptAutoSuggestion(removedTokenPath: removedPath))
        },
        onRejectAutoSuggestion: { removedPath in
          send(.rejectAutoSuggestion(removedTokenPath: removedPath))
        }
      )

    case .modified:
      ModifiedTokensView(
        modifications: changes.modified,
        newVersionTokens: store.newFile.tokens
      )
    }
  }
}
// MARK: - Previews

#if DEBUG
#Preview("Empty State") {
  CompareView(
    store: Store(initialState: .initial) {
      CompareFeature()
    }
  )
  .frame(width: 900, height: 600)
}

#Preview("Files Loaded") {
  CompareView(
    store: Store(initialState: CompareFeature.State(
      oldFile: CompareFeature.FileState(
        tokens: PreviewData.rootNodes,
        metadata: TokenMetadata(
          exportedAt: "2026-02-04 10:00:00",
          timestamp: 1738663200,
          version: "2.0.0",
          generator: "Figma"
        ),
        url: nil,
        isLoaded: true,
        isLoading: false
      ),
      newFile: CompareFeature.FileState(
        tokens: PreviewData.rootNodes,
        metadata: PreviewData.metadata,
        url: nil,
        isLoaded: true,
        isLoading: false
      ),
      changes: nil,
      loadingError: nil,
      selectedChange: nil,
      selectedTab: .overview
    )) {
      CompareFeature()
    }
  )
  .frame(width: 900, height: 600)
}

#Preview("Comparison Results") {
  CompareView(
    store: Store(initialState: CompareFeature.State(
      oldFile: CompareFeature.FileState(
        tokens: PreviewData.rootNodes,
        metadata: TokenMetadata(
          exportedAt: "2026-02-04 10:00:00",
          timestamp: 1738663200,
          version: "2.0.0",
          generator: "Figma"
        ),
        url: nil,
        isLoaded: true,
        isLoading: false
      ),
      newFile: CompareFeature.FileState(
        tokens: PreviewData.rootNodes,
        metadata: PreviewData.metadata,
        url: nil,
        isLoaded: true,
        isLoading: false
      ),
      changes: PreviewData.comparisonChanges,
      loadingError: nil,
      selectedChange: nil,
      selectedTab: .overview
    )) {
      CompareFeature()
    }
  )
  .frame(width: 900, height: 600)
}

#Preview("Removed Tokens with Suggestions") {
  CompareView(
    store: Store(initialState: CompareFeature.State(
      oldFile: CompareFeature.FileState(
        tokens: PreviewData.rootNodes,
        metadata: TokenMetadata(
          exportedAt: "2026-02-04 10:00:00",
          timestamp: 1738663200,
          version: "2.0.0",
          generator: "Figma"
        ),
        url: nil,
        isLoaded: true,
        isLoading: false
      ),
      newFile: CompareFeature.FileState(
        tokens: PreviewData.rootNodes,
        metadata: PreviewData.metadata,
        url: nil,
        isLoaded: true,
        isLoading: false
      ),
      changes: PreviewData.comparisonChanges,
      loadingError: nil,
      selectedChange: nil,
      selectedTab: .removed
    )) {
      CompareFeature()
    }
  )
  .frame(width: 900, height: 600)
}
#endif

