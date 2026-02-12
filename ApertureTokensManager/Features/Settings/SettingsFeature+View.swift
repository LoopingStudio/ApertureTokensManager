import ComposableArchitecture
import SwiftUI

// MARK: - Settings View

@ViewAction(for: SettingsFeature.self)
struct SettingsView: View {
  @Bindable var store: StoreOf<SettingsFeature>
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    NavigationSplitView {
      sidebarContent
    } detail: {
      detailContent
    }
    .frame(minWidth: UIConstants.Size.windowMinWidth, minHeight: UIConstants.Size.settingsMinHeight)
    .onAppear { send(.onAppear) }
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button("Fermer") {
          dismiss()
        }
      }
    }
    .alert("Réinitialiser toutes les données ?", isPresented: $store.showResetConfirmation) {
      Button("Annuler", role: .cancel) {
        send(.dismissResetConfirmation)
      }
      Button("Réinitialiser", role: .destructive) {
        send(.confirmResetAllData)
      }
    } message: {
      Text("Cette action supprimera la base de design system, les historiques, les filtres et les paramètres. Cette action est irréversible.")
    }
  }
}

// MARK: - Sidebar

extension SettingsView {
  private var sidebarContent: some View {
    List(selection: $store.selectedSection.sending(\.view.sectionSelected)) {
      ForEach(SettingsFeature.SettingsSection.allCases, id: \.self) { section in
        Label {
          Text(section.rawValue)
        } icon: {
          sectionIcon(for: section)
        }
        .tag(section)
      }
    }
    .listStyle(.sidebar)
    .navigationTitle("Paramètres")
  }
  
  @ViewBuilder
  private func sectionIcon(for section: SettingsFeature.SettingsSection) -> some View {
    switch section {
    case .export:
      Image(systemName: "square.and.arrow.up")
    case .history:
      Image(systemName: "clock.arrow.circlepath")
    case .data:
      Image(systemName: "folder")
    case .logs:
      Image(systemName: "doc.text.magnifyingglass")
    case .about:
      Image(systemName: "info.circle")
    }
  }
}

// MARK: - Detail Content

extension SettingsView {
  @ViewBuilder
  private var detailContent: some View {
    switch store.selectedSection {
    case .export: exportSection
    case .history: historySection
    case .data: dataSection
    case .logs: logsSection
    case .about: aboutSection
    }
  }
  
  private func sectionHeader(title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: UIConstants.Spacing.small) {
      Text(title)
        .font(.title2)
        .fontWeight(.semibold)
      
      Text(subtitle)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.bottom, UIConstants.Spacing.medium)
  }
}

// MARK: - Export Section

extension SettingsView {
  private var exportSection: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        sectionHeader(
          title: "Filtres d'export",
          subtitle: "Ces filtres s'appliquent lors de l'export vers Xcode. Les tokens correspondants seront exclus des fichiers générés."
        )
        
        GroupBox("Filtres par pattern") {
          VStack(alignment: .leading, spacing: UIConstants.Spacing.large) {
            Toggle(isOn: $store.tokenFilters.excludeTokensStartingWithHash) {
              VStack(alignment: .leading, spacing: UIConstants.Spacing.small) {
                Text("Exclure tokens commençant par #")
                Text("Exclut les tokens primitifs (ex: #blue-500)")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            }
            
            Divider()
            
            Toggle(isOn: $store.tokenFilters.excludeTokensEndingWithHover) {
              VStack(alignment: .leading, spacing: UIConstants.Spacing.small) {
                Text("Exclure tokens finissant par _hover")
                Text("Exclut les états hover des tokens")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            }
          }
          .padding(.vertical, UIConstants.Spacing.medium)
        }
        
        GroupBox("Filtres par groupe") {
          Toggle(isOn: $store.tokenFilters.excludeUtilityGroup) {
            VStack(alignment: .leading, spacing: 4) {
              Text("Exclure groupe Utility")
              Text("Exclut le groupe utilitaire complet")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
          .padding(.vertical, UIConstants.Spacing.medium)
        }
      }
      .padding()
    }
  }
}

// MARK: - History Section

extension SettingsView {
  private var historySection: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        sectionHeader(
          title: "Historique",
          subtitle: "Configurez le nombre d'entrées conservées dans l'historique des imports et comparaisons."
        )
        
        GroupBox("Configuration") {
          Stepper(value: $store.appSettings.maxHistoryEntries, in: 5...50, step: 5) {
            HStack {
              Text("Entrées maximum")
              Spacer()
              Text("\(store.appSettings.maxHistoryEntries)")
                .foregroundStyle(.secondary)
                .monospacedDigit()
            }
          }
          .padding(.vertical, UIConstants.Spacing.medium)
        }
        
        GroupBox("Statistiques actuelles") {
          VStack(spacing: UIConstants.Spacing.large) {
            HStack {
              Text("Imports")
              Spacer()
              Text("\(store.importHistory.count)")
                .monospacedDigit()
                .foregroundStyle(.secondary)
            }
            
            Divider()
            
            HStack {
              Text("Comparaisons")
              Spacer()
              Text("\(store.comparisonHistory.count)")
                .monospacedDigit()
                .foregroundStyle(.secondary)
            }
          }
          .padding(.vertical, UIConstants.Spacing.medium)
        }
      }
      .padding()
    }
  }
}

// MARK: - Data Section

extension SettingsView {
  private var dataSection: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        sectionHeader(
          title: "Gestion des données",
          subtitle: "Gérez les données stockées par l'application."
        )
        
        GroupBox("Stockage") {
          Button {
            send(.openDataFolderButtonTapped)
          } label: {
            Label("Ouvrir le dossier de données", systemImage: "folder")
          }
          .buttonStyle(.adaptiveGlass(.regular))
          .padding(.vertical, UIConstants.Spacing.medium)
        }
        
        GroupBox("Réinitialisation") {
          VStack(alignment: .leading, spacing: UIConstants.Spacing.large) {
            Text("Réinitialiser toutes les données")
              .font(.headline)
            
            Text("Cette action supprimera :")
              .font(.caption)
              .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
              Label("Base de design system", systemImage: "paintpalette")
              Label("Historique des imports", systemImage: "clock.arrow.circlepath")
              Label("Historique des comparaisons", systemImage: "arrow.left.arrow.right")
              Label("Dossiers d'analyse", systemImage: "folder.badge.gearshape")
              Label("Filtres d'export", systemImage: "line.3.horizontal.decrease.circle")
              Label("Paramètres de l'application", systemImage: "gear")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            
            Button(role: .destructive) {
              send(.resetAllDataButtonTapped)
            } label: {
              Label("Réinitialiser", systemImage: "trash")
            }
            .buttonStyle(.adaptiveGlass(.regular.tint(.red)))
          }
          .padding(.vertical, UIConstants.Spacing.medium)
        }
      }
      .padding()
    }
  }
}

// MARK: - Logs Section

extension SettingsView {
  private var logsSection: some View {
    VStack(alignment: .leading, spacing: 0) {
      logsHeader
      
      Divider()
      
      logsContent
    }
  }
  
  private var logsHeader: some View {
    VStack(alignment: .leading, spacing: UIConstants.Spacing.extraLarge) {
      HStack {
        sectionHeader(
          title: "Journal d'activité",
          subtitle: "Consultez les événements et actions récentes de l'application."
        )
        
        Spacer()
        
        Text("\(store.logCount) entrées")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      
      HStack(spacing: UIConstants.Spacing.medium) {
        Button {
          send(.refreshLogsButtonTapped)
        } label: {
          Label("Actualiser", systemImage: "arrow.clockwise")
        }
        .buttonStyle(.adaptiveGlass(.regular))
        .disabled(store.isLoadingLogs)
        
        Button {
          send(.clearLogsButtonTapped)
        } label: {
          Label("Vider", systemImage: "trash")
        }
        .buttonStyle(.adaptiveGlass(.regular.tint(.red)))
        .disabled(store.logEntries.isEmpty)
        
        Button {
          send(.exportLogsButtonTapped)
        } label: {
          Label("Exporter", systemImage: "square.and.arrow.up")
        }
        .buttonStyle(.adaptiveGlass(.regular.tint(.blue)))
        .disabled(store.logEntries.isEmpty || store.isExportingLogs)
      }
    }
    .padding()
  }
  
  @ViewBuilder
  private var logsContent: some View {
    if store.isLoadingLogs {
      ProgressView("Chargement des logs...")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else if store.logEntries.isEmpty {
      ContentUnavailableView {
        Label("Aucun log", systemImage: "doc.text")
      } description: {
        Text("Les logs apparaîtront ici au fur et à mesure de l'utilisation de l'application.")
      }
      .frame(maxHeight: .infinity)
    } else {
      ScrollViewReader { proxy in
        List(store.logEntries) { entry in
          LogEntryRow(entry: entry)
            .id(entry.id)
        }
        .listStyle(.plain)
        .onAppear {
          if let lastEntry = store.logEntries.last {
            proxy.scrollTo(lastEntry.id, anchor: .bottom)
          }
        }
      }
    }
  }
}

// MARK: - About Section

extension SettingsView {
  private var aboutSection: some View {
    VStack(spacing: UIConstants.Spacing.section) {
      Spacer()
      
      Image(systemName: "paintpalette.fill")
        .font(.system(size: UIConstants.Size.colorSquare))
        .foregroundStyle(.tint)
      
      Text("Aperture Tokens Manager")
        .font(.title)
        .fontWeight(.bold)
      
      Text("Version 1.0.0")
        .font(.subheadline)
        .foregroundStyle(.secondary)
      
      Divider()
        .frame(width: UIConstants.Size.dividerWidth)
      
      VStack(spacing: UIConstants.Spacing.medium) {
        Text("Gérez vos design tokens Figma")
        Text("Importez, comparez, analysez et exportez")
      }
      .font(.body)
      .foregroundStyle(.secondary)
      
      Button {
        send(.openTutorialButtonTapped)
      } label: {
        Label("Revoir le guide de démarrage", systemImage: "questionmark.circle")
      }
      .buttonStyle(.adaptiveGlass())
      
      Spacer()
      
      Text("© 2026 Picta")
        .font(.caption)
        .foregroundStyle(.tertiary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
  }
}

// MARK: - Preview

#if DEBUG
#Preview {
  SettingsView(
    store: Store(initialState: SettingsFeature.State.initial) {
      SettingsFeature()
    }
  )
}
#endif
