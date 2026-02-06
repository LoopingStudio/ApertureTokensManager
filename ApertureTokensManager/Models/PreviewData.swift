import Foundation

#if DEBUG
enum PreviewData {
  // MARK: - Token Values
  
  static let lightBlueValue = TokenValue(
    hex: "#0066CC",
    primitiveName: "blue/500"
  )
  
  static let darkBlueValue = TokenValue(
    hex: "#3399FF",
    primitiveName: "blue/400"
  )
  
  static let lightGreenValue = TokenValue(
    hex: "#00AA55",
    primitiveName: "green/500"
  )
  
  static let darkGreenValue = TokenValue(
    hex: "#33CC77",
    primitiveName: "green/400"
  )
  
  // MARK: - Token Themes
  
  static let blueThemes = TokenThemes(
    legacy: TokenThemes.Appearance(
      light: lightBlueValue,
      dark: darkBlueValue
    ),
    newBrand: TokenThemes.Appearance(
      light: TokenValue(hex: "#0055BB", primitiveName: "brand/blue/500"),
      dark: TokenValue(hex: "#4488DD", primitiveName: "brand/blue/400")
    )
  )
  
  static let greenThemes = TokenThemes(
    legacy: TokenThemes.Appearance(
      light: lightGreenValue,
      dark: darkGreenValue
    ),
    newBrand: nil
  )
  
  // MARK: - Token Nodes
  
  static let singleToken = TokenNode(
    name: "primary",
    type: .token,
    path: "colors/brand/primary",
    modes: blueThemes
  )
  
  static let secondaryToken = TokenNode(
    name: "secondary",
    type: .token,
    path: "colors/brand/secondary",
    modes: greenThemes
  )
  
  static let disabledToken = TokenNode(
    name: "#disabled",
    type: .token,
    path: "colors/state/#disabled",
    modes: TokenThemes(
      legacy: TokenThemes.Appearance(
        light: TokenValue(hex: "#CCCCCC", primitiveName: "gray/300"),
        dark: TokenValue(hex: "#666666", primitiveName: "gray/600")
      ),
      newBrand: nil
    ),
    isEnabled: false
  )
  
  static let brandGroup = TokenNode(
    name: "brand",
    type: .group,
    path: "colors/brand",
    children: [singleToken, secondaryToken]
  )
  
  static let stateGroup = TokenNode(
    name: "state",
    type: .group,
    path: "colors/state",
    children: [disabledToken]
  )
  
  static let colorsGroup = TokenNode(
    name: "colors",
    type: .group,
    path: "colors",
    children: [brandGroup, stateGroup]
  )
  
  static let rootNodes: [TokenNode] = [colorsGroup]
  
  // MARK: - Metadata
  
  static let metadata = TokenMetadata(
    exportedAt: "2026-02-05 14:30:00",
    timestamp: 1738764600,
    version: "2.1.0",
    generator: "Figma"
  )
  
  // MARK: - History Entries
  
  static let importHistoryEntries: [ImportHistoryEntry] = [
    ImportHistoryEntry(
      date: Date(),
      fileName: "tokens-v2.1.json",
      bookmarkData: nil,
      metadata: metadata,
      tokenCount: 156
    ),
    ImportHistoryEntry(
      date: Date().addingTimeInterval(-86400),
      fileName: "tokens-v2.0.json",
      bookmarkData: nil,
      metadata: TokenMetadata(
        exportedAt: "2026-02-04 10:00:00",
        timestamp: 1738663200,
        version: "2.0.0",
        generator: "Figma"
      ),
      tokenCount: 142
    )
  ]
  
  // MARK: - Comparison Data
  
  static let addedTokens: [TokenSummary] = [
    TokenSummary(from: TokenNode(
      name: "accent",
      type: .token,
      path: "colors/brand/accent",
      modes: blueThemes
    )),
    TokenSummary(from: TokenNode(
      name: "warning",
      type: .token,
      path: "colors/feedback/warning",
      modes: greenThemes
    ))
  ]
  
  static let removedTokens: [TokenSummary] = [
    TokenSummary(from: TokenNode(
      name: "old-primary",
      type: .token,
      path: "colors/legacy/old-primary",
      modes: blueThemes
    ))
  ]
  
  static let modifiedTokens: [TokenModification] = [
    TokenModification(
      tokenPath: "colors/brand/primary",
      tokenName: "primary",
      colorChanges: [
        ColorChange(
          brandName: "Legacy",
          theme: "light",
          oldColor: "#0055AA",
          newColor: "#0066CC"
        ),
        ColorChange(
          brandName: "Legacy",
          theme: "dark",
          oldColor: "#3388EE",
          newColor: "#3399FF"
        )
      ]
    )
  ]
  
  static let autoSuggestions: [AutoSuggestion] = [
    AutoSuggestion(
      removedTokenPath: "colors/legacy/old-primary",
      suggestedTokenPath: "colors/brand/accent",
      confidence: 0.78,
      matchFactors: AutoSuggestion.MatchFactors(
        pathSimilarity: 0.60,       // Structure: 20%
        nameSimilarity: 0.85,       // Contexte d'usage: 30%
        colorSimilarity: 0.92       // Couleur: 50% (priorité max)
      )
    )
  ]
  
  static let comparisonChanges: ComparisonChanges = {
    var changes = ComparisonChanges(
      added: addedTokens,
      removed: removedTokens,
      modified: modifiedTokens
    )
    changes.autoSuggestions = autoSuggestions
    return changes
  }()
  
  static let comparisonHistoryEntries: [ComparisonHistoryEntry] = [
    ComparisonHistoryEntry(
      date: Date(),
      oldFile: FileSnapshot(
        fileName: "tokens-v2.0.json",
        bookmarkData: nil,
        metadata: TokenMetadata(
          exportedAt: "2026-02-04 10:00:00",
          timestamp: 1738663200,
          version: "2.0.0",
          generator: "Figma"
        )
      ),
      newFile: FileSnapshot(
        fileName: "tokens-v2.1.json",
        bookmarkData: nil,
        metadata: metadata
      ),
      summary: ComparisonSummary(
        addedCount: 2,
        removedCount: 1,
        modifiedCount: 1
      )
    )
  ]
}
#endif
