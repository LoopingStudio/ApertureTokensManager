import SwiftUI
import ComposableArchitecture

// MARK: - Analysis View

@ViewAction(for: AnalysisFeature.self)
struct AnalysisView: View {
  @Bindable var store: StoreOf<AnalysisFeature>
  @Namespace private var tabNamespace
  @FocusState private var isSearchFocused: Bool

  var body: some View {
    VStack(spacing: 0) {
      header
      if store.report != nil {
        analysisContent
      } else {
        configurationArea
      }
    }
    .animation(.easeInOut, value: store.report != nil)
    .animation(.easeInOut(duration: 0.25), value: store.selectedTab)
    .onAppear { send(.onAppear) }
  }
}

// MARK: - Header

extension AnalysisView {
  private var header: some View {
    VStack(spacing: UIConstants.Spacing.large) {
      HStack {
        Text("Analyse d'Utilisation")
          .font(.title)
          .fontWeight(.bold)

        Spacer()

        if store.report != nil {
          headerButtons
        }
      }

      if let error = store.analysisError {
        Text(error)
          .foregroundStyle(.red)
          .font(.caption)
      }

      Divider()
    }
    .padding()
  }
  
  private var headerButtons: some View {
    HStack(spacing: UIConstants.Spacing.medium) {
      Button {
        send(.exportReportTapped)
      } label: {
        Label("Exporter", systemImage: "square.and.arrow.up")
      }
      .buttonStyle(.adaptiveGlass())
      .controlSize(.small)
      
      Button("Nouvelle Analyse") { send(.clearResultsTapped) }
        .buttonStyle(.adaptiveGlass())
        .controlSize(.small)
    }
    .transition(.asymmetric(
      insertion: .scale(scale: 0.9).combined(with: .opacity),
      removal: .opacity
    ))
  }
}

// MARK: - Configuration Area

extension AnalysisView {
  private var configurationArea: some View {
    VStack(spacing: 0) {
      ScrollView {
        VStack(spacing: UIConstants.Spacing.section) {
          if !store.hasTokensLoaded {
            WarningCard(
              icon: "exclamationmark.triangle.fill",
              title: "Aucun Design System chargé",
              message: "Chargez d'abord un fichier de tokens dans l'onglet Dashboard pour pouvoir analyser son utilisation.",
              color: .orange
            )
          }
          
          directoriesSection
          filtersSection
          optionsSection
        }
        .padding()
        .frame(maxWidth: UIConstants.Size.maxContentWidth)
      }
      
      if store.canStartAnalysis || store.isAnalyzing {
        bottomActionArea
      }
    }
  }
  
  private var directoriesSection: some View {
    SectionCard(
      title: "Dossiers à analyser",
      trailing: {
        Button {
          send(.addDirectoryTapped)
        } label: {
          Label("Ajouter un dossier", systemImage: "folder.badge.plus")
        }
        .controlSize(.small)
      }
    ) {
      if store.directoriesToScan.isEmpty {
        EmptyStateCard(
          icon: "folder",
          title: "Aucun dossier sélectionné",
          message: "Ajoutez les dossiers de vos projets Swift qui utilisent le design system"
        )
      } else {
        VStack(spacing: UIConstants.Spacing.medium) {
          ForEach(store.directoriesToScan) { directory in
            DirectoryRow(
              name: directory.name,
              path: directory.url.path,
              onRemove: { send(.removeDirectory(directory.id)) }
            )
          }
        }
      }
    }
  }
  
  private var filtersSection: some View {
    SectionCard(
      title: "Filtres d'export appliqués",
      subtitle: "Seuls les tokens qui seraient exportés sont analysés",
      trailing: {
        Text("Configurer dans l'onglet Importer")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    ) {
      HStack(spacing: UIConstants.Spacing.medium) {
        FilterBadge(
          label: "Exclure Utility",
          isActive: store.tokenFilters.excludeUtilityGroup,
          color: .orange
        )
        
        FilterBadge(
          label: "Exclure #tokens",
          isActive: store.tokenFilters.excludeTokensStartingWithHash,
          color: .purple
        )
        
        FilterBadge(
          label: "Exclure hover",
          isActive: store.tokenFilters.excludeTokensEndingWithHover,
          color: .blue
        )
      }
    }
  }
  
  private var optionsSection: some View {
    SectionCard(title: "Options de scan") {
      Toggle("Ignorer les fichiers de test", isOn: $store.config.ignoreTestFiles)
      Toggle("Ignorer les fichiers de preview", isOn: $store.config.ignorePreviewFiles)
      
      Divider()
      
      Toggle(isOn: $store.config.ignoreTokenDeclarationFiles) {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.extraSmall) {
          Text("Ignorer les fichiers de déclaration")
          Text("Aperture+Colors.swift, Colors.swift, etc.")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
  }
  
  private var bottomActionArea: some View {
    VStack(spacing: 0) {
      Divider()
      
      if store.isAnalyzing, let progress = store.scanProgress {
        ScanProgressView(
          progress: progress,
          onCancel: { send(.cancelAnalysisTapped) }
        )
        .padding()
      } else {
        Button {
          send(.startAnalysisTapped)
        } label: {
          Text("Lancer l'analyse")
        }
        .buttonStyle(.adaptiveGlassProminent)
        .controlSize(.large)
        .padding()
      }
    }
    .background(.bar)
  }
}

// MARK: - Analysis Content

extension AnalysisView {
  private var analysisContent: some View {
    VStack(spacing: 0) {
      tabs
      
      if store.selectedTab != .overview {
        searchField
      }
      
      Divider()
      
      if let report = store.report {
        tabContent(for: store.selectedTab, report: report)
          .padding()
          .id(store.selectedTab)
          .transition(.opacity.combined(with: .scale(scale: 0.95)))
      }
    }
    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: store.selectedTab)
    .searchFocusShortcut($isSearchFocused)
  }
  
  private var searchField: some View {
    HStack {
      SearchField(
        text: $store.searchText,
        placeholder: searchPlaceholder,
        resultCount: searchResultCount,
        totalCount: searchTotalCount,
        isFocused: $isSearchFocused
      )
    }
    .padding(.horizontal)
    .padding(.vertical, UIConstants.Spacing.medium)
  }
  
  private var searchPlaceholder: String {
    switch store.selectedTab {
    case .overview: "Rechercher..."
    case .used: "Rechercher un token ou fichier..."
    case .orphaned: "Rechercher un token ou catégorie..."
    }
  }
  
  private var searchResultCount: Int? {
    guard !store.searchText.isEmpty else { return nil }
    switch store.selectedTab {
    case .overview: return nil
    case .used: return store.filteredUsedTokens.count
    case .orphaned: return store.filteredOrphanedTokens.count
    }
  }
  
  private var searchTotalCount: Int? {
    guard !store.searchText.isEmpty else { return nil }
    switch store.selectedTab {
    case .overview: return nil
    case .used: return store.report?.usedTokens.count
    case .orphaned: return store.report?.orphanedTokens.count
    }
  }
}

// MARK: - Tabs

extension AnalysisView {
  private var tabs: some View {
    HStack {
      ForEach(AnalysisFeature.AnalysisTab.allCases, id: \.self) { tab in
        Button {
          send(.tabTapped(tab))
        } label: {
          VStack(spacing: UIConstants.Spacing.small) {
            Text(tab.rawValue)
              .font(.headline)
              .foregroundStyle(store.selectedTab == tab ? .primary : .secondary)

            if let report = store.report {
              Text(countForTab(tab, report: report))
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
          .padding(.horizontal, UIConstants.Spacing.extraLarge)
          .padding(.vertical, UIConstants.Spacing.medium)
          .contentShape(.rect)
          .background {
            if store.selectedTab == tab {
              RoundedRectangle(cornerRadius: UIConstants.CornerRadius.large)
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

  private func countForTab(_ tab: AnalysisFeature.AnalysisTab, report: TokenUsageReport) -> String {
    switch tab {
    case .overview: "Résumé"
    case .used: "\(report.usedTokens.count)"
    case .orphaned: "\(report.orphanedTokens.count)"
    }
  }

  @ViewBuilder
  private func tabContent(for tab: AnalysisFeature.AnalysisTab, report: TokenUsageReport) -> some View {
    switch tab {
    case .overview:
      UsageOverviewView(report: report, onTabTapped: { send(.tabTapped($0)) })

    case .used:
      UsedTokensListView(
        tokens: store.filteredUsedTokens,
        selectedToken: store.selectedUsedToken,
        searchText: store.searchText,
        onTokenTapped: { send(.usedTokenTapped($0)) }
      )

    case .orphaned:
      OrphanedTokensListView(
        tokens: store.filteredOrphanedTokens,
        expandedCategories: store.expandedOrphanCategories,
        searchText: store.searchText,
        onToggleCategory: { send(.toggleOrphanCategory($0)) }
      )
    }
  }
}

// MARK: - Previews

#if DEBUG
#Preview("Configuration") {
  AnalysisView(
    store: Store(initialState: .initial) {
      AnalysisFeature()
    }
  )
  .frame(width: UIConstants.Size.windowMinWidth, height: UIConstants.Size.windowMinHeight)
}
#endif
