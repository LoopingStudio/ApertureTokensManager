import Dependencies
import Foundation
import UniformTypeIdentifiers

struct FileClient {
  var handleFileDrop: (NSItemProvider) async -> URL?
  var loadJSON: @Sendable (URL) async throws -> [TokenNode]
  var loadTokenExport: @Sendable (URL) async throws -> TokenExport
  var openInFinder: @Sendable (URL) async -> Void
  var pickDirectory: @Sendable (String) async throws -> URL?
  var pickFile: @Sendable () async throws -> URL?
  var saveToFile: @Sendable (Data, String, UTType, String) async throws -> URL?
  var saveTextFile: @Sendable (String, String, String, String?) async throws -> URL?
}

extension FileClient: DependencyKey {
  static let liveValue: Self = {
    let service = FileService()
    return .init(
      handleFileDrop: { await service.handleFileDrop(provider: $0) },
      loadJSON: { try await service.loadJSON(from: $0) },
      loadTokenExport: { try await service.loadTokenExport(from: $0) },
      openInFinder: { await service.openInFinder(url: $0) },
      pickDirectory: { try await service.pickDirectory(message: $0) },
      pickFile: { try await service.pickFile() },
      saveToFile: { try await service.saveToFile(data: $0, defaultName: $1, contentType: $2, title: $3) },
      saveTextFile: { try await service.saveTextFile(content: $0, defaultName: $1, title: $2, message: $3) }
    )
  }()
  
  static let testValue: Self = .init(
    handleFileDrop: { _ in nil },
    loadJSON: { _ in [] },
    loadTokenExport: { _ in TokenExport(metadata: TokenMetadata(exportedAt: "", timestamp: 0, version: "", generator: ""), tokens: []) },
    openInFinder: { _ in },
    pickDirectory: { _ in nil },
    pickFile: { nil },
    saveToFile: { _, _, _, _ in nil },
    saveTextFile: { _, _, _, _ in nil }
  )
  
  static let previewValue: Self = testValue
}

extension DependencyValues {
  var fileClient: FileClient {
    get { self[FileClient.self] }
    set { self[FileClient.self] = newValue }
  }
}
