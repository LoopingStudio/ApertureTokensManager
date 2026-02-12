import SwiftUI

// MARK: - Token Badge

struct TokenBadge: View {
  let text: String
  let color: Color

  var body: some View {
    Text(text)
      .font(.caption)
      .fontWeight(.semibold)
      .foregroundStyle(.white)
      .padding(.horizontal, UIConstants.Spacing.medium)
      .padding(.vertical, UIConstants.Spacing.small)
      .background(color)
      .clipShape(RoundedRectangle(cornerRadius: UIConstants.CornerRadius.small))
  }
}

// MARK: - Color Square Preview

struct ColorSquarePreview: View {
  let color: Color
  let size: CGFloat

  init(color: Color, size: CGFloat = 20) {
    self.color = color
    self.size = size
  }

  var body: some View {
    RoundedRectangle(cornerRadius: UIConstants.CornerRadius.small)
      .fill(color)
      .frame(width: size, height: size)
      .overlay(
        RoundedRectangle(cornerRadius: UIConstants.CornerRadius.small)
          .stroke(Color.secondary.opacity(0.3), lineWidth: 0.5)
      )
  }
}

// MARK: - Color Square With Popover

struct ColorSquareWithPopover: View {
  let value: TokenValue
  let label: String
  @State private var showPopover = false
  @State private var isHovering = false

  var body: some View {
    RoundedRectangle(cornerRadius: UIConstants.CornerRadius.small)
      .fill(Color(hex: value.hex))
      .frame(width: UIConstants.Size.colorSquareSmall, height: UIConstants.Size.colorSquareSmall)
      .overlay(
        RoundedRectangle(cornerRadius: UIConstants.CornerRadius.small)
          .stroke(Color.primary.opacity(isHovering ? 0.4 : 0), lineWidth: 1.5)
      )
      .overlay(
        Text(label)
          .font(.caption2)
          .fontWeight(.bold)
          .foregroundStyle(.white)
          .shadow(color: .black.opacity(0.8), radius: 1, x: 0, y: 0)
      )
      .scaleEffect(isHovering ? 1.15 : 1.0)
      .animation(.easeOut(duration: 0.15), value: isHovering)
      .onHover { isHovering = $0 }
      .onTapGesture {
        showPopover.toggle()
      }
      .popover(isPresented: $showPopover, arrowEdge: .top) {
        colorDetailPopover
      }
  }

  private var colorDetailPopover: some View {
    VStack(alignment: .leading, spacing: UIConstants.Spacing.large) {
      Text("Détails de la couleur")
        .font(.headline)
        .fontWeight(.semibold)

      HStack(spacing: UIConstants.Spacing.large) {
        RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium)
          .fill(Color(hex: value.hex))
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

            Text(value.hex)
              .font(.body)
              .fontWeight(.medium)
              .textSelection(.enabled)
          }

          VStack(alignment: .leading, spacing: UIConstants.Spacing.extraSmall) {
            Text("Primitive")
              .font(.caption)
              .fontWeight(.medium)
              .foregroundStyle(.secondary)

            Text(value.primitiveName)
              .font(.caption)
              .fontWeight(.medium)
              .textSelection(.enabled)
          }
        }
        Spacer()
      }
    }
    .padding()
    .frame(width: UIConstants.Size.popoverWidth)
  }
}

// MARK: - Compact Color Preview (4 colors grid)

struct CompactColorPreview: View {
  let modes: TokenThemes
  let shouldShowLabels: Bool

  init(modes: TokenThemes, shouldShowLabels: Bool = true) {
    self.modes = modes
    self.shouldShowLabels = shouldShowLabels
  }

  var body: some View {
    HStack(spacing: UIConstants.Spacing.medium) {
      // Legacy colors
      if let legacy = modes.legacy {
        VStack(spacing: UIConstants.Spacing.small) {
          if shouldShowLabels {
            Text("Legacy")
              .font(.caption2)
              .foregroundStyle(.secondary)
          }

          HStack(spacing: UIConstants.Spacing.extraSmall) {
            if let light = legacy.light {
              ColorSquareWithPopover(value: light, label: "L")
            }
            if let dark = legacy.dark {
              ColorSquareWithPopover(value: dark, label: "D")
            }
          }
        }
        .frame(minWidth: UIConstants.Size.colorSquareMedium)
      }

      // New Brand colors
      if let newBrand = modes.newBrand {
        VStack(spacing: UIConstants.Spacing.small) {
          if shouldShowLabels {
            Text("New Brand")
              .font(.caption2)
              .foregroundStyle(.secondary)
          }

          HStack(spacing: UIConstants.Spacing.extraSmall) {
            if let light = newBrand.light {
              ColorSquareWithPopover(value: light, label: "L")
            }
            if let dark = newBrand.dark {
              ColorSquareWithPopover(value: dark, label: "D")
            }
          }
        }
        .frame(minWidth: UIConstants.Size.colorSquareMedium)
      }
    }
  }
}

// MARK: - View Extension

extension View {
  func controlRoundedBackground() -> some View {
    self
      .padding()
      .background(
        RoundedRectangle(cornerRadius: UIConstants.CornerRadius.large)
          .fill(Color(nsColor: .controlBackgroundColor))
      )
  }
}

// MARK: - Token Info Header

struct TokenInfoHeader: View {
  let name: String
  let path: String
  var searchText: String = ""

  var body: some View {
    VStack(alignment: .leading, spacing: UIConstants.Spacing.small) {
      highlightedName
        .font(.subheadline)
        .fontWeight(.medium)

      highlightedPath
        .font(.caption)
    }
  }
  
  private var highlightedName: Text {
    TokenTreeSearchHelper.highlightedText(name, searchText: searchText, baseColor: .primary)
  }
  
  private var highlightedPath: Text {
    TokenTreeSearchHelper.highlightedText(path, searchText: searchText, baseColor: .secondary)
  }
}
