import Foundation
import OSLog

// MARK: - App Logger

/// Centralized logging system using OSLog
/// Usage: AppLogger.import.info("File loaded: \(fileName)")
enum AppLogger {
  /// Bundle identifier for subsystem
  private static let subsystem = Bundle.main.bundleIdentifier ?? "com.picta.ApertureTokensManager"
  
  // MARK: - Category Loggers
  
  /// Import feature logging
  static let `import` = Logger(subsystem: subsystem, category: "Import")
  
  /// Compare feature logging
  static let compare = Logger(subsystem: subsystem, category: "Compare")
  
  /// Analysis feature logging
  static let analysis = Logger(subsystem: subsystem, category: "Analysis")
  
  /// Export operations logging
  static let export = Logger(subsystem: subsystem, category: "Export")
  
  /// File operations logging
  static let file = Logger(subsystem: subsystem, category: "File")
  
  /// History operations logging
  static let history = Logger(subsystem: subsystem, category: "History")
  
  /// Suggestion service logging
  static let suggestion = Logger(subsystem: subsystem, category: "Suggestion")
  
  /// Token usage analysis logging
  static let usage = Logger(subsystem: subsystem, category: "Usage")
  
  /// Navigation and UI logging
  static let navigation = Logger(subsystem: subsystem, category: "Navigation")
  
  /// General app logging
  static let app = Logger(subsystem: subsystem, category: "App")
}

// MARK: - Log Event Types

/// Structured log event for analytics tracking
public struct LogEvent: Equatable, Sendable {
  public let category: Category
  public let action: String
  public let label: String?
  public let value: Int?
  public let metadata: [String: String]
  public let timestamp: Date
  
  public enum Category: String, Sendable {
    case userAction = "user_action"
    case systemEvent = "system_event"
    case error = "error"
    case performance = "performance"
  }
  
  public init(
    category: Category,
    action: String,
    label: String? = nil,
    value: Int? = nil,
    metadata: [String: String] = [:],
    timestamp: Date = Date()
  ) {
    self.category = category
    self.action = action
    self.label = label
    self.value = value
    self.metadata = metadata
    self.timestamp = timestamp
  }
}

// MARK: - Convenience Extensions

extension Logger {
  /// Log a user action with structured data
  func userAction(_ action: String, metadata: [String: String] = [:]) {
    let metadataString = metadata.isEmpty ? "" : " | \(metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", "))"
    self.info("🎯 [USER] \(action)\(metadataString)")
  }
  
  /// Log a system event
  func systemEvent(_ event: String, metadata: [String: String] = [:]) {
    let metadataString = metadata.isEmpty ? "" : " | \(metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", "))"
    self.info("⚙️ [SYSTEM] \(event)\(metadataString)")
  }
  
  /// Log a success event
  func success(_ message: String, metadata: [String: String] = [:]) {
    let metadataString = metadata.isEmpty ? "" : " | \(metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ", "))"
    self.info("✅ [SUCCESS] \(message)\(metadataString)")
  }
  
  /// Log a failure event
  func failure(_ message: String, error: Error? = nil) {
    if let error {
      self.error("❌ [FAILURE] \(message) | error=\(error.localizedDescription)")
    } else {
      self.error("❌ [FAILURE] \(message)")
    }
  }
  
  /// Log performance metrics
  func performance(_ operation: String, duration: TimeInterval) {
    self.info("⏱️ [PERF] \(operation) completed in \(String(format: "%.2f", duration * 1000))ms")
  }
}
