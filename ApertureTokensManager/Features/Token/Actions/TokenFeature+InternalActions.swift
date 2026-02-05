import Combine
import ComposableArchitecture
import Foundation

extension TokenFeature {
  func handleInternalAction(_ action: Action.Internal, state: inout State) -> EffectOf<Self> {
    switch action {
    case .fileLoadingStarted:
      state.isLoading = true
      state.loadingError = false
      state.errorMessage = nil
      return .none
    case .fileLoadingFailed(let message):
      state.isLoading = false
      state.loadingError = true
      state.errorMessage = message
      return .none
    case .loadFile(let url):
      return .run { send in
        do {
          let tokenExport = try await fileClient.loadTokenExport(url)
          await send(.internal(.exportLoaded(tokenExport, url)))
        } catch {
          print("Erreur chargement: \(error)")
          await send(.internal(.fileLoadingFailed("Erreur de chargement du fichier JSON")))
        }
      }
    case .exportLoaded(let tokenExport, let url):
      state.isLoading = false
      state.loadingError = false
      state.errorMessage = nil
      state.rootNodes = tokenExport.tokens
      state.isFileLoaded = true
      state.metadata = tokenExport.metadata
      state.currentFileURL = url
      
      // Appliquer les filtres initiaux avant de sélectionner
      applyFiltersToNodes(state: &state)
      
      // Sélectionner le premier node après filtrage
      state.allNodes = TokenHelpers.flattenAllNodes(state.rootNodes)
      state.selectedNode = state.rootNodes.first
      
      // Count leaf tokens (nodes with values)
      let tokenCount = TokenHelpers.countLeafTokens(tokenExport.tokens)
      
      // Save to history
      let entry = ImportHistoryEntry(
        fileName: url.lastPathComponent,
        bookmarkData: url.securityScopedBookmark(),
        metadata: tokenExport.metadata,
        tokenCount: tokenCount
      )
      
      return .merge(
        .send(.internal(.observeFilters)),
        .run { send in
          await historyClient.addImportEntry(entry)
          let history = await historyClient.getImportHistory()
          await send(.internal(.historyLoaded(history)))
        }
      )
    case .historyLoaded(let history):
      state.importHistory = history
      return .none
    case .applyFilters:
      applyFiltersToNodes(state: &state)
      return .none
    case .filtersChanged(let filters):
      applyFiltersToNodes(state: &state, filters: filters)
      return .none
    case .observeFilters:
      return .publisher {
        state.$filters.publisher
          .dropFirst()
          .map { Action.internal(.filtersChanged($0)) }
      }
    }
  }
  
  // Fonction pour appliquer les filtres aux nœuds
  func applyFiltersToNodes(state: inout State) {
    applyFiltersToNodes(state: &state, filters: state.filters)
  }
  
  func applyFiltersToNodes(state: inout State, filters: TokenFilters) {
    applyFiltersRecursively(
      nodes: &state.rootNodes,
      filters: filters
    )
    // Reconstruire la liste plate après filtrage
    state.allNodes = TokenHelpers.flattenAllNodes(state.rootNodes)
  }
  
  private func applyFiltersRecursively(
    nodes: inout [TokenNode],
    filters: TokenFilters,
    forceDisabled: Bool = false
  ) {
    for i in 0..<nodes.count {
      var shouldDisableChildren = forceDisabled
      
      // Filtrer le groupe Utility
      if nodes[i].type == .group && nodes[i].name.lowercased() == GroupNames.utility {
        if filters.excludeUtilityGroup {
          nodes[i].isEnabled = false
          shouldDisableChildren = true
        } else if !forceDisabled {
          nodes[i].isEnabled = true
        }
      }
      
      // Si forcé par un parent désactivé
      if forceDisabled {
        nodes[i].isEnabled = false
      }
      
      // Appliquer les filtres au nœud courant s'il s'agit d'un token (et pas forcé désactivé)
      if nodes[i].type == .token && !shouldDisableChildren {
        var newIsEnabled = true
        
        if filters.excludeTokensStartingWithHash && nodes[i].name.hasPrefix("#") {
          newIsEnabled = false
        }
        if filters.excludeTokensEndingWithHover && nodes[i].name.hasSuffix("_hover") {
          newIsEnabled = false
        }
        
        nodes[i].isEnabled = newIsEnabled
      }
      
      // Appliquer les filtres aux enfants
      if nodes[i].children != nil {
        applyFiltersRecursively(
          nodes: &nodes[i].children!,
          filters: filters,
          forceDisabled: shouldDisableChildren
        )
      }
    }
  }
}
