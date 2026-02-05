import AppKit
import ComposableArchitecture
import Foundation

struct ExportClient {
  var exportDesignSystem: @Sendable ([TokenNode]) async throws -> Void
}

extension DependencyValues {
  var exportClient: ExportClient {
    get { self[ExportClient.self] }
    set { self[ExportClient.self] = newValue }
  }
}

extension ExportClient: DependencyKey {
  static let liveValue: Self = {
    let service = ExportService()
    return .init(
      exportDesignSystem: { try await service.exportDesignSystem(nodes: $0) }
    )
  }()
  
  static let testValue: Self = .init(
    exportDesignSystem: { _ in }
  )
  
  static let previewValue: Self = testValue
}
