import SwiftUI

struct GraphNodeCardView: View {
  let node: GraphNode
  let isHighlighted: Bool
  let isDimmed: Bool
  let isSelected: Bool
  let onHover: (Bool) -> Void
  let onTap: () -> Void

  @State private var showColorPopover = false
  @State private var isColorHovering = false

  var body: some View {
    HStack(spacing: UIConstants.Spacing.medium) {
      if let hex = node.hex {
        RoundedRectangle(cornerRadius: UIConstants.CornerRadius.small)
          .fill(Color(hex: hex))
          .frame(width: UIConstants.Size.treeColorDotSize, height: UIConstants.Size.treeColorDotSize)
          .overlay(
            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.small)
              .stroke(Color.primary.opacity(isColorHovering ? 0.4 : 0), lineWidth: 1)
          )
          .scaleEffect(isColorHovering ? 1.15 : 1.0)
          .animation(.easeOut(duration: 0.15), value: isColorHovering)
          .onHover { isColorHovering = $0 }
          .onTapGesture { showColorPopover.toggle() }
          .popover(isPresented: $showColorPopover, arrowEdge: .top) {
            colorDetailPopover(hex: hex)
          }
      }
      Text(node.name)
        .font(.caption)
        .lineLimit(1)
        .truncationMode(.middle)
    }
    .padding(.horizontal, UIConstants.Spacing.medium)
    .padding(.vertical, UIConstants.Spacing.small)
    .background(
      RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium)
        .fill(backgroundColor)
    )
    .overlay(
      RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium)
        .stroke(borderColor, lineWidth: isSelected ? 2 : (isHighlighted ? 1.5 : 0.5))
    )
    .opacity(isDimmed ? 0.3 : 1.0)
    .scaleEffect(isHighlighted && !isDimmed ? 1.05 : 1.0)
    .animation(.easeOut(duration: AnimationDuration.quick), value: isHighlighted)
    .animation(.easeOut(duration: AnimationDuration.normal), value: isDimmed)
    .onHover { hovering in
      onHover(hovering)
    }
    .onTapGesture {
      onTap()
    }
    .trackNodePosition(id: node.id)
  }

  private var backgroundColor: Color {
    if isSelected {
      return Color.accentColor.opacity(0.15)
    }
    if isHighlighted {
      return Color.accentColor.opacity(0.08)
    }
    return Color(nsColor: .controlBackgroundColor)
  }

  private func colorDetailPopover(hex: String) -> some View {
    VStack(alignment: .leading, spacing: UIConstants.Spacing.large) {
      Text("Détails de la couleur")
        .font(.headline)
        .fontWeight(.semibold)

      HStack(spacing: UIConstants.Spacing.large) {
        RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium)
          .fill(Color(hex: hex))
          .frame(width: UIConstants.Size.colorSquareMedium, height: UIConstants.Size.colorSquareMedium)
          .overlay(
            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium)
              .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
          )

        VStack(alignment: .leading, spacing: UIConstants.Spacing.medium) {
          VStack(alignment: .leading, spacing: UIConstants.Spacing.extraSmall) {
            Text("Hex")
              .font(.caption)
              .fontWeight(.medium)
              .foregroundStyle(.secondary)

            Text(hex)
              .font(.body)
              .fontWeight(.medium)
              .textSelection(.enabled)
          }

          if let primitiveName = node.primitiveName {
            VStack(alignment: .leading, spacing: UIConstants.Spacing.extraSmall) {
              Text("Primitive")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

              Text(primitiveName)
                .font(.caption)
                .fontWeight(.medium)
                .textSelection(.enabled)
            }
          }
        }
        Spacer()
      }
    }
    .padding()
    .frame(width: UIConstants.Size.popoverWidth)
  }

  private var borderColor: Color {
    if isSelected {
      return Color.accentColor
    }
    if isHighlighted {
      return Color.accentColor.opacity(0.6)
    }
    return Color.secondary.opacity(0.3)
  }
}
