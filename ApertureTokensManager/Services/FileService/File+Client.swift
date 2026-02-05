import Dependencies
import Foundation
import UniformTypeIdentifiers

struct FileClient {
  var pickFile: @Sendable () async throws -> URL?
  var handleFileDrop: (NSItemProvider) async -> URL?
  var loadJSON: @Sendable (URL) async throws -> [TokenNode]
  var loadTokenExport: @Sendable (URL) async throws -> TokenExport
  var saveToFile: @Sendable (Data, String, UTType, String) async throws -> URL?
  var pickDirectory: @Sendable (String) async throws -> URL?
}

extension FileClient: DependencyKey {
  static let liveValue: Self = {
    let service = FileService()
    return .init(
      pickFile: { try await service.pickFile() },
      handleFileDrop: { await service.handleFileDrop(provider: $0) },
      loadJSON: { try await service.loadJSON(from: $0) },
      loadTokenExport: { try await service.loadTokenExport(from: $0) },
      saveToFile: { try await service.saveToFile(data: $0, defaultName: $1, contentType: $2, title: $3) },
      pickDirectory: { try await service.pickDirectory(message: $0) }
    )
  }()
  
  static let testValue: Self = .init(
    pickFile: { nil },
    handleFileDrop: { _ in nil },
    loadJSON: { _ in [] },
    loadTokenExport: { _ in TokenExport(metadata: TokenMetadata(exportedAt: "", timestamp: 0, version: "", generator: ""), tokens: []) },
    saveToFile: { _, _, _, _ in nil },
    pickDirectory: { _ in nil }
  )
  
  static let previewValue: Self = testValue
}

extension DependencyValues {
  var fileClient: FileClient {
    get { self[FileClient.self] }
    set { self[FileClient.self] = newValue }
  }
}
