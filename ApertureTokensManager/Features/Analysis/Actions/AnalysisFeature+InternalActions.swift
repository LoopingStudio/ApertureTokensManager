import ComposableArchitecture
import Foundation

extension AnalysisFeature {
  func handleInternalAction(_ action: Action.Internal, state: inout State) -> EffectOf<Self> {
    switch action {
    case .analysisCompleted(let report):
      state.isAnalyzing = false
      state.report = report
      state.analysisError = nil
      return .send(.analytics(.analysisCompleted(
        usedCount: report.usedTokens.count,
        orphanedCount: report.orphanedTokens.count,
        filesScanned: report.statistics.filesScanned
      )))
      
    case .analysisFailed(let error):
      state.isAnalyzing = false
      state.analysisError = error
      return .send(.analytics(.analysisFailed(error: error)))
      
    case .directoryPicked(let url, let bookmarkData):
      let directory = ScanDirectory(
        name: url.lastPathComponent,
        url: url,
        bookmarkData: bookmarkData
      )
      
      // Éviter les doublons
      var wasAdded = false
      state.$directoriesToScan.withLock { directories in
        if !directories.contains(where: { $0.url == url }) {
          directories.append(directory)
          wasAdded = true
        }
      }
      
      if wasAdded {
        return .send(.analytics(.directoryAdded(name: url.lastPathComponent)))
      }
      return .none
    }
  }
}
