import ComposableArchitecture
import Foundation

extension SettingsFeature {
  func handleViewAction(_ action: Action.View, state: inout State) -> Effect<Action> {
    switch action {
    case .clearLogsButtonTapped:
      return .run { send in
        await loggingClient.clearBuffer()
        let entries = await loggingClient.getLogEntries()
        await send(.internal(.logEntriesLoaded(entries)))
      }
      
    case .confirmResetAllData:
      state.showResetConfirmation = false
      // Reset all shared data
      state.$tokenFilters.withLock { $0 = TokenFilters() }
      state.$appSettings.withLock { $0 = AppSettings() }
      state.$importHistory.withLock { $0 = [] }
      state.$comparisonHistory.withLock { $0 = [] }
      state.$designSystemBase.withLock { $0 = nil }
      state.$analysisDirectories.withLock { $0 = [] }
      loggingClient.logSystemEvent(LogFeature.app, "all_data_reset", [:])
      return .run { send in
        await loggingClient.clearBuffer()
        let entries = await loggingClient.getLogEntries()
        await send(.internal(.logEntriesLoaded(entries)))
      }
      
    case .dismissResetConfirmation:
      state.showResetConfirmation = false
      return .none
      
    case .exportLogsButtonTapped:
      state.isExportingLogs = true
      return .run { send in
        let logsContent = await loggingClient.exportLogs()
        await send(.internal(.logsExported(logsContent)))
      }
      
    case .onAppear:
      state.isLoadingLogs = true
      return .run { send in
        let entries = await loggingClient.getLogEntries()
        await send(.internal(.logEntriesLoaded(entries)))
      }
      
    case .openDataFolderButtonTapped:
      return .run { [fileClient] _ in
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
          return
        }
        await fileClient.openInFinder(documentsURL)
      }
      
    case .openTutorialButtonTapped:
      return .send(.delegate(.openTutorial))
      
    case .refreshLogsButtonTapped:
      state.isLoadingLogs = true
      return .run { send in
        let entries = await loggingClient.getLogEntries()
        await send(.internal(.logEntriesLoaded(entries)))
      }
      
    case .resetAllDataButtonTapped:
      state.showResetConfirmation = true
      return .none
      
    case .sectionSelected(let section):
      state.selectedSection = section
      return .none
    }
  }
}
