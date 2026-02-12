import SwiftUI

/// Composant de base pour les lignes d'historique avec hover et press effects
struct HistoryRow<Content: View, Icon: View>: View {
  let icon: () -> Icon
  let content: () -> Content
  let onTap: () -> Void
  let onRemove: () -> Void
  
  @State private var isHovering = false
  @State private var isPressed = false
  
  init(
    @ViewBuilder icon: @escaping () -> Icon,
    @ViewBuilder content: @escaping () -> Content,
    onTap: @escaping () -> Void,
    onRemove: @escaping () -> Void
  ) {
    self.icon = icon
    self.content = content
    self.onTap = onTap
    self.onRemove = onRemove
  }
  
  var body: some View {
    HStack(spacing: UIConstants.Spacing.extraLarge) {
      icon()
        .scaleEffect(isHovering ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovering)
      
      content()
      
      Spacer()
      
      removeButton
    }
    .padding(.horizontal, UIConstants.Spacing.extraLarge)
    .padding(.vertical, UIConstants.Spacing.medium)
    .background(
      RoundedRectangle(cornerRadius: UIConstants.CornerRadius.large)
        .fill(isHovering ? Color.accentColor.opacity(0.1) : Color.clear)
    )
    .scaleEffect(isPressed ? 0.98 : 1.0)
    .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
    .animation(.easeOut(duration: 0.15), value: isHovering)
    .contentShape(Rectangle())
    .onTapGesture { handleTap() }
    .onHover { isHovering = $0 }
  }
  
  @ViewBuilder
  private var removeButton: some View {
    Button {
      onRemove()
    } label: {
      Image(systemName: "xmark.circle.fill")
        .foregroundStyle(.secondary)
        .opacity(isHovering ? 1 : 0)
        .scaleEffect(isHovering ? 1 : 0.5)
    }
    .buttonStyle(.plain)
    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovering)
  }
  
  private func handleTap() {
    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
      isPressed = true
    }
    Task {
      try? await Task.sleep(for: .milliseconds(100))
      withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
        isPressed = false
      }
      onTap()
    }
  }
}

/// Container pour une section d'historique avec header et liste
struct HistorySection<Content: View>: View {
  let title: String
  let icon: String
  let isEmpty: Bool
  let emptyMessage: String
  let maxHeight: CGFloat
  let onClear: () -> Void
  @ViewBuilder let content: () -> Content
  
  var body: some View {
    VStack(alignment: .leading, spacing: UIConstants.Spacing.large) {
      header
      
      if isEmpty {
        emptyState
      } else {
        ScrollView {
          content()
        }
        .frame(maxHeight: maxHeight)
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: UIConstants.CornerRadius.xxLarge)
        .fill(Color(nsColor: .controlBackgroundColor))
    )
    .animation(.easeInOut(duration: 0.25), value: isEmpty)
  }
  
  @ViewBuilder
  private var header: some View {
    HStack {
      Label(title, systemImage: icon)
        .font(.headline)
        .foregroundStyle(.secondary)
      
      Spacer()
      
      if !isEmpty {
        Button("Effacer") {
          withAnimation(.easeOut(duration: AnimationDuration.normal)) {
            onClear()
          }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .buttonStyle(.plain)
      }
    }
  }
  
  @ViewBuilder
  private var emptyState: some View {
    Text(emptyMessage)
      .font(.caption)
      .foregroundStyle(.tertiary)
      .frame(maxWidth: .infinity, alignment: .center)
      .padding(.vertical, UIConstants.Spacing.medium)
      .transition(.opacity.combined(with: .scale(scale: 0.95)))
  }
}

#if DEBUG
#Preview("HistoryRow") {
  VStack(spacing: UIConstants.Spacing.medium) {
    HistoryRow {
      Image(systemName: "doc.fill")
        .font(.title3)
        .foregroundStyle(.purple)
    } content: {
      VStack(alignment: .leading, spacing: UIConstants.Spacing.extraSmall) {
        Text("aperture-tokens.json")
          .font(.subheadline)
          .fontWeight(.medium)
        Text("Importé le 6 fév. 2026")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    } onTap: {
      print("Tapped")
    } onRemove: {
      print("Remove")
    }
    
    HistoryRow {
      Image(systemName: "doc.text.magnifyingglass")
        .font(.title3)
        .foregroundStyle(.blue)
    } content: {
      VStack(alignment: .leading, spacing: UIConstants.Spacing.extraSmall) {
        Text("v1.0 → v2.0")
          .font(.subheadline)
          .fontWeight(.medium)
        Text("+12 -5 ~8")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    } onTap: {
      print("Tapped")
    } onRemove: {
      print("Remove")
    }
  }
  .padding()
  .frame(width: UIConstants.Size.previewWidth)
}
#endif
