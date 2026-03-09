import ComposableArchitecture
import CoreGraphics
import Foundation
import Sharing

@Reducer
struct GraphFeature: Sendable {
  @Dependency(\.graphClient) var graphClient
  @Dependency(\.loggingClient) var loggingClient

  // MARK: - State

  @ObservableState
  struct State: Equatable {
    @Shared(.designSystemBase) var designSystemBase: DesignSystemBase?
    var graph: TokenGraph?
    var isBuilding: Bool = false

    // Display
    var selectedBrand: String = Brand.legacy
    var selectedAppearance: String = ThemeType.light
    var searchText: String = ""
    var hideUtility: Bool = true

    // Interaction
    var zoomScale: CGFloat = 1.0
    var scrollOffset: CGPoint = .zero
    var hoveredNodeId: UUID?
    var selectedNodeId: UUID?
    var isIsolating: Bool = false

    // The active node for highlighting: hover takes priority, then selection
    var activeNodeId: UUID? {
      hoveredNodeId ?? selectedNodeId
    }

    // Full connected subgraph from a given node (ancestors + descendants)
    func connectedIds(from nodeId: UUID) -> Set<UUID> {
      guard let graph else { return [nodeId] }
      var ids: Set<UUID> = [nodeId]
      // Walk ancestors
      var queue = [nodeId]
      while !queue.isEmpty {
        let current = queue.removeFirst()
        for edge in graph.edges where edge.targetId == current {
          if ids.insert(edge.sourceId).inserted { queue.append(edge.sourceId) }
        }
      }
      // Walk descendants
      queue = [nodeId]
      var visited: Set<UUID> = [nodeId]
      while !queue.isEmpty {
        let current = queue.removeFirst()
        for edge in graph.edges where edge.sourceId == current {
          if visited.insert(edge.targetId).inserted {
            ids.insert(edge.targetId)
            queue.append(edge.targetId)
          }
        }
      }
      return ids
    }

    var highlightedNodeIds: Set<UUID> {
      guard let activeId = activeNodeId else { return [] }
      return connectedIds(from: activeId)
    }

    var highlightedEdgeIds: Set<UUID> {
      guard let graph, !highlightedNodeIds.isEmpty else { return [] }
      var ids: Set<UUID> = []
      for edge in graph.edges {
        if highlightedNodeIds.contains(edge.sourceId) && highlightedNodeIds.contains(edge.targetId) {
          ids.insert(edge.id)
        }
      }
      return ids
    }

    // Count of connected descendants per layer for the selected node
    var selectedDescendantCounts: [TokenLayer: Int] {
      guard let selectedId = selectedNodeId, let graph else { return [:] }
      let connected = connectedIds(from: selectedId)
      var counts: [TokenLayer: Int] = [:]
      for node in graph.nodes where connected.contains(node.id) && node.id != selectedId {
        counts[node.layer, default: 0] += 1
      }
      return counts
    }

    var filteredNodes: [GraphNode] {
      guard let graph else { return [] }
      guard !searchText.isEmpty else { return graph.nodes }
      let query = searchText.lowercased()
      return graph.nodes.filter {
        $0.name.lowercased().contains(query) || $0.path.lowercased().contains(query)
      }
    }

    var matchingNodeIds: Set<UUID>? {
      guard !searchText.isEmpty else { return nil }
      return Set(filteredNodes.map(\.id))
    }

    // When isolating, only show connected nodes
    var isolatedNodeIds: Set<UUID>? {
      guard isIsolating, let selectedId = selectedNodeId else { return nil }
      return connectedIds(from: selectedId)
    }

    static var initial: Self { .init() }
  }

  // MARK: - Action

  @CasePathable
  enum Action: BindableAction, ViewAction, Equatable, Sendable {
    case analytics(Analytics)
    case binding(BindingAction<State>)
    case `internal`(Internal)
    case view(View)

    @CasePathable
    enum Analytics: Equatable, Sendable {
      case graphBuilt(nodeCount: Int, edgeCount: Int, unresolvedCount: Int)
      case brandChanged(brand: String)
      case appearanceChanged(appearance: String)
      case searchPerformed(query: String)
      case nodeSelected(path: String)
      case zoomChanged(scale: Double)
    }

    @CasePathable
    enum Internal: Equatable, Sendable {
      case graphLoaded(TokenGraph)
    }

    @CasePathable
    enum View: Equatable, Sendable {
      case onAppear
      case brandSelected(String)
      case appearanceSelected(String)
      case searchTextChanged(String)
      case zoomChanged(CGFloat)
      case nodeHovered(UUID?)
      case nodeSelected(UUID?)
      case hideUtilityToggled
      case isolateToggled
      case rebuildGraphTapped
    }
  }

  // MARK: - Body

  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .analytics(let action): handleAnalyticsAction(action, state: &state)
      case .binding: .none
      case .internal(let action): handleInternalAction(action, state: &state)
      case .view(let action): handleViewAction(action, state: &state)
      }
    }
  }

  // MARK: - Build Graph Effect

  func buildGraphEffect(state: State) -> EffectOf<Self> {
    guard let base = state.designSystemBase else { return .none }
    let brand = state.selectedBrand
    let appearance = state.selectedAppearance
    let hideUtility = state.hideUtility
    return .run { send in
      let graph = await graphClient.buildGraph(base.tokens, brand, appearance, hideUtility)
      await send(.internal(.graphLoaded(graph)))
    }
  }
}
