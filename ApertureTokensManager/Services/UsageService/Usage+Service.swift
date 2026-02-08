import Dependencies
import Foundation
import OSLog

/// Service pour analyser l'utilisation des tokens dans les projets Swift
actor UsageService {
  private let logger = AppLogger.usage
  
  // MARK: - Public API
  
  /// Analyse l'utilisation des tokens dans les dossiers spécifiés
  func analyzeUsage(
    directories: [ScanDirectory],
    exportedTokens: [TokenNode],
    config: UsageAnalysisConfig,
    tokenFilters: TokenFilters
  ) async throws -> TokenUsageReport {
    logger.info("Starting usage analysis for \(directories.count) directories")
    
    // Appliquer les filtres d'export aux tokens (comme pour l'export réel)
    let filteredTokens = filterTokensForExport(exportedTokens, filters: tokenFilters)
    
    // Convertir les tokens filtrés en Set de cases enum pour recherche rapide
    let tokenMapping = buildTokenMapping(from: filteredTokens)
    let knownTokens = Set(tokenMapping.keys)
    
    var allUsages: [String: [TokenUsageHelpers.UsageMatch]] = [:]
    var scannedDirectories: [ScannedDirectory] = []
    
    // Scanner chaque dossier
    for directory in directories {
      let (usages, scanned) = try await scanDirectory(
        directory,
        knownTokens: knownTokens,
        config: config
      )
      
      // Fusionner les usages
      for (token, matches) in usages {
        allUsages[token, default: []].append(contentsOf: matches)
      }
      
      scannedDirectories.append(scanned)
    }
    
    // Construire le rapport
    let usedTokens = buildUsedTokens(from: allUsages, tokenMapping: tokenMapping)
    let orphanedTokens = buildOrphanedTokens(
      allTokens: tokenMapping,
      usedTokens: Set(allUsages.keys)
    )
    
    let report = TokenUsageReport(
      scannedDirectories: scannedDirectories,
      usedTokens: usedTokens,
      orphanedTokens: orphanedTokens
    )
    
    logger.info("Analysis complete: \(usedTokens.count) used, \(orphanedTokens.count) orphaned, \(report.statistics.filesScanned) files scanned")
    return report
  }
  
  // MARK: - Private Helpers
  
  /// Construit un mapping enumCase -> originalPath
  private func buildTokenMapping(from nodes: [TokenNode]) -> [String: String?] {
    var mapping: [String: String?] = [:]
    
    func collect(_ nodes: [TokenNode]) {
      for node in nodes {
        if node.type == .token {
          let enumCase = TokenUsageHelpers.tokenNameToEnumCase(node.name)
          mapping[enumCase] = node.path
        }
        if let children = node.children {
          collect(children)
        }
      }
    }
    
    collect(nodes)
    return mapping
  }
  
  /// Scanne un dossier et retourne les usages trouvés
  private func scanDirectory(
    _ directory: ScanDirectory,
    knownTokens: Set<String>,
    config: UsageAnalysisConfig
  ) async throws -> ([String: [TokenUsageHelpers.UsageMatch]], ScannedDirectory) {
    // Résoudre le bookmark si disponible
    let url: URL
    if let bookmarkData = directory.bookmarkData {
      var isStale = false
      if let resolvedURL = try? URL(
        resolvingBookmarkData: bookmarkData,
        options: .withSecurityScope,
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      ) {
        url = resolvedURL
      } else {
        url = directory.url
      }
    } else {
      url = directory.url
    }
    
    // Accéder au dossier
    let canAccess = url.startAccessingSecurityScopedResource()
    defer {
      if canAccess {
        url.stopAccessingSecurityScopedResource()
      }
    }
    
    // Trouver les fichiers Swift
    let swiftFiles = try TokenUsageHelpers.findSwiftFiles(in: url)
    
    // Filtrer selon config
    let filteredFiles = swiftFiles.filter { fileURL in
      let fileName = fileURL.lastPathComponent.lowercased()
      
      if config.ignoreTestFiles && (fileName.contains("test") || fileName.contains("spec")) {
        return false
      }
      
      if config.ignorePreviewFiles && fileName.contains("preview") {
        return false
      }
      
      // Ignorer les fichiers de déclaration de tokens (évite de compter les "case tokenName" comme usages)
      if config.ignoreTokenDeclarationFiles {
        for pattern in UsageAnalysisConfig.tokenDeclarationPatterns {
          if fileName.contains(pattern) {
            return false
          }
        }
      }
      
      return true
    }
    
    // Scanner chaque fichier
    var usages: [String: [TokenUsageHelpers.UsageMatch]] = [:]
    
    for fileURL in filteredFiles {
      guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
        continue
      }
      
      let matches = TokenUsageHelpers.findTokenUsages(
        in: content,
        filePath: fileURL.path,
        knownTokens: knownTokens
      )
      
      for match in matches {
        usages[match.tokenEnumCase, default: []].append(match)
      }
    }
    
    let scanned = ScannedDirectory(
      name: directory.name,
      url: url,
      bookmarkData: directory.bookmarkData,
      filesScanned: filteredFiles.count
    )
    
    return (usages, scanned)
  }
  
  /// Construit la liste des tokens utilisés
  private func buildUsedTokens(
    from usages: [String: [TokenUsageHelpers.UsageMatch]],
    tokenMapping: [String: String?]
  ) -> [UsedToken] {
    usages.map { (enumCase, matches) in
      UsedToken(
        enumCase: enumCase,
        originalPath: tokenMapping[enumCase] ?? nil,
        usages: matches.map { match in
          TokenUsage(
            filePath: match.filePath,
            lineNumber: match.lineNumber,
            lineContent: match.lineContent,
            matchType: match.matchType.rawValue
          )
        }
      )
    }
    .sorted { $0.usageCount > $1.usageCount }
  }
  
  /// Construit la liste des tokens orphelins
  private func buildOrphanedTokens(
    allTokens: [String: String?],
    usedTokens: Set<String>
  ) -> [OrphanedToken] {
    allTokens
      .filter { !usedTokens.contains($0.key) }
      .map { OrphanedToken(enumCase: $0.key, originalPath: $0.value) }
      .sorted { $0.enumCase < $1.enumCase }
  }
  
  // MARK: - Token Filtering
  
  /// Filtre les tokens selon les filtres d'export (même logique que ExportService)
  private func filterTokensForExport(_ nodes: [TokenNode], filters: TokenFilters) -> [TokenNode] {
    var result: [TokenNode] = []
    
    for node in nodes {
      // Vérifier si le noeud doit être exclu
      if shouldExcludeNode(node, filters: filters) {
        continue
      }
      
      var newNode = node
      
      // Filtrer récursivement les enfants
      if let children = node.children {
        let filteredChildren = filterTokensForExport(children, filters: filters)
        newNode.children = filteredChildren.isEmpty ? nil : filteredChildren
      }
      
      // Garder le noeud s'il a des enfants ou s'il est de type token
      if newNode.children != nil || newNode.type == .token {
        result.append(newNode)
      }
    }
    
    return result
  }
  
  /// Détermine si un noeud doit être exclu selon les filtres
  private func shouldExcludeNode(_ node: TokenNode, filters: TokenFilters) -> Bool {
    // Exclure le groupe Utility
    if filters.excludeUtilityGroup && node.type == .group {
      let nameLower = node.name.lowercased()
      if nameLower == "utility" || nameLower == "utilities" {
        return true
      }
    }
    
    // Exclure les tokens commençant par #
    if filters.excludeTokensStartingWithHash && node.type == .token {
      if node.name.hasPrefix("#") {
        return true
      }
    }
    
    // Exclure les tokens finissant par hover
    if filters.excludeTokensEndingWithHover && node.type == .token {
      let nameLower = node.name.lowercased()
      if nameLower.hasSuffix("hover") || nameLower.hasSuffix("-hover") || nameLower.hasSuffix("_hover") {
        return true
      }
    }
    
    return false
  }
}
