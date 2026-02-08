import Foundation
import OSLog

// MARK: - Logging Service

/// Service centralisé pour le logging avec OSLog
actor LoggingService {
  
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
  }
  
  /// Log un événement système
  func logSystemEvent(feature: String, event: String, metadata: [String: String] = [:]) {
    let logger = loggerForFeature(feature)
    let metadataString = formatMetadata(metadata)
    logger.info("⚙️ [SYSTEM] \(event)\(metadataString)")
  }
  
  /// Log une erreur
  func logError(feature: String, message: String, error: Error? = nil) {
    let logger = loggerForFeature(feature)
    if let error {
      logger.error("❌ [ERROR] \(message) | error=\(error.localizedDescription)")
    } else {
      logger.error("❌ [ERROR] \(message)")
    }
  }
  
  /// Log une métrique de performance
  func logPerformance(feature: String, operation: String, duration: TimeInterval) {
    let logger = loggerForFeature(feature)
    let durationMs = String(format: "%.2f", duration * 1000)
    logger.info("⏱️ [PERF] \(operation) completed in \(durationMs)ms")
  }
  
  /// Log un succès
  func logSuccess(feature: String, message: String, metadata: [String: String] = [:]) {
    let logger = loggerForFeature(feature)
    let metadataString = formatMetadata(metadata)
    logger.info("✅ [SUCCESS] \(message)\(metadataString)")
  }
  
  /// Log un warning
  func logWarning(feature: String, message: String, metadata: [String: String] = [:]) {
    let logger = loggerForFeature(feature)
    let metadataString = formatMetadata(metadata)
    logger.warning("⚠️ [WARNING] \(message)\(metadataString)")
  }
  
  /// Log un message debug
  func logDebug(feature: String, message: String, metadata: [String: String] = [:]) {
    let logger = loggerForFeature(feature)
    let metadataString = formatMetadata(metadata)
    logger.debug("🔍 [DEBUG] \(message)\(metadataString)")
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
