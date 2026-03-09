import ComposableArchitecture
import Foundation

extension GraphFeature {
  func handleInternalAction(_ action: Action.Internal, state: inout State) -> EffectOf<Self> {
    switch action {
    case .graphLoaded(let graph):
      state.graph = graph
      state.isBuilding = false
      return .send(.analytics(.graphBuilt(
        nodeCount: graph.nodes.count,
        edgeCount: graph.edges.count,
        unresolvedCount: graph.unresolvedCount
      )))
    }
  }
}
