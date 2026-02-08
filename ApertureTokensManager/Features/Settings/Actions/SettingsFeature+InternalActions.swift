import ComposableArchitecture
import Foundation

extension SettingsFeature {
  func handleInternalAction(_ action: Action.Internal, state: inout State) -> Effect<Action> {
    switch action {
    case .logEntriesLoaded(let entries):
      state.logEntries = entries
      state.logCount = entries.count
      state.isLoadingLogs = false
      return .none
      
    case .logsExported(let content):
      state.isExportingLogs = false
      let fileName = "ApertureTokensManager-logs-\(formattedDate()).txt"
      return .run { [fileClient] _ in
        if let url = try await fileClient.saveTextFile(
          content,
          fileName,
          "Exporter les logs",
          "Choisissez où enregistrer le fichier de logs"
        ) {
          await fileClient.openInFinder(url)
        }
      }
    }
  }
  
  private func formattedDate() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd-HHmmss"
    return formatter.string(from: Date())
  }
}
