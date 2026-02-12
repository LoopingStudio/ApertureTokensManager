import ComposableArchitecture
import Foundation
import Sharing

extension HomeFeature {
  func handleViewAction(_ action: Action.View, state: inout State) -> EffectOf<Self> {
    switch action {
    case .clearBaseButtonTapped:
      state.$designSystemBase.withLock { $0 = nil }
      return .send(.analytics(.baseCleared))
    case .compareWithBaseButtonTapped:
      guard let base = state.designSystemBase else { return .none }
      return .merge(
        .send(.analytics(.compareWithBaseTapped)),
        .send(.delegate(.compareWithBase(tokens: base.tokens, metadata: base.metadata)))
      )
    case .confirmExportButtonTapped:
      guard let base = state.designSystemBase else { return .none }
      state.isExportPopoverPresented = false
      // Appliquer les filtres avant l'export
      let filteredTokens = TokenHelpers.applyFilters(state.filters, to: base.tokens)
      let tokenCount = TokenHelpers.countLeafTokens(filteredTokens)
      return .run { send in
        try await exportClient.exportDesignSystem(filteredTokens)
        await send(.analytics(.exportCompleted(tokenCount: tokenCount)))
      } catch: { error, send in
        await send(.analytics(.exportFailed(error: error.localizedDescription)))
      }
    case .dismissExportPopover:
      state.isExportPopoverPresented = false
      return .none
    case .exportButtonTapped:
      state.isExportPopoverPresented = true
      return .none
    case .goToImportTapped:
      return .send(.delegate(.goToImport))
    case .historyFilterChanged(let filter):
      state.historyFilter = filter
      return .send(.analytics(.historyFilterChanged(filter: filter.rawValue)))
    case .historyItemTapped(let item):
      switch item {
      case .imported(let entry):
        return .merge(
          .send(.analytics(.historyItemTapped(type: "import", fileName: entry.fileName))),
          .send(.delegate(.openImportHistory(entry)))
        )
      case .comparison(let entry):
        return .merge(
          .send(.analytics(.historyItemTapped(type: "comparison", fileName: entry.oldFile.fileName))),
          .send(.delegate(.openComparisonHistory(entry)))
        )
      }
    case .openFileButtonTapped:
      guard let base = state.designSystemBase, let url = base.resolveURL() else { return .none }
      return .merge(
        .send(.analytics(.openFileTapped)),
        .run { _ in
          await fileClient.openInFinder(url)
        }
      )
    case .tokenCountTapped:
      guard let base = state.designSystemBase else { return .none }
      state.tokenBrowser = .initial(tokens: base.tokens, metadata: base.metadata)
      return .send(.analytics(.tokenBrowserOpened))
    }
  }
}
