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
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(color)
      .clipShape(RoundedRectangle(cornerRadius: 4))
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
    RoundedRectangle(cornerRadius: 4)
      .fill(color)
      .frame(width: size, height: size)
      .overlay(
        RoundedRectangle(cornerRadius: 4)
          .stroke(Color.secondary.opacity(0.3), lineWidth: 0.5)
      )
  }
}

// MARK: - Color Square With Popover

struct ColorSquareWithPopover: View {
  let value: TokenValue
  let label: String
  @State private var showPopover = false

  var body: some View {
    RoundedRectangle(cornerRadius: 4)
      .fill(Color(hex: value.hex))
      .frame(width: 24, height: 24)
      .overlay(
        Text(label)
          .font(.caption2)
          .fontWeight(.bold)
          .foregroundStyle(.white)
          .shadow(color: .black.opacity(0.8), radius: 1, x: 0, y: 0)
      )
      .onTapGesture {
        showPopover.toggle()
      }
      .popover(isPresented: $showPopover, arrowEdge: .top) {
        colorDetailPopover
      }
  }

  private var colorDetailPopover: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Détails de la couleur")
        .font(.headline)
        .fontWeight(.semibold)

      HStack(spacing: 12) {
        RoundedRectangle(cornerRadius: 6)
          .fill(Color(hex: value.hex))
          .frame(width: 50, height: 50)
          .overlay(
            RoundedRectangle(cornerRadius: 6)
              .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
          )

        VStack(alignment: .leading, spacing: 6) {
          VStack(alignment: .leading, spacing: 2) {
            Text("Hex")
              .font(.caption)
              .fontWeight(.medium)
              .foregroundStyle(.secondary)

            Text(value.hex)
              .font(.body)
              .fontWeight(.medium)
              .textSelection(.enabled)
          }

          VStack(alignment: .leading, spacing: 2) {
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
    .frame(width: 320)
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
    HStack(spacing: 8) {
      // Legacy colors
      if let legacy = modes.legacy {
        VStack(spacing: 4) {
          if shouldShowLabels {
            Text("Legacy")
              .font(.caption2)
              .foregroundStyle(.secondary)
          }

          HStack(spacing: 3) {
            if let light = legacy.light {
              ColorSquareWithPopover(value: light, label: "L")
            }
            if let dark = legacy.dark {
              ColorSquareWithPopover(value: dark, label: "D")
            }
          }
        }
        .frame(minWidth: 64)
      }

      // New Brand colors
      if let newBrand = modes.newBrand {
        VStack(spacing: 4) {
          if shouldShowLabels {
            Text("New Brand")
              .font(.caption2)
              .foregroundStyle(.secondary)
          }

          HStack(spacing: 3) {
            if let light = newBrand.light {
              ColorSquareWithPopover(value: light, label: "L")
            }
            if let dark = newBrand.dark {
              ColorSquareWithPopover(value: dark, label: "D")
            }
          }
        }
        .frame(minWidth: 64)
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
        RoundedRectangle(cornerRadius: 8)
          .fill(Color(nsColor: .controlBackgroundColor))
      )
  }
}

// MARK: - Token Info Header

struct TokenInfoHeader: View {
  let name: String
  let path: String

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(name)
        .font(.subheadline)
        .fontWeight(.medium)

      Text(path)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }
}

