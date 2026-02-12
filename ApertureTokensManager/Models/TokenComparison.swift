import Foundation

public struct ComparisonChanges: Equatable, Sendable {
  let added: [TokenSummary]
  let removed: [TokenSummary] 
  let modified: [TokenModification]
  var replacementSuggestions: [ReplacementSuggestion] = []
  var autoSuggestions: [AutoSuggestion] = []
  
  // MARK: - Manual Replacement Suggestions
  
  mutating func addReplacementSuggestion(removedTokenPath: String, suggestedTokenPath: String) {
    // Remove existing suggestion for this token first
    replacementSuggestions.removeAll { $0.removedTokenPath == removedTokenPath }
    // Add new suggestion
    replacementSuggestions.append(ReplacementSuggestion(
      removedTokenPath: removedTokenPath,
      suggestedTokenPath: suggestedTokenPath
    ))
  }
  
  mutating func removeReplacementSuggestion(for removedTokenPath: String) {
    replacementSuggestions.removeAll { $0.removedTokenPath == removedTokenPath }
  }
  
  func getSuggestion(for removedTokenPath: String) -> ReplacementSuggestion? {
    return replacementSuggestions.first { $0.removedTokenPath == removedTokenPath }
  }
  
  // MARK: - Auto Suggestions
  
  func getAutoSuggestion(for removedTokenPath: String) -> AutoSuggestion? {
    return autoSuggestions.first { $0.removedTokenPath == removedTokenPath }
  }
  
  /// Accepte une auto-suggestion en la convertissant en suggestion manuelle
  mutating func acceptAutoSuggestion(for removedTokenPath: String) {
    guard let auto = getAutoSuggestion(for: removedTokenPath) else { return }
    addReplacementSuggestion(
      removedTokenPath: removedTokenPath,
      suggestedTokenPath: auto.suggestedTokenPath
    )
  }
  
  /// Rejette une auto-suggestion (la retire de la liste)
  mutating func rejectAutoSuggestion(for removedTokenPath: String) {
    autoSuggestions.removeAll { $0.removedTokenPath == removedTokenPath }
  }
}

// Résumé léger d'un token (sans stocker le node complet)
public struct TokenSummary: Equatable, Sendable, Identifiable {
  public var id: String { path }
  let name: String
  let path: String
  let modes: TokenThemes?
  
  init(from node: TokenNode) {
    self.name = node.name
    self.path = node.path ?? node.name
    self.modes = node.modes
  }
}

// Structure pour représenter une suggestion de remplacement manuelle
public struct ReplacementSuggestion: Equatable, Sendable, Identifiable {
  public var id: String { removedTokenPath }
  let removedTokenPath: String
  let suggestedTokenPath: String
}

// Structure pour représenter une suggestion automatique avec score de confiance
public struct AutoSuggestion: Equatable, Sendable, Identifiable {
  public var id: String { removedTokenPath }
  let removedTokenPath: String
  let suggestedTokenPath: String
  let confidence: Double  // 0.0 à 1.0
  let matchFactors: MatchFactors
  
  struct MatchFactors: Equatable, Sendable {
    let pathSimilarity: Double
    let nameSimilarity: Double
    let colorSimilarity: Double
  }
}

// Structure pour représenter une modification de token (allégée)
public struct TokenModification: Equatable, Sendable, Identifiable {
  public var id: String { tokenPath }
  let tokenPath: String
  let tokenName: String
  let colorChanges: [ColorChange]
}

public struct ColorChange: Equatable, Sendable, Identifiable {
  public var id: String { "\(brandName)-\(theme)" }
  let brandName: String
  let theme: String
  let oldColor: String
  let newColor: String
}
