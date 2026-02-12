import SwiftUI

/// Card de statistique réutilisable avec icône, valeur, titre et sous-titre
struct StatCard: View {
  let title: String
  let value: String
  let subtitle: String
  let color: Color
  let icon: String
  var action: (() -> Void)? = nil
  
  private var isInteractive: Bool { action != nil }
  
  var body: some View {
    if isInteractive {
      InteractiveStatCard(
        title: title,
        value: value,
        subtitle: subtitle,
        color: color,
        icon: icon,
        action: action!
      )
    } else {
      StaticStatCard(
        title: title,
        value: value,
        subtitle: subtitle,
        color: color,
        icon: icon
      )
    }
  }
}

// MARK: - Static Card (non-interactive)

private struct StaticStatCard: View {
  let title: String
  let value: String
  let subtitle: String
  let color: Color
  let icon: String
  
  var body: some View {
    VStack(alignment: .leading, spacing: UIConstants.Spacing.medium) {
      HStack {
        Image(systemName: icon)
          .foregroundStyle(color)
        Spacer()
      }
      
      Text(value)
        .font(.system(size: 32, weight: .bold, design: .rounded))
        .contentTransition(.numericText())
      
      Text(title)
        .font(.headline)
      
      Text(subtitle)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(color.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: UIConstants.CornerRadius.xxLarge))
  }
}

// MARK: - Interactive Card (with hover and press effects)

private struct InteractiveStatCard: View {
  let title: String
  let value: String
  let subtitle: String
  let color: Color
  let icon: String
  let action: () -> Void
  
  @State private var isHovering = false
  @State private var isPressed = false
  @State private var iconBounce = false
  
  var body: some View {
    Button(action: handleTap) {
      VStack(alignment: .leading, spacing: UIConstants.Spacing.medium) {
        HStack {
          Image(systemName: icon)
            .foregroundStyle(color)
            .scaleEffect(iconBounce ? 1.15 : 1.0)
            .rotationEffect(.degrees(iconBounce ? -5 : 0))
          
          Spacer()
          
          // Indicateur subtil de cliquabilité
          Image(systemName: "chevron.right")
            .font(.caption2)
            .foregroundStyle(color.opacity(isHovering ? 0.8 : 0.4))
            .offset(x: isHovering ? 2 : 0)
        }
        
        Text(value)
          .font(.system(size: 32, weight: .bold, design: .rounded))
          .contentTransition(.numericText())
        
        Text(title)
          .font(.headline)
        
        Text(subtitle)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .padding()
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        RoundedRectangle(cornerRadius: UIConstants.CornerRadius.xxLarge)
          .fill(color.opacity(isHovering ? 0.15 : 0.1))
          .overlay(
            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.xxLarge)
              .stroke(color.opacity(isHovering ? 0.4 : 0.15), lineWidth: 1)
          )
      )
      .scaleEffect(isPressed ? 0.97 : (isHovering ? 1.02 : 1.0))
    }
    .buttonStyle(.plain)
    .animation(.easeOut(duration: AnimationDuration.normal), value: isHovering)
    .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
    .onHover { hovering in handleHover(hovering) }
    .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
      isPressed = pressing
    }, perform: {})
  }
  
  private func handleTap() {
    action()
  }
  
  private func handleHover(_ hovering: Bool) {
    isHovering = hovering
    guard hovering else { return }
    bounceIcon()
  }
  
  private func bounceIcon() {
    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
      iconBounce = true
    }
    Task {
      try? await Task.sleep(for: .milliseconds(150))
      withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
        iconBounce = false
      }
    }
  }
}

/// Version compacte de StatCard pour les espaces réduits
struct CompactStatCard: View {
  let title: String
  let value: String
  let color: Color
  let icon: String
  var action: (() -> Void)? = nil
  
  var body: some View {
    Button {
      action?()
    } label: {
      HStack(spacing: UIConstants.Spacing.large) {
        Image(systemName: icon)
          .font(.title2)
          .foregroundStyle(color)
          .frame(width: UIConstants.Size.iconSmall)
        
        VStack(alignment: .leading, spacing: UIConstants.Spacing.extraSmall) {
          Text(value)
            .font(.system(size: 20, weight: .bold, design: .rounded))
          
          Text(title)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        
        Spacer()
      }
      .padding(UIConstants.Spacing.large)
      .background(color.opacity(0.1))
      .clipShape(RoundedRectangle(cornerRadius: UIConstants.CornerRadius.extraLarge))
    }
    .buttonStyle(.plain)
    .disabled(action == nil)
  }
}

#if DEBUG
#Preview("StatCard") {
  HStack(spacing: UIConstants.Spacing.extraLarge) {
    StatCard(
      title: "Tokens Utilisés",
      value: "142",
      subtitle: "85% du total",
      color: .green,
      icon: "checkmark.circle.fill"
    )
    
    StatCard(
      title: "Tokens Orphelins",
      value: "28",
      subtitle: "15% du total",
      color: .orange,
      icon: "exclamationmark.triangle.fill"
    )
    
    StatCard(
      title: "Occurrences",
      value: "1,247",
      subtitle: "dans 42 fichiers",
      color: .blue,
      icon: "doc.text.fill"
    )
  }
  .padding()
  .frame(width: 800)
}

#Preview("CompactStatCard") {
  VStack(spacing: UIConstants.Spacing.medium) {
    CompactStatCard(
      title: "Ajoutés",
      value: "12",
      color: .green,
      icon: "plus.circle.fill"
    )
    
    CompactStatCard(
      title: "Supprimés",
      value: "5",
      color: .red,
      icon: "minus.circle.fill"
    )
    
    CompactStatCard(
      title: "Modifiés",
      value: "23",
      color: .orange,
      icon: "pencil.circle.fill"
    )
  }
  .padding()
  .frame(width: 300)
}
#endif
