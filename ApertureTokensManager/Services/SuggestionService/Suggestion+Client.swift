import Dependencies
import Foundation

struct SuggestionClient {
  var computeSuggestions: @Sendable (
    _ removedTokens: [TokenSummary],
    _ addedTokens: [TokenSummary]
  ) async -> [AutoSuggestion]
}

extension SuggestionClient: DependencyKey {
  static let liveValue: Self = {
    let service = SuggestionService()
    return .init(
      computeSuggestions: { await service.computeSuggestions(removedTokens: $0, addedTokens: $1) }
    )
  }()
  
  static let testValue: Self = .init(
    computeSuggestions: { _, _ in [] }
  )
  
  static let previewValue: Self = .init(
    computeSuggestions: { removed, added in
      // Pour les previews, générer des suggestions fictives
      guard let firstRemoved = removed.first, let firstAdded = added.first else { return [] }
      return [
        AutoSuggestion(
          removedTokenPath: firstRemoved.path,
          suggestedTokenPath: firstAdded.path,
          confidence: 0.85,
          matchFactors: .init(pathSimilarity: 0.9, nameSimilarity: 0.8, colorSimilarity: 0.85)
        )
      ]
    }
  )
}

extension DependencyValues {
  var suggestionClient: SuggestionClient {
    get { self[SuggestionClient.self] }
    set { self[SuggestionClient.self] = newValue }
  }
}
