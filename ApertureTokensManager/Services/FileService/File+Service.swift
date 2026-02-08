import AppKit
import Foundation
import OSLog
import UniformTypeIdentifiers

actor FileService {
  private let logger = AppLogger.file
  // MARK: - File Picking
  @MainActor  
  func pickFile() async throws -> URL? {
    logger.debug("Opening file picker panel")
    let openPanel = NSOpenPanel()
    openPanel.allowedContentTypes = [.json]
    openPanel.allowsMultipleSelection = false
    openPanel.canChooseDirectories = false
    openPanel.canChooseFiles = true
    openPanel.message = "Sélectionnez votre fichier de tokens JSON"

    guard openPanel.runModal() == .OK, let selectedURL = openPanel.url else {
      logger.debug("File picker cancelled")
      return nil 
    }
    logger.info("File selected: \(selectedURL.lastPathComponent)")
    return selectedURL
  }
  
  // MARK: - File Dropping
  @MainActor
  func handleFileDrop(provider: NSItemProvider) async -> URL? {
    return await withCheckedContinuation { continuation in
      provider.loadDataRepresentation(forTypeIdentifier: UTType.json.identifier) { data, _ in
        if let data = data {
          let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("dropped_tokens.json")
          try? data.write(to: tmpURL)
          continuation.resume(returning: tmpURL)
        } else {
          continuation.resume(returning: nil)
        }
      }
    }
  }
  
  // MARK: - File Reading
  func loadJSON(from url: URL) throws -> [TokenNode] {
    let data = try Data(contentsOf: url)
    
    // Try to decode the new format first (with metadata wrapper)
    do {
      let tokenExport = try JSONDecoder().decode(TokenExport.self, from: data)
      return tokenExport.tokens
    } catch {
      // Fallback to old format (direct array)
      return try JSONDecoder().decode([TokenNode].self, from: data)
    }
  }
  
  func loadTokenExport(from url: URL) throws -> TokenExport {
    logger.debug("Loading token export from: \(url.lastPathComponent)")
    let data = try Data(contentsOf: url)
    
    // Try to decode the new format first (with metadata wrapper)
    do {
      let export = try JSONDecoder().decode(TokenExport.self, from: data)
      let tokenCount = TokenHelpers.countLeafTokens(export.tokens)
      logger.info("Loaded token export: \(tokenCount) tokens, version: \(export.metadata.version)")
      return export
    } catch {
      logger.debug("New format failed, trying legacy format")
      // Fallback to old format (direct array) - create default metadata
      let tokens = try JSONDecoder().decode([TokenNode].self, from: data)
      let defaultMetadata = TokenMetadata(
        exportedAt: "Date inconnue",
        timestamp: 0,
        version: "Inconnue",
        generator: "Fichier legacy"
      )
      logger.info("Loaded legacy token export: \(tokens.count) root nodes")
      return TokenExport(metadata: defaultMetadata, tokens: tokens)
    }
  }
  
  // MARK: - File Saving
  @MainActor
  func saveToFile(data: Data, defaultName: String, contentType: UTType, title: String) async throws -> URL? {
    let savePanel = NSSavePanel()
    savePanel.title = title
    savePanel.nameFieldStringValue = defaultName
    savePanel.allowedContentTypes = [contentType]
    savePanel.canCreateDirectories = true
    
    guard savePanel.runModal() == .OK, let selectedURL = savePanel.url else { return nil }
    
    try data.write(to: selectedURL)
    return selectedURL
  }
  
  @MainActor
  func saveTextFile(content: String, defaultName: String, title: String, message: String? = nil) async throws -> URL? {
    logger.debug("Opening save panel for text file: \(defaultName)")
    let savePanel = NSSavePanel()
    savePanel.title = title
    savePanel.nameFieldStringValue = defaultName
    savePanel.allowedContentTypes = [.plainText]
    savePanel.canCreateDirectories = true
    if let message { savePanel.message = message }
    
    guard savePanel.runModal() == .OK, let selectedURL = savePanel.url else {
      logger.debug("Save panel cancelled")
      return nil
    }
    
    try content.write(to: selectedURL, atomically: true, encoding: .utf8)
    logger.info("Text file saved: \(selectedURL.lastPathComponent)")
    return selectedURL
  }
  
  // MARK: - Directory Operations
  @MainActor
  func pickDirectory(message: String = "Sélectionnez un dossier") throws -> URL? {
    let openPanel = NSOpenPanel()
    openPanel.canCreateDirectories = true
    openPanel.canChooseDirectories = true
    openPanel.canChooseFiles = false
    openPanel.allowsMultipleSelection = false
    openPanel.message = message
    
    guard openPanel.runModal() == .OK, let selectedURL = openPanel.url else {
      return nil
    }
    
    return selectedURL
  }
  
  // MARK: - Finder Operations
  @MainActor
  func openInFinder(url: URL) {
    _ = url.startAccessingSecurityScopedResource()
    defer { url.stopAccessingSecurityScopedResource() }
    NSWorkspace.shared.activateFileViewerSelecting([url])
  }
}
