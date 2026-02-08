import ComposableArchitecture
import Foundation

extension ImportFeature {
  func handleAnalyticsAction(_ action: Action.Analytics, state: inout State) -> EffectOf<Self> {
    switch action {
    case .exportCompleted(let tokenCount):
      loggingClient.logUserAction(
        LogFeature.import,
        "export_completed",
        ["token_count": "\(tokenCount)"]
      )
      return .none
      
    case .exportFailed(let error):
      loggingClient.logError(
        LogFeature.import,
        "export_failed",
        nil
      )
      loggingClient.logSystemEvent(
        LogFeature.import,
        "export_error",
        ["error": error]
      )
      return .none
      
    case .fileLoaded(let fileName, let tokenCount):
      loggingClient.logUserAction(
        LogFeature.import,
        "file_loaded",
        ["file_name": fileName, "token_count": "\(tokenCount)"]
      )
      return .none
      
    case .fileLoadFailed(let error):
      loggingClient.logError(
        LogFeature.import,
        "file_load_failed",
        nil
      )
      loggingClient.logSystemEvent(
        LogFeature.import,
        "file_load_error",
        ["error": error]
      )
      return .none
      
    case .historyCleared:
      loggingClient.logUserAction(
        LogFeature.import,
        "history_cleared",
        [:]
      )
      return .none
      
    case .historyEntryRemoved:
      loggingClient.logUserAction(
        LogFeature.import,
        "history_entry_removed",
        [:]
      )
      return .none
      
    case .historyEntryTapped(let fileName):
      loggingClient.logUserAction(
        LogFeature.import,
        "history_entry_tapped",
        ["file_name": fileName]
      )
      return .none
      
    case .nodeToggled(let path, let enabled):
      loggingClient.logUserAction(
        LogFeature.import,
        "node_toggled",
        ["path": path, "enabled": "\(enabled)"]
      )
      return .none
      
    case .screenViewed:
      loggingClient.logUserAction(
        LogFeature.import,
        "screen_viewed",
        [:]
      )
      return .none
      
    case .setAsBaseTapped(let fileName):
      loggingClient.logUserAction(
        LogFeature.import,
        "set_as_base_tapped",
        ["file_name": fileName]
      )
      return .none
    }
  }
}
