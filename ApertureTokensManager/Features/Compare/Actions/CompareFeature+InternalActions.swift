import ComposableArchitecture
import Foundation

extension CompareFeature {
  func handleInternalAction(_ action: Action.Internal, state: inout State) -> EffectOf<Self> {
    switch action {
    case .loadFile(let fileType, let url):
      return .run { send in
        do {
          let tokenExport = try await fileClient.loadTokenExport(url)
          await send(.internal(.exportLoaded(fileType, tokenExport, url)))
        } catch {
          await send(.internal(.loadingFailed("Erreur chargement fichier: \(error.localizedDescription)")))
        }
      }
      
    case .exportLoaded(let fileType, let tokenExport, let url):
      var fileState = fileType == .old ? state.oldFile : state.newFile
      fileState.isLoading = false
      fileState.tokens = tokenExport.tokens
      fileState.isLoaded = true
      fileState.metadata = tokenExport.metadata
      fileState.url = url
      
      if fileType == .old {
        state.oldFile = fileState
      } else {
        state.newFile = fileState
      }
      state.loadingError = nil
      return .none
      
    case .loadingFailed(let errorMessage):
      state.oldFile.isLoading = false
      state.newFile.isLoading = false
      state.loadingError = errorMessage
      return .none
      
    case .performComparison:
      guard let oldTokens = state.oldFile.tokens, let newTokens = state.newFile.tokens else { return .none }
      return .run { send in
        let comparison = await comparisonClient.compareTokens(oldTokens, newTokens)
        await send(.internal(.comparisonCompleted(comparison)))
      }
      
    case .comparisonCompleted(let changes):
      state.changes = changes
      
      // Capture les données nécessaires pour les effets
      let removed = changes.removed
      let added = changes.added
      let oldURL = state.oldFile.url
      let newURL = state.newFile.url
      let oldMetadata = state.oldFile.metadata
      let newMetadata = state.newFile.metadata
      
      return .merge(
        // Calculer les suggestions intelligentes
        .run { send in
          let suggestions = await suggestionClient.computeSuggestions(removed, added)
          await send(.internal(.suggestionsComputed(suggestions)))
        },
        // Sauvegarder dans l'historique
        .run { send in
          guard let oldURL, let newURL else { return }
          let entry = ComparisonHistoryEntry(
            oldFile: FileSnapshot(
              fileName: oldURL.lastPathComponent,
              bookmarkData: oldURL.securityScopedBookmark(),
              metadata: oldMetadata
            ),
            newFile: FileSnapshot(
              fileName: newURL.lastPathComponent,
              bookmarkData: newURL.securityScopedBookmark(),
              metadata: newMetadata
            ),
            summary: ComparisonSummary(from: changes)
          )
          await historyClient.addComparisonEntry(entry)
          let history = await historyClient.getComparisonHistory()
          await send(.internal(.historyLoaded(history)))
        }
      )
      
    case .historyLoaded(let history):
      state.comparisonHistory = history
      return .none
      
    case .setBaseAsOldFile(let tokens, let metadata):
      state.oldFile.tokens = tokens
      state.oldFile.metadata = metadata
      state.oldFile.isLoaded = true
      state.oldFile.isFromBase = true
      state.oldFile.url = nil
      return .none
      
    case .suggestionsComputed(let suggestions):
      state.changes?.autoSuggestions = suggestions
      return .none
    }
  }
}
