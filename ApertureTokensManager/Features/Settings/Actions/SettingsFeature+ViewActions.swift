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
      
    case .refreshLogsButtonTapped:
      state.isLoadingLogs = true
      return .run { send in
        let entries = await loggingClient.getLogEntries()
        await send(.internal(.logEntriesLoaded(entries)))
      }
      
    case .sectionSelected(let section):
      state.selectedSection = section
      return .none
    }
  }
}
