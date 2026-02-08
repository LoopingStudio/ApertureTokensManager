import ComposableArchitecture
import Foundation

extension HomeFeature {
  func handleAnalyticsAction(_ action: Action.Analytics, state: inout State) -> EffectOf<Self> {
    switch action {
    case .baseCleared:
      loggingClient.logUserAction(
        LogFeature.home,
        "base_cleared",
        [:]
      )
      return .none
      
    case .compareWithBaseTapped:
      loggingClient.logUserAction(
        LogFeature.home,
        "compare_with_base_tapped",
        [:]
      )
      return .none
      
    case .exportCompleted(let tokenCount):
      loggingClient.logUserAction(
        LogFeature.home,
        "export_completed",
        ["token_count": "\(tokenCount)"]
      )
      return .none
      
    case .exportFailed(let error):
      loggingClient.logError(
        LogFeature.home,
        "export_failed",
        nil
      )
      loggingClient.logSystemEvent(
        LogFeature.home,
        "export_error",
        ["error": error]
      )
      return .none
      
    case .historyFilterChanged(let filter):
      loggingClient.logUserAction(
        LogFeature.home,
        "history_filter_changed",
        ["filter": filter]
      )
      return .none
      
    case .historyItemTapped(let type, let fileName):
      loggingClient.logUserAction(
        LogFeature.home,
        "history_item_tapped",
        ["type": type, "file_name": fileName]
      )
      return .none
      
    case .openFileTapped:
      loggingClient.logUserAction(
        LogFeature.home,
        "open_file_tapped",
        [:]
      )
      return .none
      
    case .tokenBrowserOpened:
      loggingClient.logUserAction(
        LogFeature.home,
        "token_browser_opened",
        [:]
      )
      return .none
    }
  }
}
