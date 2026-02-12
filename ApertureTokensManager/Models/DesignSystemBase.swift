import Foundation

/// Represents the current Design System used as reference
/// Stored persistently and used for quick comparisons and dashboard display
public struct DesignSystemBase: Codable, Equatable, Sendable {
  public let id: UUID
  public let setAt: Date
  public let fileName: String
  public let bookmarkData: Data?
  public let metadata: TokenMetadata
  public let tokens: [TokenNode]
  
  public init(
    id: UUID = UUID(),
    setAt: Date = Date(),
    fileName: String,
    bookmarkData: Data?,
    metadata: TokenMetadata,
    tokens: [TokenNode]
  ) {
    self.id = id
    self.setAt = setAt
    self.fileName = fileName
    self.bookmarkData = bookmarkData
    self.metadata = metadata
    self.tokens = tokens
  }
  
  /// Number of leaf tokens (excluding groups)
  public var tokenCount: Int {
    TokenHelpers.countLeafTokens(tokens)
  }
  
  /// Resolves the bookmark to get the file URL
  public func resolveURL() -> URL? {
    guard let bookmarkData else { return nil }
    var _isStale = false
    return try? URL(
      resolvingBookmarkData: bookmarkData,
      options: .withSecurityScope,
      relativeTo: nil,
      bookmarkDataIsStale: &_isStale
    )
  }
}
