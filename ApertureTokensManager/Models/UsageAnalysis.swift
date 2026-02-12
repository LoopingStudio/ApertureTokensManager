import Foundation

// MARK: - Scan Progress

/// Progression du scan en cours
public struct ScanProgress: Equatable, Sendable {
  /// Nom du dossier en cours de scan
  public let currentDirectory: String
  
  /// Nombre de fichiers scannés
  public let filesScanned: Int
  
  /// Nombre total de fichiers à scanner
  public let totalFiles: Int
  
  /// Phase actuelle du scan
  public let phase: Phase
  
  /// Pourcentage de progression (0-1)
  public var progress: Double {
    guard totalFiles > 0 else { return 0 }
    return Double(filesScanned) / Double(totalFiles)
  }
  
  /// Pourcentage formaté
  public var percentFormatted: String {
    "\(Int(progress * 100))%"
  }
  
  public enum Phase: String, Sendable, Equatable {
    case discovering = "Recherche des fichiers..."
    case scanning = "Analyse en cours..."
    case processing = "Traitement des résultats..."
  }
  
  public init(currentDirectory: String, filesScanned: Int, totalFiles: Int, phase: Phase) {
    self.currentDirectory = currentDirectory
    self.filesScanned = filesScanned
    self.totalFiles = totalFiles
    self.phase = phase
  }
  
  public static let initial = ScanProgress(
    currentDirectory: "",
    filesScanned: 0,
    totalFiles: 0,
    phase: .discovering
  )
}

// MARK: - Usage Analysis Models

/// Rapport complet d'analyse d'utilisation des tokens
public struct TokenUsageReport: Equatable, Sendable, Identifiable {
  public var id: Date { analyzedAt }
  
  /// Date de l'analyse
  let analyzedAt: Date
  
  /// Dossiers scannés
  let scannedDirectories: [ScannedDirectory]
  
  /// Tokens utilisés avec leurs occurrences
  let usedTokens: [UsedToken]
  
  /// Tokens non utilisés (orphelins)
  let orphanedTokens: [OrphanedToken]
  
  /// Statistiques globales
  var statistics: UsageStatistics {
    UsageStatistics(
      totalTokens: usedTokens.count + orphanedTokens.count,
      usedCount: usedTokens.count,
      orphanedCount: orphanedTokens.count,
      totalUsages: usedTokens.reduce(0) { $0 + $1.usageCount },
      filesScanned: scannedDirectories.reduce(0) { $0 + $1.filesScanned }
    )
  }
  
  public init(
    analyzedAt: Date = Date(),
    scannedDirectories: [ScannedDirectory],
    usedTokens: [UsedToken],
    orphanedTokens: [OrphanedToken]
  ) {
    self.analyzedAt = analyzedAt
    self.scannedDirectories = scannedDirectories
    self.usedTokens = usedTokens
    self.orphanedTokens = orphanedTokens
  }
  
  static let empty = TokenUsageReport(
    scannedDirectories: [],
    usedTokens: [],
    orphanedTokens: []
  )
}

// MARK: - Scanned Directory

/// Représente un dossier scanné
public struct ScannedDirectory: Equatable, Sendable, Identifiable {
  public var id: URL { url }
  
  /// Nom affiché du dossier
  let name: String
  
  /// URL du dossier
  let url: URL
  
  /// Bookmark pour accès futur
  let bookmarkData: Data?
  
  /// Nombre de fichiers Swift trouvés
  let filesScanned: Int
  
  public init(name: String, url: URL, bookmarkData: Data?, filesScanned: Int) {
    self.name = name
    self.url = url
    self.bookmarkData = bookmarkData
    self.filesScanned = filesScanned
  }
}

// MARK: - Used Token

/// Token utilisé avec ses occurrences
public struct UsedToken: Equatable, Sendable, Identifiable {
  public var id: String { enumCase }
  
  /// Nom du case enum (ex: "bgBrandSolid")
  let enumCase: String
  
  /// Path original du token (ex: "Background/Brand/solid")
  let originalPath: String?
  
  /// Nombre total d'utilisations
  var usageCount: Int { usages.count }
  
  /// Liste des usages détaillés
  let usages: [TokenUsage]
  
  public init(enumCase: String, originalPath: String?, usages: [TokenUsage]) {
    self.enumCase = enumCase
    self.originalPath = originalPath
    self.usages = usages
  }
}

/// Occurrence d'utilisation d'un token
public struct TokenUsage: Equatable, Sendable, Identifiable {
  public var id: String { "\(filePath):\(lineNumber)" }
  
  /// Chemin du fichier
  let filePath: String
  
  /// Numéro de ligne
  let lineNumber: Int
  
  /// Contenu de la ligne
  let lineContent: String
  
  /// Type de match trouvé
  let matchType: String
  
  public init(filePath: String, lineNumber: Int, lineContent: String, matchType: String) {
    self.filePath = filePath
    self.lineNumber = lineNumber
    self.lineContent = lineContent
    self.matchType = matchType
  }
}

// MARK: - Orphaned Token

/// Token non utilisé (orphelin)
public struct OrphanedToken: Equatable, Sendable, Identifiable {
  public var id: String { enumCase }
  
  /// Nom du case enum (ex: "bgBrandSolid")
  let enumCase: String
  
  /// Path original du token (ex: "Background/Brand/solid")
  let originalPath: String?
  
  /// Catégorie du token (premier segment du path)
  var category: String {
    guard let path = originalPath else { return "Uncategorized" }
    return String(path.split(separator: "/").first ?? "Uncategorized")
  }
  
  public init(enumCase: String, originalPath: String?) {
    self.enumCase = enumCase
    self.originalPath = originalPath
  }
}

// MARK: - Statistics

/// Statistiques d'utilisation
public struct UsageStatistics: Equatable, Sendable {
  let totalTokens: Int
  let usedCount: Int
  let orphanedCount: Int
  let totalUsages: Int
  let filesScanned: Int
  
  var usagePercentage: Double {
    guard totalTokens > 0 else { return 0 }
    return Double(usedCount) / Double(totalTokens) * 100
  }
  
  var orphanedPercentage: Double {
    guard totalTokens > 0 else { return 0 }
    return Double(orphanedCount) / Double(totalTokens) * 100
  }
}

// MARK: - Analysis Configuration

/// Configuration pour l'analyse
public struct UsageAnalysisConfig: Equatable, Sendable {
  /// Dossiers à scanner
  var directoriesToScan: [ScanDirectory]
  
  /// Ignorer les fichiers de test
  var ignoreTestFiles: Bool
  
  /// Ignorer les fichiers de preview
  var ignorePreviewFiles: Bool
  
  /// Ignorer les fichiers de déclaration de tokens (Aperture+Colors.swift, etc.)
  var ignoreTokenDeclarationFiles: Bool
  
  /// Patterns de noms de fichiers à ignorer (déclarations de tokens)
  static let tokenDeclarationPatterns = [
    "aperture+colors",
    "aperture+color", 
    "colors.swift",
    "colortoken",
    "designsystemcolors"
  ]
  
  public init(
    directoriesToScan: [ScanDirectory] = [],
    ignoreTestFiles: Bool = true,
    ignorePreviewFiles: Bool = true,
    ignoreTokenDeclarationFiles: Bool = true
  ) {
    self.directoriesToScan = directoriesToScan
    self.ignoreTestFiles = ignoreTestFiles
    self.ignorePreviewFiles = ignorePreviewFiles
    self.ignoreTokenDeclarationFiles = ignoreTokenDeclarationFiles
  }
  
  static let `default` = UsageAnalysisConfig()
}

/// Dossier à scanner (avant analyse)
public struct ScanDirectory: Equatable, Sendable, Identifiable, Codable {
  public let id: UUID
  
  /// Nom affiché
  let name: String
  
  /// URL du dossier - reconstruite depuis le bookmark
  var url: URL
  
  /// Bookmark pour accès persistant
  let bookmarkData: Data?
  
  public init(name: String, url: URL, bookmarkData: Data?) {
    self.id = UUID()
    self.name = name
    self.url = url
    self.bookmarkData = bookmarkData
  }
  
  // MARK: - Codable
  
  enum CodingKeys: String, CodingKey {
    case id, name, bookmarkData
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try container.decode(UUID.self, forKey: .id)
    self.name = try container.decode(String.self, forKey: .name)
    self.bookmarkData = try container.decodeIfPresent(Data.self, forKey: .bookmarkData)
    
    // Reconstruire l'URL depuis le bookmark
    if let bookmarkData = self.bookmarkData {
      var _isStale = false
      if let resolvedURL = try? URL(
        resolvingBookmarkData: bookmarkData,
        options: .withSecurityScope,
        relativeTo: nil,
        bookmarkDataIsStale: &_isStale
      ) {
        self.url = resolvedURL
      } else {
        // Fallback: URL invalide mais on garde l'entrée
        self.url = URL(fileURLWithPath: "/invalid")
      }
    } else {
      self.url = URL(fileURLWithPath: "/invalid")
    }
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(name, forKey: .name)
    try container.encodeIfPresent(bookmarkData, forKey: .bookmarkData)
  }
  
  /// Tente de résoudre l'URL et démarrer l'accès security-scoped
  public func resolveAndAccess() -> URL? {
    guard let bookmarkData = bookmarkData else { return nil }
    var _isStale = false
    guard let resolvedURL = try? URL(
      resolvingBookmarkData: bookmarkData,
      options: .withSecurityScope,
      relativeTo: nil,
      bookmarkDataIsStale: &_isStale
    ) else { return nil }
    
    _ = resolvedURL.startAccessingSecurityScopedResource()
    return resolvedURL
  }
}
