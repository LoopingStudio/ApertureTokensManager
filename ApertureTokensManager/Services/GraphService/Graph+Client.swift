import ComposableArchitecture
import Foundation

struct GraphClient {
  var buildGraph: @Sendable ([TokenNode], String, String, Bool) async -> TokenGraph
}

extension DependencyValues {
  var graphClient: GraphClient {
    get { self[GraphClient.self] }
    set { self[GraphClient.self] = newValue }
  }
}

extension GraphClient: DependencyKey {
  static let liveValue: Self = {
    let service = GraphService()
    return .init(
      buildGraph: { tokens, brand, appearance, hideUtility in
        await service.buildGraph(tokens: tokens, brand: brand, appearance: appearance, hideUtility: hideUtility)
      }
    )
  }()

  static let testValue: Self = .init(
    buildGraph: { _, _, _, _ in
      TokenGraph(nodes: [], edges: [], layerGroups: [:], unresolvedCount: 0)
    }
  )

  static let previewValue: Self = testValue
}
