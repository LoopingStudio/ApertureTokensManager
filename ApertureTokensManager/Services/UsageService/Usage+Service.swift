import Dependencies
import Foundation
import OSLog

/// Service pour analyser l'utilisation des tokens dans les projets Swift
actor UsageService {
  private let logger = AppLogger.usage
  
  /// Nombre de fichiers à traiter en parallèle
  private let parallelBatchSize = 50
  
  /// Intervalle minimum entre les updates de progression (en ms)
  private let progressUpdateInterval: UInt64 = 100_000_000 // 100ms
  
  // MARK: - Public API
  
  /// Analyse l'utilisation des tokens dans les dossiers spécifiés avec progression
  func analyzeUsage(
    directories: [ScanDirectory],
    exportedTokens: [TokenNode],
    config: UsageAnalysisConfig,
    tokenFilters: TokenFilters,
    onProgress: @escaping @Sendable (ScanProgress) -> Void
  ) async throws -> TokenUsageReport {
    logger.info("Starting usage analysis for \(directories.count) directories")
    
    // Phase 1: Préparation
    onProgress(ScanProgress(
      currentDirectory: "",
      filesScanned: 0,
      totalFiles: 0,
      phase: .discovering
    ))
    
    // Appliquer les filtres d'export aux tokens (comme pour l'export réel)
    let filteredTokens = filterTokensForExport(exportedTokens, filters: tokenFilters)
    
    // Convertir les tokens filtrés en Set de cases enum pour recherche rapide
    let tokenMapping = buildTokenMapping(from: filteredTokens)
    let knownTokens = Set(tokenMapping.keys)
    
    // Phase 2: Découverte des fichiers
    var allFilesToScan: [(url: URL, directory: ScanDirectory)] = []
    var directoryAccessInfo: [(directory: ScanDirectory, resolvedURL: URL, canAccess: Bool)] = []
    
    for directory in directories {
      try Task.checkCancellation()
      
      let (resolvedURL, canAccess) = resolveDirectory(directory)
      directoryAccessInfo.append((directory, resolvedURL, canAccess))
      
      onProgress(ScanProgress(
        currentDirectory: directory.name,
        filesScanned: 0,
        totalFiles: 0,
        phase: .discovering
      ))
      
      let swiftFiles = try TokenUsageHelpers.findSwiftFiles(in: resolvedURL)
      let filteredFiles = filterFiles(swiftFiles, config: config)
      
      for file in filteredFiles {
        allFilesToScan.append((file, directory))
      }
    }
    
    let totalFiles = allFilesToScan.count
    logger.info("Found \(totalFiles) files to scan")
    
    // Envoyer la progression initiale avec le total
    onProgress(ScanProgress(
      currentDirectory: directories.first?.name ?? "",
      filesScanned: 0,
      totalFiles: totalFiles,
      phase: .scanning
    ))
    
    // Petit délai pour laisser l'UI afficher le total
    try await Task.sleep(nanoseconds: progressUpdateInterval)
    
    // Phase 3: Scan parallèle des fichiers
    var allUsages: [String: [TokenUsageHelpers.UsageMatch]] = [:]
    var filesScannedCount = 0
    var lastProgressUpdate = ContinuousClock.now
    
    // Traiter par batches pour permettre les updates de progression
    for batchStart in stride(from: 0, to: allFilesToScan.count, by: parallelBatchSize) {
      try Task.checkCancellation()
      
      let batchEnd = min(batchStart + parallelBatchSize, allFilesToScan.count)
      let batch = Array(allFilesToScan[batchStart..<batchEnd])
      
      // Traiter le batch en parallèle
      let batchResults = await withTaskGroup(of: [TokenUsageHelpers.UsageMatch].self) { group in
        for (fileURL, _) in batch {
          group.addTask {
            guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
              return []
            }
            return TokenUsageHelpers.findTokenUsages(
              in: content,
              filePath: fileURL.path,
              knownTokens: knownTokens
            )
          }
        }
        
        var results: [[TokenUsageHelpers.UsageMatch]] = []
        for await matches in group {
          results.append(matches)
        }
        return results
      }
      
      // Fusionner les résultats du batch
      for matches in batchResults {
        for match in matches {
          allUsages[match.tokenEnumCase, default: []].append(match)
        }
      }
      
      filesScannedCount += batch.count
      
      // Mettre à jour la progression (throttled)
      let now = ContinuousClock.now
      let elapsed = now - lastProgressUpdate
      if elapsed >= .milliseconds(50) || filesScannedCount == totalFiles {
        let currentDir = batch.first?.directory.name ?? ""
        onProgress(ScanProgress(
          currentDirectory: currentDir,
          filesScanned: filesScannedCount,
          totalFiles: totalFiles,
          phase: .scanning
        ))
        lastProgressUpdate = now
        
        // Yield pour laisser l'UI respirer
        await Task.yield()
      }
    }
    
    // Libérer les accès security-scoped
    for (_, resolvedURL, canAccess) in directoryAccessInfo {
      if canAccess {
        resolvedURL.stopAccessingSecurityScopedResource()
      }
    }
    
    // Envoyer 100% et laisser l'UI l'afficher
    onProgress(ScanProgress(
      currentDirectory: "",
      filesScanned: totalFiles,
      totalFiles: totalFiles,
      phase: .scanning
    ))
    
    // Petit délai pour voir le 100%
    try await Task.sleep(for: .milliseconds(300))
    
    // Phase 4: Construction du rapport
    onProgress(ScanProgress(
      currentDirectory: "",
      filesScanned: totalFiles,
      totalFiles: totalFiles,
      phase: .processing
    ))
    
    try Task.checkCancellation()
    
    // Construire les scannedDirectories
    var scannedDirectories: [ScannedDirectory] = []
    for directory in directories {
      let filesInDir = allFilesToScan.filter { $0.directory.id == directory.id }.count
      scannedDirectories.append(ScannedDirectory(
        name: directory.name,
        url: directory.url,
        bookmarkData: directory.bookmarkData,
        filesScanned: filesInDir
      ))
    }
    
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
  
  /// Résout l'URL d'un dossier et démarre l'accès security-scoped
  private func resolveDirectory(_ directory: ScanDirectory) -> (url: URL, canAccess: Bool) {
    let url: URL
    if let bookmarkData = directory.bookmarkData {
      var _isStale = false
      if let resolvedURL = try? URL(
        resolvingBookmarkData: bookmarkData,
        options: .withSecurityScope,
        relativeTo: nil,
        bookmarkDataIsStale: &_isStale
      ) {
        url = resolvedURL
      } else {
        url = directory.url
      }
    } else {
      url = directory.url
    }
    
    let canAccess = url.startAccessingSecurityScopedResource()
    return (url, canAccess)
  }
  
  /// Filtre les fichiers selon la configuration
  private func filterFiles(_ files: [URL], config: UsageAnalysisConfig) -> [URL] {
    files.filter { fileURL in
      let fileName = fileURL.lastPathComponent.lowercased()
      
      if config.ignoreTestFiles && (fileName.contains("test") || fileName.contains("spec")) {
        return false
      }
      
      if config.ignorePreviewFiles && fileName.contains("preview") {
        return false
      }
      
      if config.ignoreTokenDeclarationFiles {
        for pattern in UsageAnalysisConfig.tokenDeclarationPatterns {
          if fileName.contains(pattern) {
            return false
          }
        }
      }
      
      return true
    }
  }
  
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
