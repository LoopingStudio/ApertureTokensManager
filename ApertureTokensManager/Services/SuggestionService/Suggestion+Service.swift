import Foundation
import OSLog

/// Configuration pour le fuzzy matching
/// Hiérarchie des priorités :
/// 1. Couleur (50%) - Le plus important pour trouver un remplacement visuel
/// 2. Contexte d'usage (30%) - bg, fg, hover, solid, surface, text, border...
/// 3. Structure/Path (20%) - Moins important si couleur et contexte matchent
struct SuggestionMatchingConfig: Equatable, Sendable {
  let minimumConfidenceThreshold: Double
  let colorWeight: Double
  let usageContextWeight: Double
  let structureWeight: Double
  
  static let `default` = Self(
    minimumConfidenceThreshold: 0.35,
    colorWeight: 0.50,
    usageContextWeight: 0.30,
    structureWeight: 0.20
  )
}

/// Service pour calculer les suggestions de remplacement intelligentes
actor SuggestionService {
  private let config: SuggestionMatchingConfig
  private let logger = AppLogger.suggestion
  
  init(config: SuggestionMatchingConfig = .default) {
    self.config = config
  }
  
  /// Calcule les suggestions de remplacement pour tous les tokens supprimés
  func computeSuggestions(
    removedTokens: [TokenSummary],
    addedTokens: [TokenSummary]
  ) -> [AutoSuggestion] {
    logger.debug("Computing suggestions for \(removedTokens.count) removed tokens against \(addedTokens.count) added tokens")
    var suggestions: [AutoSuggestion] = []
    
    for removed in removedTokens {
      if let bestMatch = findBestMatch(for: removed, in: addedTokens) {
        suggestions.append(bestMatch)
      }
    }
    
    logger.info("Found \(suggestions.count) suggestions with confidence >= \(self.config.minimumConfidenceThreshold)")
    return suggestions
  }
  
  /// Trouve le meilleur match pour un token supprimé parmi les candidats
  private func findBestMatch(
    for removedToken: TokenSummary,
    in candidates: [TokenSummary]
  ) -> AutoSuggestion? {
    var bestMatch: (token: TokenSummary, score: Double, factors: AutoSuggestion.MatchFactors)?
    
    for candidate in candidates {
      let factors = computeMatchFactors(removed: removedToken, candidate: candidate)
      let score = computeWeightedScore(factors: factors)
      
      if score >= config.minimumConfidenceThreshold {
        if bestMatch == nil || score > bestMatch!.score {
          bestMatch = (candidate, score, factors)
        }
      }
    }
    
    guard let match = bestMatch else { return nil }
    
    return AutoSuggestion(
      removedTokenPath: removedToken.path,
      suggestedTokenPath: match.token.path,
      confidence: match.score,
      matchFactors: match.factors
    )
  }
  
  /// Calcule les facteurs de similarité individuels
  private func computeMatchFactors(
    removed: TokenSummary,
    candidate: TokenSummary
  ) -> AutoSuggestion.MatchFactors {
    // 1. Couleur - Priorité maximale
    let colorSimilarity = FuzzyMatchingHelpers.computeColorSimilarity(removed.modes, candidate.modes)
    
    // 2. Contexte d'usage - Analyser les marqueurs sémantiques
    let usageContextSimilarity = FuzzyMatchingHelpers.computeUsageContextSimilarity(
      removed.path,
      removed.name,
      candidate.path,
      candidate.name
    )
    
    // 3. Structure du path - Moins prioritaire
    let structureSimilarity = FuzzyMatchingHelpers.computeStructureSimilarity(removed.path, candidate.path)
    
    return AutoSuggestion.MatchFactors(
      pathSimilarity: structureSimilarity,
      nameSimilarity: usageContextSimilarity,
      colorSimilarity: colorSimilarity
    )
  }
  
  /// Calcule le score pondéré final avec la nouvelle hiérarchie
  private func computeWeightedScore(factors: AutoSuggestion.MatchFactors) -> Double {
    // factors.colorSimilarity = couleur
    // factors.nameSimilarity = contexte d'usage (réutilisé pour compatibilité)
    // factors.pathSimilarity = structure (réutilisé pour compatibilité)
    return (factors.colorSimilarity * config.colorWeight) +
           (factors.nameSimilarity * config.usageContextWeight) +
           (factors.pathSimilarity * config.structureWeight)
  }
}
