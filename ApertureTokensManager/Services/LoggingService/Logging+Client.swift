import Dependencies
import Foundation
import OSLog

// MARK: - Logging Client

struct LoggingClient {
  var log: @Sendable (LogEvent) -> Void
  var logUserAction: @Sendable (String, String, [String: String]) -> Void
  var logSystemEvent: @Sendable (String, String, [String: String]) -> Void
  var logError: @Sendable (String, String, Error?) -> Void
  var logPerformance: @Sendable (String, String, TimeInterval) -> Void
  var logSuccess: @Sendable (String, String, [String: String]) -> Void
  var logWarning: @Sendable (String, String, [String: String]) -> Void
  var logDebug: @Sendable (String, String, [String: String]) -> Void
}

// MARK: - Dependency Key

extension LoggingClient: DependencyKey {
  static let liveValue: Self = {
    let service = LoggingService()
    return .init(
      log: { event in
        Task { await service.log(event) }
      },
      logUserAction: { feature, action, metadata in
        Task { await service.logUserAction(feature: feature, action: action, metadata: metadata) }
      },
      logSystemEvent: { feature, event, metadata in
        Task { await service.logSystemEvent(feature: feature, event: event, metadata: metadata) }
      },
      logError: { feature, message, error in
        Task { await service.logError(feature: feature, message: message, error: error) }
      },
      logPerformance: { feature, operation, duration in
        Task { await service.logPerformance(feature: feature, operation: operation, duration: duration) }
      },
      logSuccess: { feature, message, metadata in
        Task { await service.logSuccess(feature: feature, message: message, metadata: metadata) }
      },
      logWarning: { feature, message, metadata in
        Task { await service.logWarning(feature: feature, message: message, metadata: metadata) }
      },
      logDebug: { feature, message, metadata in
        Task { await service.logDebug(feature: feature, message: message, metadata: metadata) }
      }
    )
  }()
  
  static let testValue: Self = .init(
    log: { _ in },
    logUserAction: { _, _, _ in },
    logSystemEvent: { _, _, _ in },
    logError: { _, _, _ in },
    logPerformance: { _, _, _ in },
    logSuccess: { _, _, _ in },
    logWarning: { _, _, _ in },
    logDebug: { _, _, _ in }
  )
  
  static let previewValue: Self = testValue
}

// MARK: - Dependency Values

extension DependencyValues {
  var loggingClient: LoggingClient {
    get { self[LoggingClient.self] }
    set { self[LoggingClient.self] = newValue }
  }
}
