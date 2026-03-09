import ComposableArchitecture
import SwiftUI

@ViewAction(for: GraphFeature.self)
struct GraphView: View {
  @Bindable var store: StoreOf<GraphFeature>
  @State private var nodeFrames: [UUID: CGRect] = [:]

  var body: some View {
    VStack(spacing: 0) {
      if store.designSystemBase != nil {
        // Toolbar
        GraphToolbarView(
          selectedBrand: store.selectedBrand,
          selectedAppearance: store.selectedAppearance,
          searchText: store.searchText,
          zoomScale: store.zoomScale,
          nodeCount: store.graph?.nodes.count ?? 0,
          edgeCount: store.graph?.edges.count ?? 0,
          onBrandSelected: { send(.brandSelected($0)) },
          onAppearanceSelected: { send(.appearanceSelected($0)) },
          hideUtility: store.hideUtility,
          onSearchTextChanged: { send(.searchTextChanged($0)) },
          onZoomChanged: { send(.zoomChanged($0)) },
          onHideUtilityToggled: { send(.hideUtilityToggled) }
        )

        Divider()

        // Graph content
        ZStack(alignment: .bottom) {
          if store.isBuilding {
            ProgressView("Construction du graphe...")
              .frame(maxWidth: .infinity, maxHeight: .infinity)
          } else if let graph = store.graph, !graph.nodes.isEmpty {
            graphContent(graph: graph)
          } else {
            emptyGraphState
          }

          // Selection bar overlay
          if let selectedId = store.selectedNodeId,
             let graph = store.graph,
             let node = graph.nodes.first(where: { $0.id == selectedId }) {
            selectionBar(node: node, graph: graph)
              .padding(.horizontal, UIConstants.Spacing.extraLarge)
              .padding(.bottom, UIConstants.Spacing.large)
          }
        }
      } else {
        emptyState
      }
    }
    .onAppear {
      send(.onAppear)
    }
  }

  // MARK: - Graph Content

  private func graphContent(graph: TokenGraph) -> some View {
    ScrollView([.horizontal, .vertical]) {
      ZStack(alignment: .topLeading) {
        // Bezier edges layer (Canvas)
        GraphCanvasView(
          edges: graph.edges,
          nodeFrames: nodeFrames,
          highlightedEdgeIds: store.highlightedEdgeIds,
          isDimming: store.matchingNodeIds != nil || store.activeNodeId != nil,
          visibleNodeIds: store.isolatedNodeIds
        )
        .frame(width: canvasWidth, height: canvasHeight(graph: graph))
        .allowsHitTesting(false)

        // Node cards layer
        HStack(alignment: .top, spacing: GraphConstants.columnSpacing) {
          ForEach(TokenLayer.allCases, id: \.self) { layer in
            if let groups = graph.layerGroups[layer], !groups.isEmpty {
              GraphColumnView(
                layer: layer,
                groups: groups,
                highlightedNodeIds: store.highlightedNodeIds,
                matchingNodeIds: store.matchingNodeIds,
                isolatedNodeIds: store.isolatedNodeIds,
                selectedNodeId: store.selectedNodeId,
                onNodeHover: { id in
                  send(.nodeHovered(id))
                },
                onNodeTap: { id in
                  send(.nodeSelected(store.selectedNodeId == id ? nil : id))
                }
              )
            }
          }
        }
        .padding(GraphConstants.canvasPadding)
        .animation(.easeInOut(duration: 0.3), value: store.isIsolating)
      }
      .coordinateSpace(name: "graphCanvas")
      .onPreferenceChange(NodeFramesPreferenceKey.self) { frames in
        nodeFrames = frames
      }
      .scaleEffect(store.zoomScale, anchor: .topLeading)
      .frame(
        width: canvasWidth * store.zoomScale,
        height: canvasHeight(graph: graph) * store.zoomScale,
        alignment: .topLeading
      )
    }
    .background(Color(nsColor: .windowBackgroundColor))
    .gesture(
      MagnificationGesture()
        .onChanged { value in
          send(.zoomChanged(store.zoomScale * value))
        }
    )
  }

  // MARK: - Selection Bar

  private func selectionBar(node: GraphNode, graph: TokenGraph) -> some View {
    let counts = store.selectedDescendantCounts

    return HStack(spacing: UIConstants.Spacing.medium) {
      // Build the path chain: ancestors → selected → descendants
      let chain = buildChain(for: node.id, in: graph)

      ForEach(Array(chain.enumerated()), id: \.element.id) { index, chainNode in
        if index > 0 {
          Image(systemName: "arrow.right")
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }

        HStack(spacing: UIConstants.Spacing.small) {
          if let hex = chainNode.hex {
            ColorSquarePreview(color: Color(hex: hex), size: 10)
          }
          Text(chainNode.path)
            .font(.caption)
            .fontWeight(chainNode.id == node.id ? .semibold : .regular)
            .foregroundStyle(chainNode.id == node.id ? .primary : .secondary)
        }
        .padding(.horizontal, UIConstants.Spacing.medium)
        .padding(.vertical, UIConstants.Spacing.extraSmall)
        .background(
          RoundedRectangle(cornerRadius: UIConstants.CornerRadius.small)
            .fill(chainNode.id == node.id ? Color.accentColor.opacity(0.12) : Color.clear)
        )
        .onTapGesture {
          send(.nodeSelected(chainNode.id))
        }
      }

      // Descendant counts per layer
      if !counts.isEmpty {
        Divider()
          .frame(height: 16)

        ForEach(TokenLayer.allCases, id: \.self) { layer in
          if let count = counts[layer], count > 0 {
            Text("\(count) \(layer.displayName)")
              .font(.caption)
              .foregroundStyle(.secondary)
              .padding(.horizontal, UIConstants.Spacing.small)
              .padding(.vertical, UIConstants.Spacing.extraSmall)
              .background(
                RoundedRectangle(cornerRadius: UIConstants.CornerRadius.small)
                  .fill(Color.secondary.opacity(0.08))
              )
          }
        }
      }

      Spacer()

      // Isolate toggle
      if counts.values.reduce(0, +) > 1 {
        Button {
          send(.isolateToggled)
        } label: {
          HStack(spacing: UIConstants.Spacing.extraSmall) {
            Image(systemName: store.isIsolating ? "eye.slash" : "eye")
            Text(store.isIsolating ? "Tout afficher" : "Isoler")
          }
          .font(.caption)
        }
        .buttonStyle(.borderless)
      }

      Button {
        send(.nodeSelected(nil))
      } label: {
        Image(systemName: "xmark.circle.fill")
          .foregroundStyle(.secondary)
      }
      .buttonStyle(.borderless)
    }
    .padding(.horizontal, UIConstants.Spacing.extraLarge)
    .padding(.vertical, UIConstants.Spacing.medium)
    .background(
      RoundedRectangle(cornerRadius: UIConstants.CornerRadius.extraLarge)
        .fill(.ultraThinMaterial)
        .shadow(color: .black.opacity(0.2), radius: 8, y: 2)
    )
  }

  /// Build ordered chain: ancestors → node → descendants
  private func buildChain(for nodeId: UUID, in graph: TokenGraph) -> [GraphNode] {
    let nodeMap = Dictionary(uniqueKeysWithValues: graph.nodes.map { ($0.id, $0) })

    // Walk ancestors
    var ancestors: [GraphNode] = []
    var current = nodeId
    var visited: Set<UUID> = [nodeId]
    while let edge = graph.edges.first(where: { $0.targetId == current }),
          let source = nodeMap[edge.sourceId],
          visited.insert(source.id).inserted {
      ancestors.append(source)
      current = source.id
    }

    // Walk descendants
    var descendants: [GraphNode] = []
    current = nodeId
    visited = [nodeId]
    while let edge = graph.edges.first(where: { $0.sourceId == current }),
          let target = nodeMap[edge.targetId],
          visited.insert(target.id).inserted {
      descendants.append(target)
      current = target.id
    }

    // Chain: ancestors (reversed, from root) → selected node → descendants
    var chain = ancestors.reversed() as [GraphNode]
    if let node = nodeMap[nodeId] {
      chain.append(node)
    }
    chain.append(contentsOf: descendants)
    return chain
  }

  // MARK: - Empty States

  private var emptyState: some View {
    VStack(spacing: UIConstants.Spacing.extraLarge) {
      Spacer()
      Image(systemName: "point.3.connected.trianglepath.dotted")
        .font(.system(size: UIConstants.Size.emptyStateIconSize * 0.6))
        .foregroundStyle(.quaternary)
      Text("Aucune base chargee")
        .font(.title2)
        .foregroundStyle(.secondary)
      Text("Importez un fichier de tokens pour visualiser le graphe de dependances.")
        .font(.body)
        .foregroundStyle(.tertiary)
        .multilineTextAlignment(.center)
        .frame(maxWidth: 400)
      Spacer()
    }
    .frame(maxWidth: .infinity)
  }

  private var emptyGraphState: some View {
    VStack(spacing: UIConstants.Spacing.extraLarge) {
      Spacer()
      Image(systemName: "point.3.connected.trianglepath.dotted")
        .font(.system(size: UIConstants.Size.emptyStateIconSize * 0.6))
        .foregroundStyle(.quaternary)
      Text("Graphe vide")
        .font(.title2)
        .foregroundStyle(.secondary)
      Text("Aucun token trouve dans la base actuelle.")
        .font(.body)
        .foregroundStyle(.tertiary)
      Spacer()
    }
    .frame(maxWidth: .infinity)
  }

  // MARK: - Layout

  private var canvasWidth: CGFloat {
    CGFloat(TokenLayer.allCases.count) * (GraphConstants.columnWidth + GraphConstants.columnSpacing) + GraphConstants.canvasPadding * 2
  }

  private func canvasHeight(graph: TokenGraph) -> CGFloat {
    let maxNodesInColumn = graph.layerGroups.values.map { groups in
      groups.values.reduce(0) { $0 + $1.count }
    }.max() ?? 0
    return CGFloat(maxNodesInColumn) * (GraphConstants.cardHeight + GraphConstants.cardSpacing) + GraphConstants.canvasPadding * 2 + 100
  }
}

// MARK: - Node Frames Preference Key

struct NodeFramesPreferenceKey: PreferenceKey {
  static let defaultValue: [UUID: CGRect] = [:]
  static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
    value.merge(nextValue()) { _, new in new }
  }
}

// MARK: - Node Position Modifier

struct NodePositionModifier: ViewModifier {
  let nodeId: UUID

  func body(content: Content) -> some View {
    content
      .background(
        GeometryReader { geometry in
          Color.clear.preference(
            key: NodeFramesPreferenceKey.self,
            value: [nodeId: geometry.frame(in: .named("graphCanvas"))]
          )
        }
      )
  }
}

extension View {
  func trackNodePosition(id: UUID) -> some View {
    modifier(NodePositionModifier(nodeId: id))
  }
}

#if DEBUG
#Preview {
  GraphView(
    store: Store(initialState: GraphFeature.State.initial) {
      GraphFeature()
    }
  )
}
#endif
