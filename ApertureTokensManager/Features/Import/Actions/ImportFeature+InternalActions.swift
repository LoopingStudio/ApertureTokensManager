import Combine
import ComposableArchitecture
import Foundation

extension ImportFeature {
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
      return .send(.analytics(.fileLoadFailed(error: message)))
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
      state.originalRootNodes = tokenExport.tokens  // Stocker les originaux sans filtres
      state.rootNodes = tokenExport.tokens
      state.isFileLoaded = true
      state.metadata = tokenExport.metadata
      state.currentFileURL = url
      
      // Appliquer les filtres sur rootNodes (originalRootNodes reste intact)
      applyFiltersToNodes(state: &state, filters: state.filters)

      // Sélectionner le premier node après filtrage
      state.selectedNode = state.rootNodes.first
      
      // Count leaf tokens (nodes with values)
      let tokenCount = TokenHelpers.countLeafTokens(tokenExport.tokens)
      let fileName = url.lastPathComponent
      
      // Save to history
      let entry = ImportHistoryEntry(
        fileName: fileName,
        bookmarkData: url.securityScopedBookmark(),
        metadata: tokenExport.metadata,
        tokenCount: tokenCount
      )
      
      return .merge(
        .send(.analytics(.fileLoaded(fileName: fileName, tokenCount: tokenCount))),
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
    case .loadFromHistoryEntry(let entry):
      // Réutilise la même logique que historyEntryTapped
      guard let url = entry.resolveURL() else {
        return .run { send in
          await historyClient.removeImportEntry(entry.id)
          let history = await historyClient.getImportHistory()
          await send(.internal(.historyLoaded(history)))
        }
      }
      _ = url.startAccessingSecurityScopedResource()
      return .concatenate(
        .send(.internal(.fileLoadingStarted)),
        .send(.internal(.loadFile(url)))
      )
    case .applyFilters:
      applyFiltersToNodes(state: &state, filters: state.filters)
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
  
  func applyFiltersToNodes(state: inout State, filters: TokenFilters) {
    // Toujours partir des tokens originaux pour appliquer les filtres
    // Cela permet de réactiver les tokens quand on désactive un filtre
    state.rootNodes = TokenHelpers.applyFilters(filters, to: state.originalRootNodes)
  }
}
