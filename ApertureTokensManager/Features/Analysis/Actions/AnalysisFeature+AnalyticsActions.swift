import ComposableArchitecture
import Foundation

extension AnalysisFeature {
  func handleAnalyticsAction(_ action: Action.Analytics, state: inout State) -> EffectOf<Self> {
    switch action {
    case .analysisCompleted(let usedCount, let orphanedCount, let filesScanned):
      loggingClient.logUserAction(
        LogFeature.analysis,
        "analysis_completed",
        [
          "used_count": "\(usedCount)",
          "orphaned_count": "\(orphanedCount)",
          "files_scanned": "\(filesScanned)"
        ]
      )
      return .none
      
    case .analysisFailed(let error):
      loggingClient.logError(
        LogFeature.analysis,
        "analysis_failed",
        nil
      )
      loggingClient.logSystemEvent(
        LogFeature.analysis,
        "analysis_error",
        ["error": error]
      )
      return .none
      
    case .analysisStarted(let directoryCount, let tokenCount):
      loggingClient.logUserAction(
        LogFeature.analysis,
        "analysis_started",
        [
          "directory_count": "\(directoryCount)",
          "token_count": "\(tokenCount)"
        ]
      )
      return .none
      
    case .directoryAdded(let name):
      loggingClient.logUserAction(
        LogFeature.analysis,
        "directory_added",
        ["name": name]
      )
      return .none
      
    case .directoryRemoved:
      loggingClient.logUserAction(
        LogFeature.analysis,
        "directory_removed",
        [:]
      )
      return .none
      
    case .resultsCleared:
      loggingClient.logUserAction(
        LogFeature.analysis,
        "results_cleared",
        [:]
      )
      return .none
      
    case .screenViewed:
      loggingClient.logUserAction(
        LogFeature.analysis,
        "screen_viewed",
        [:]
      )
      return .none
      
    case .tabChanged(let tab):
      loggingClient.logUserAction(
        LogFeature.analysis,
        "tab_changed",
        ["tab": tab]
      )
      return .none
    }
  }
}
