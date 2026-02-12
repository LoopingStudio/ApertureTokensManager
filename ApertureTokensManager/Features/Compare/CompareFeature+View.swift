import SwiftUI
import ComposableArchitecture
import UniformTypeIdentifiers

@ViewAction(for: CompareFeature.self)
struct CompareView: View {
  @Bindable var store: StoreOf<CompareFeature>
  @Namespace private var tabNamespace
  @FocusState private var isSearchFocused: Bool

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
}

// MARK: - Header

extension CompareView {
  private var header: some View {
    VStack(spacing: UIConstants.Spacing.large) {
      HStack {
        Text("Comparaison de Tokens")
          .font(.title)
          .fontWeight(.bold)

        Spacer()

        if store.changes != nil {
          headerActions
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
  
  private var headerActions: some View {
    HStack(spacing: UIConstants.Spacing.medium) {
      Button("Nouvelle Comparaison") { send(.resetComparison) }
        .buttonStyle(.adaptiveGlass())
        .controlSize(.small)
      Button("Exporter pour Notion") { send(.exportToNotionTapped) }
        .buttonStyle(.adaptiveGlassProminent)
        .controlSize(.small)
    }
    .transition(.asymmetric(
      insertion: .scale(scale: 0.9).combined(with: .opacity),
      removal: .opacity
    ))
  }
}

// MARK: - File Selection Area

extension CompareView {
  private var fileSelectionArea: some View {
    VStack(spacing: UIConstants.Spacing.section) {
      fileDropZones
      comparisonHistorySection
    }
    .padding()
    .frame(maxHeight: .infinity)
    .onAppear { send(.onAppear) }
  }
  
  private var fileDropZones: some View {
    HStack(spacing: UIConstants.Spacing.section) {
      oldFileDropZone
      fileSwitchControls
      newFileDropZone
    }
    .overlay(alignment: .bottom) {
      if store.oldFile.isLoaded && store.newFile.isLoaded {
        Button("Comparer les fichiers") {
          send(.compareButtonTapped)
        }
        .buttonStyle(.adaptiveGlassProminent)
        .controlSize(.large)
        .offset(y: UIConstants.Size.buttonOffset)
        .transition(.push(from: .top).combined(with: .opacity))
      }
    }
  }
  
  private var oldFileDropZone: some View {
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
  }
  
  private var fileSwitchControls: some View {
    VStack(spacing: UIConstants.Spacing.medium) {
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
    .frame(width: UIConstants.Size.iconSmall)
  }
  
  private var newFileDropZone: some View {
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
  
  @ViewBuilder
  private var comparisonHistorySection: some View {
    if !store.comparisonHistory.isEmpty && !store.oldFile.isLoaded && !store.newFile.isLoaded {
      ComparisonHistoryView(
        history: store.comparisonHistory,
        onEntryTapped: { send(.historyEntryTapped($0)) },
        onRemove: { send(.removeHistoryEntry($0)) },
        onClear: { send(.clearHistory) }
      )
      .frame(maxWidth: UIConstants.Size.maxContentWidth)
      .padding(.top, UIConstants.Spacing.extraLarge)
    }
  }
}

// MARK: - Comparison Content

extension CompareView {
  private var comparisonContent: some View {
    VStack(spacing: 0) {
      tabs
      searchFieldIfNeeded
      Divider()
      if let changes = store.changes {
        tabContent(for: store.selectedTab, changes: changes)
          .padding()
          .id(store.selectedTab)
          .transition(.opacity.combined(with: .scale(scale: 0.95)))
      }
    }
    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: store.selectedTab)
    .searchFocusShortcut($isSearchFocused)
  }
  
  @ViewBuilder
  private var searchFieldIfNeeded: some View {
    if store.selectedTab != .overview {
      SearchField(
        text: $store.searchText,
        placeholder: "Rechercher un token...",
        resultCount: filteredCountForCurrentTab,
        totalCount: totalCountForCurrentTab,
        isFocused: $isSearchFocused
      )
      .padding(.horizontal)
      .padding(.bottom, UIConstants.Spacing.medium)
    }
  }
  
  private var filteredCountForCurrentTab: Int? {
    guard !store.searchText.isEmpty else { return nil }
    switch store.selectedTab {
    case .overview: return nil
    case .added: return store.filteredAdded.count
    case .removed: return store.filteredRemoved.count
    case .modified: return store.filteredModified.count
    }
  }
  
  private var totalCountForCurrentTab: Int? {
    guard !store.searchText.isEmpty else { return nil }
    switch store.selectedTab {
    case .overview: return nil
    case .added: return store.changes?.added.count
    case .removed: return store.changes?.removed.count
    case .modified: return store.changes?.modified.count
    }
  }
}

// MARK: - Tabs

extension CompareView {
  private var tabs: some View {
    HStack {
      ForEach(CompareFeature.ComparisonTab.allCases, id: \.self) { tab in
        tabButton(for: tab)
      }
      Spacer()
    }
    .padding(.horizontal)
  }
  
  private func tabButton(for tab: CompareFeature.ComparisonTab) -> some View {
    Button {
      send(.tabTapped(tab))
    } label: {
      VStack(spacing: UIConstants.Spacing.small) {
        Text(tab.rawValue)
          .font(.headline)
          .foregroundStyle(store.selectedTab == tab ? .primary : .secondary)

        if let changes = store.changes {
          Text(countForTab(tab, changes: changes))
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

  private func countForTab(_ tab: CompareFeature.ComparisonTab, changes: ComparisonChanges) -> String {
    switch tab {
    case .overview: "Résumé"
    case .added: "\(changes.added.count)"
    case .removed: "\(changes.removed.count)"
    case .modified: "\(changes.modified.count)"
    }
  }
}

// MARK: - Tab Content

extension CompareView {
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
      AddedTokensView(tokens: store.filteredAdded, searchText: store.searchText)

    case .removed:
      RemovedTokensView(
        tokens: store.filteredRemoved,
        changes: store.changes,
        newVersionTokens: store.newFile.tokens,
        searchText: store.searchText,
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
        modifications: store.filteredModified,
        newVersionTokens: store.newFile.tokens,
        searchText: store.searchText
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
  .frame(width: UIConstants.Size.windowMinWidth, height: UIConstants.Size.windowMinHeight)
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
  .frame(width: UIConstants.Size.windowMinWidth, height: UIConstants.Size.windowMinHeight)
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
  .frame(width: UIConstants.Size.windowMinWidth, height: UIConstants.Size.windowMinHeight)
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
  .frame(width: UIConstants.Size.windowMinWidth, height: UIConstants.Size.windowMinHeight)
}
#endif
