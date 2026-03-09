import SwiftUI

struct GraphCanvasView: View {
  let edges: [GraphEdge]
  let nodeFrames: [UUID: CGRect]
  let highlightedEdgeIds: Set<UUID>
  let isDimming: Bool
  var visibleNodeIds: Set<UUID>?

  var body: some View {
    Canvas { context, _ in
      for edge in edges {
        // Skip edges not in isolated subset
        if let visible = visibleNodeIds,
           !visible.contains(edge.sourceId) || !visible.contains(edge.targetId) {
          continue
        }
        guard
          let sourceFrame = nodeFrames[edge.sourceId],
          let targetFrame = nodeFrames[edge.targetId]
        else { continue }

        // Attach to right edge of source, left edge of target
        let sourcePoint = CGPoint(x: sourceFrame.maxX, y: sourceFrame.midY)
        let targetPoint = CGPoint(x: targetFrame.minX, y: targetFrame.midY)

        let isHighlighted = highlightedEdgeIds.contains(edge.id)
        let opacity: Double = isDimming && !isHighlighted ? 0.08 : (isHighlighted ? 0.8 : 0.2)

        var path = Path()
        let controlOffset = (targetPoint.x - sourcePoint.x) * 0.4
        path.move(to: sourcePoint)
        path.addCurve(
          to: targetPoint,
          control1: CGPoint(x: sourcePoint.x + controlOffset, y: sourcePoint.y),
          control2: CGPoint(x: targetPoint.x - controlOffset, y: targetPoint.y)
        )

        context.opacity = opacity
        context.stroke(
          path,
          with: .color(isHighlighted ? .accentColor : .secondary),
          lineWidth: isHighlighted ? 2 : 1
        )
      }
    }
  }
}
