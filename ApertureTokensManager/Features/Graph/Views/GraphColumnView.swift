import SwiftUI

struct GraphColumnView: View {
  let layer: TokenLayer
  let groups: [String: [GraphNode]]
  let highlightedNodeIds: Set<UUID>
  let matchingNodeIds: Set<UUID>?
  let isolatedNodeIds: Set<UUID>?
  let selectedNodeId: UUID?
  let onNodeHover: (UUID?) -> Void
  let onNodeTap: (UUID) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: UIConstants.Spacing.extraLarge) {
      // Column header
      Text(layer.displayName)
        .font(.headline)
        .foregroundStyle(.secondary)
        .padding(.horizontal, UIConstants.Spacing.medium)

      // Groups
      ForEach(sortedGroupNames, id: \.self) { groupName in
        let nodesInGroup = filteredGroupNodes(groupName)
        if !nodesInGroup.isEmpty {
          VStack(alignment: .leading, spacing: UIConstants.Spacing.small) {
            Text(groupName)
              .font(.caption2)
              .foregroundStyle(.tertiary)
              .textCase(.uppercase)
              .padding(.horizontal, UIConstants.Spacing.medium)

            VStack(alignment: .leading, spacing: UIConstants.Spacing.small) {
              ForEach(nodesInGroup) { node in
                GraphNodeCardView(
                  node: node,
                  isHighlighted: highlightedNodeIds.contains(node.id),
                  isDimmed: isDimmed(node),
                  isSelected: selectedNodeId == node.id,
                  onHover: { hovering in
                    onNodeHover(hovering ? node.id : nil)
                  },
                  onTap: {
                    onNodeTap(node.id)
                  }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.85, anchor: .leading)))
              }
            }
          }
        }
      }
    }
    .frame(width: GraphConstants.columnWidth)
  }

  private var sortedGroupNames: [String] {
    groups.keys.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
  }

  private func filteredGroupNodes(_ groupName: String) -> [GraphNode] {
    let sorted = (groups[groupName] ?? [])
      .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    guard let isolated = isolatedNodeIds else { return sorted }
    return sorted.filter { isolated.contains($0.id) }
  }

  private func isDimmed(_ node: GraphNode) -> Bool {
    guard let matching = matchingNodeIds else { return false }
    return !matching.contains(node.id)
  }
}
