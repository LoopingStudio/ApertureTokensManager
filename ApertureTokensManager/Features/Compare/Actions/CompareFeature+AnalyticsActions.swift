import ComposableArchitecture
import Foundation

extension CompareFeature {
  func handleAnalyticsAction(_ action: Action.Analytics, state: inout State) -> EffectOf<Self> {
    switch action {
    case .comparisonCompleted(let added, let removed, let modified):
      loggingClient.logUserAction(
        LogFeature.compare,
        "comparison_completed",
        [
          "added": "\(added)",
          "removed": "\(removed)",
          "modified": "\(modified)"
        ]
      )
      return .none
      
    case .exportToNotionCompleted:
      loggingClient.logUserAction(
        LogFeature.compare,
        "export_notion_completed",
        [:]
      )
      return .none
      
    case .exportToNotionFailed(let error):
      loggingClient.logError(
        LogFeature.compare,
        "export_notion_failed",
        nil
      )
      loggingClient.logSystemEvent(
        LogFeature.compare,
        "export_notion_error",
        ["error": error]
      )
      return .none
      
    case .fileLoaded(let slot, let fileName):
      loggingClient.logUserAction(
        LogFeature.compare,
        "file_loaded",
        ["slot": slot, "file_name": fileName]
      )
      return .none
      
    case .fileLoadFailed(let error):
      loggingClient.logError(
        LogFeature.compare,
        "file_load_failed",
        nil
      )
      loggingClient.logSystemEvent(
        LogFeature.compare,
        "file_load_error",
        ["error": error]
      )
      return .none
      
    case .historyCleared:
      loggingClient.logUserAction(
        LogFeature.compare,
        "history_cleared",
        [:]
      )
      return .none
      
    case .historyEntryTapped(let oldFile, let newFile):
      loggingClient.logUserAction(
        LogFeature.compare,
        "history_entry_tapped",
        ["old_file": oldFile, "new_file": newFile]
      )
      return .none
      
    case .screenViewed:
      loggingClient.logUserAction(
        LogFeature.compare,
        "screen_viewed",
        [:]
      )
      return .none
      
    case .suggestionAccepted(let removedPath, let suggestedPath):
      loggingClient.logUserAction(
        LogFeature.compare,
        "suggestion_accepted",
        ["removed_path": removedPath, "suggested_path": suggestedPath]
      )
      return .none
      
    case .suggestionRejected(let removedPath):
      loggingClient.logUserAction(
        LogFeature.compare,
        "suggestion_rejected",
        ["removed_path": removedPath]
      )
      return .none
      
    case .tabChanged(let tab):
      loggingClient.logUserAction(
        LogFeature.compare,
        "tab_changed",
        ["tab": tab]
      )
      return .none
    }
  }
}
