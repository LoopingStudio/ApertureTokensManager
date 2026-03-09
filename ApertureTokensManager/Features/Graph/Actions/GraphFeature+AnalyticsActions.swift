import ComposableArchitecture
import Foundation

extension GraphFeature {
  func handleAnalyticsAction(_ action: Action.Analytics, state: inout State) -> EffectOf<Self> {
    switch action {
    case .graphBuilt(let nodeCount, let edgeCount, let unresolvedCount):
      loggingClient.logSystemEvent(
        LogFeature.graph,
        "graph_built",
        [
          "node_count": "\(nodeCount)",
          "edge_count": "\(edgeCount)",
          "unresolved_count": "\(unresolvedCount)",
        ]
      )
      return .none

    case .brandChanged(let brand):
      loggingClient.logUserAction(
        LogFeature.graph,
        "brand_changed",
        ["brand": brand]
      )
      return .none

    case .appearanceChanged(let appearance):
      loggingClient.logUserAction(
        LogFeature.graph,
        "appearance_changed",
        ["appearance": appearance]
      )
      return .none

    case .searchPerformed(let query):
      loggingClient.logUserAction(
        LogFeature.graph,
        "search_performed",
        ["query": query]
      )
      return .none

    case .nodeSelected(let path):
      loggingClient.logUserAction(
        LogFeature.graph,
        "node_selected",
        ["path": path]
      )
      return .none

    case .zoomChanged(let scale):
      loggingClient.logUserAction(
        LogFeature.graph,
        "zoom_changed",
        ["scale": String(format: "%.2f", scale)]
      )
      return .none
    }
  }
}
