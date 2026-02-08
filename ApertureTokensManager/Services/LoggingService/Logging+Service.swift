import Foundation
import OSLog

// MARK: - Log Entry (for buffer)

/// Entrée de log stockée dans le buffer
public struct LogEntry: Equatable, Sendable, Identifiable {
  public let id = UUID()
  public let timestamp: Date
  public let level: Level
  public let feature: String
  public let message: String
  public let metadata: [String: String]
  
  public enum Level: String, Sendable {
    case debug = "DEBUG"
    case info = "INFO"
    case success = "SUCCESS"
    case warning = "WARNING"
    case error = "ERROR"
    
    var emoji: String {
      switch self {
      case .debug: return "🔍"
      case .info: return "ℹ️"
      case .success: return "✅"
      case .warning: return "⚠️"
      case .error: return "❌"
      }
    }
  }
  
  public var formattedLine: String {
    let dateFormatter = ISO8601DateFormatter()
    dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let dateString = dateFormatter.string(from: timestamp)
    let metadataString = metadata.isEmpty ? "" : " | \(metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", "))"
    return "[\(dateString)] \(level.emoji) [\(level.rawValue)] [\(feature)] \(message)\(metadataString)"
  }
}

// MARK: - Logging Service

/// Service centralisé pour le logging avec OSLog
actor LoggingService {
  
  // MARK: - Buffer
  
  private var logBuffer: [LogEntry] = []
  private let maxBufferSize = 1000
  
  /// Ajoute une entrée au buffer
  private func addToBuffer(_ entry: LogEntry) {
    logBuffer.append(entry)
    if logBuffer.count > maxBufferSize {
      logBuffer.removeFirst(logBuffer.count - maxBufferSize)
    }
  }
  
  /// Récupère toutes les entrées du buffer
  func getLogEntries() -> [LogEntry] {
    return logBuffer
  }
  
  /// Récupère le nombre d'entrées dans le buffer
  func getLogCount() -> Int {
    return logBuffer.count
  }
  
  /// Vide le buffer
  func clearBuffer() {
    logBuffer.removeAll()
  }
  
  /// Exporte les logs en texte formaté
  func exportLogs() -> String {
    let header = """
    ================================================================================
    Aperture Tokens Manager - Log Export
    Date: \(ISO8601DateFormatter().string(from: Date()))
    Entries: \(logBuffer.count)
    ================================================================================
    
    """
    let logs = logBuffer.map { $0.formattedLine }.joined(separator: "\n")
    return header + logs
  }
  
  // MARK: - Public API
  
  /// Log un événement structuré
  func log(_ event: LogEvent) {
    let logger = loggerForCategory(event.category)
    let metadataString = formatMetadata(event.metadata)
    let labelString = event.label.map { " [\($0)]" } ?? ""
    let valueString = event.value.map { " value=\($0)" } ?? ""
    
    switch event.category {
    case .userAction:
      logger.info("🎯 \(event.action)\(labelString)\(valueString)\(metadataString)")
    case .systemEvent:
      logger.info("⚙️ \(event.action)\(labelString)\(valueString)\(metadataString)")
    case .error:
      logger.error("❌ \(event.action)\(labelString)\(metadataString)")
    case .performance:
      logger.info("⏱️ \(event.action)\(labelString)\(valueString)\(metadataString)")
    }
  }
  
  /// Log une action utilisateur
  func logUserAction(feature: String, action: String, metadata: [String: String] = [:]) {
    let logger = loggerForFeature(feature)
    let metadataString = formatMetadata(metadata)
    logger.info("🎯 [USER] \(action)\(metadataString)")
    addToBuffer(LogEntry(timestamp: Date(), level: .info, feature: feature, message: "[USER] \(action)", metadata: metadata))
  }
  
  /// Log un événement système
  func logSystemEvent(feature: String, event: String, metadata: [String: String] = [:]) {
    let logger = loggerForFeature(feature)
    let metadataString = formatMetadata(metadata)
    logger.info("⚙️ [SYSTEM] \(event)\(metadataString)")
    addToBuffer(LogEntry(timestamp: Date(), level: .info, feature: feature, message: "[SYSTEM] \(event)", metadata: metadata))
  }
  
  /// Log une erreur
  func logError(feature: String, message: String, error: Error? = nil) {
    let logger = loggerForFeature(feature)
    var meta: [String: String] = [:]
    if let error {
      logger.error("❌ [ERROR] \(message) | error=\(error.localizedDescription)")
      meta["error"] = error.localizedDescription
    } else {
      logger.error("❌ [ERROR] \(message)")
    }
    addToBuffer(LogEntry(timestamp: Date(), level: .error, feature: feature, message: message, metadata: meta))
  }
  
  /// Log une métrique de performance
  func logPerformance(feature: String, operation: String, duration: TimeInterval) {
    let logger = loggerForFeature(feature)
    let durationMs = String(format: "%.2f", duration * 1000)
    logger.info("⏱️ [PERF] \(operation) completed in \(durationMs)ms")
    addToBuffer(LogEntry(timestamp: Date(), level: .info, feature: feature, message: "[PERF] \(operation)", metadata: ["duration_ms": durationMs]))
  }
  
  /// Log un succès
  func logSuccess(feature: String, message: String, metadata: [String: String] = [:]) {
    let logger = loggerForFeature(feature)
    let metadataString = formatMetadata(metadata)
    logger.info("✅ [SUCCESS] \(message)\(metadataString)")
    addToBuffer(LogEntry(timestamp: Date(), level: .success, feature: feature, message: message, metadata: metadata))
  }
  
  /// Log un warning
  func logWarning(feature: String, message: String, metadata: [String: String] = [:]) {
    let logger = loggerForFeature(feature)
    let metadataString = formatMetadata(metadata)
    logger.warning("⚠️ [WARNING] \(message)\(metadataString)")
    addToBuffer(LogEntry(timestamp: Date(), level: .warning, feature: feature, message: message, metadata: metadata))
  }
  
  /// Log un message debug
  func logDebug(feature: String, message: String, metadata: [String: String] = [:]) {
    let logger = loggerForFeature(feature)
    let metadataString = formatMetadata(metadata)
    logger.debug("🔍 [DEBUG] \(message)\(metadataString)")
    addToBuffer(LogEntry(timestamp: Date(), level: .debug, feature: feature, message: message, metadata: metadata))
  }
  
  // MARK: - Private Helpers
  
  private func formatMetadata(_ metadata: [String: String]) -> String {
    guard !metadata.isEmpty else { return "" }
    return " | \(metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", "))"
  }
  
  private func loggerForCategory(_ category: LogEvent.Category) -> Logger {
    switch category {
    case .userAction:
      return AppLogger.navigation
    case .systemEvent:
      return AppLogger.app
    case .error:
      return AppLogger.app
    case .performance:
      return AppLogger.app
    }
  }
  
  private func loggerForFeature(_ feature: String) -> Logger {
    switch feature.lowercased() {
    case "import":
      return AppLogger.import
    case "compare":
      return AppLogger.compare
    case "analysis":
      return AppLogger.analysis
    case "export":
      return AppLogger.export
    case "file":
      return AppLogger.file
    case "history":
      return AppLogger.history
    case "suggestion":
      return AppLogger.suggestion
    case "usage":
      return AppLogger.usage
    case "navigation", "app":
      return AppLogger.navigation
    case "home":
      return AppLogger.app
    default:
      return AppLogger.app
    }
  }
}

// MARK: - Feature Constants

enum LogFeature {
  static let `import` = "Import"
  static let compare = "Compare"
  static let analysis = "Analysis"
  static let export = "Export"
  static let file = "File"
  static let history = "History"
  static let suggestion = "Suggestion"
  static let usage = "Usage"
  static let navigation = "Navigation"
  static let app = "App"
  static let home = "Home"
}
