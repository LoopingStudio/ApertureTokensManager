import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct UsageClient: Sendable {
  /// Analyse l'utilisation des tokens dans les dossiers spécifiés avec callback de progression
  var analyzeUsage: @Sendable (
    _ directories: [ScanDirectory],
    _ exportedTokens: [TokenNode],
    _ config: UsageAnalysisConfig,
    _ tokenFilters: TokenFilters,
    _ onProgress: @escaping @Sendable (ScanProgress) -> Void
  ) async throws -> TokenUsageReport = { _, _, _, _, _ in .empty }
}

// MARK: - Dependency Key

extension UsageClient: DependencyKey {
  static let liveValue: Self = {
    let service = UsageService()
    
    return Self(
      analyzeUsage: { directories, tokens, config, tokenFilters, onProgress in
        try await service.analyzeUsage(
          directories: directories,
          exportedTokens: tokens,
          config: config,
          tokenFilters: tokenFilters,
          onProgress: onProgress
        )
      }
    )
  }()
  
  static let testValue: Self = Self(
    analyzeUsage: { _, _, _, _, _ in .empty }
  )
  
  static let previewValue: Self = Self(
    analyzeUsage: { _, tokens, _, _, onProgress in
      // Simuler une progression
      for i in 0...10 {
        try? await Task.sleep(for: .milliseconds(100))
        onProgress(ScanProgress(
          currentDirectory: "Preview",
          filesScanned: i * 10,
          totalFiles: 100,
          phase: .scanning
        ))
      }
      
      // Générer des données de preview
      let allTokens = TokenHelpers.flattenTokens(tokens)
      let usedCount = min(allTokens.count / 2, 5)
      let orphanedCount = min(allTokens.count - usedCount, 3)
      
      let usedTokens = allTokens.prefix(usedCount).map { node in
        UsedToken(
          enumCase: TokenUsageHelpers.tokenNameToEnumCase(node.name),
          originalPath: node.path,
          usages: [
            TokenUsage(
              filePath: "/App/Views/ContentView.swift",
              lineNumber: 42,
              lineContent: ".foregroundColor(.bgBrandSolid)",
              matchType: "."
            )
          ]
        )
      }
      
      let orphanedTokens = allTokens.dropFirst(usedCount).prefix(orphanedCount).map { node in
        OrphanedToken(
          enumCase: TokenUsageHelpers.tokenNameToEnumCase(node.name),
          originalPath: node.path
        )
      }
      
      return TokenUsageReport(
        scannedDirectories: [
          ScannedDirectory(
            name: "MyApp",
            url: URL(fileURLWithPath: "/Users/dev/MyApp"),
            bookmarkData: nil,
            filesScanned: 42
          )
        ],
        usedTokens: Array(usedTokens),
        orphanedTokens: Array(orphanedTokens)
      )
    }
  )
}

// MARK: - Dependency Values

extension DependencyValues {
  var usageClient: UsageClient {
    get { self[UsageClient.self] }
    set { self[UsageClient.self] = newValue }
  }
}
