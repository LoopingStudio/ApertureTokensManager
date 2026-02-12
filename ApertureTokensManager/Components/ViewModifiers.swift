import SwiftUI

// MARK: - Compatible Glass Button Styles

/// Configuration for adaptive glass button style
public struct AdaptiveGlassConfiguration {
  let tintColor: Color?
  
  public static let regular = AdaptiveGlassConfiguration(tintColor: nil)
  
  public func tint(_ color: Color) -> AdaptiveGlassConfiguration {
    AdaptiveGlassConfiguration(tintColor: color)
  }
}

/// A button style that uses Liquid Glass on macOS 26+ and falls back to bordered style on older versions
public struct AdaptiveGlassButtonStyle: ButtonStyle {
  let configuration: AdaptiveGlassConfiguration
  
  public init(_ configuration: AdaptiveGlassConfiguration = .regular) {
    self.configuration = configuration
  }
  
  @ViewBuilder
  public func makeBody(configuration: Configuration) -> some View {
    if #available(macOS 26.0, *) {
      GlassButtonContent(
        label: configuration.label,
        isPressed: configuration.isPressed,
        tintColor: self.configuration.tintColor
      )
    } else {
      // Fallback for macOS < 26
      FallbackGlassButton(
        configuration: configuration,
        tintColor: self.configuration.tintColor
      )
    }
  }
}

/// A button style that uses Liquid Glass Prominent on macOS 26+ and falls back to borderedProminent on older versions
public struct AdaptiveGlassProminentButtonStyle: ButtonStyle {
  public init() {}
  
  @ViewBuilder
  public func makeBody(configuration: Configuration) -> some View {
    if #available(macOS 26.0, *) {
      GlassProminentButtonContent(
        label: configuration.label,
        isPressed: configuration.isPressed
      )
    } else {
      // Fallback for macOS < 26
      FallbackGlassProminentButton(configuration: configuration)
    }
  }
}

// MARK: - Liquid Glass Button Views (macOS 26+)

@available(macOS 26.0, *)
private struct GlassButtonContent<Label: View>: View {
  let label: Label
  let isPressed: Bool
  let tintColor: Color?
  
  var body: some View {
    if let tint = tintColor {
      label
        .padding(.horizontal, UIConstants.Spacing.large)
        .padding(.vertical, UIConstants.Spacing.medium)
        .glassEffect(.regular.tint(tint).interactive())
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isPressed)
    } else {
      label
        .padding(.horizontal, UIConstants.Spacing.large)
        .padding(.vertical, UIConstants.Spacing.medium)
        .glassEffect(.regular.interactive())
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isPressed)
    }
  }
}

@available(macOS 26.0, *)
private struct GlassProminentButtonContent<Label: View>: View {
  let label: Label
  let isPressed: Bool
  
  var body: some View {
    label
      .padding(.horizontal, UIConstants.Spacing.extraLarge)
      .padding(.vertical, UIConstants.Spacing.medium)
      .glassEffect(.regular.tint(.accentColor).interactive())
      .scaleEffect(isPressed ? 0.97 : 1.0)
      .animation(.easeOut(duration: 0.15), value: isPressed)
  }
}

// MARK: - Fallback Button Views

private struct FallbackGlassButton: View {
  let configuration: ButtonStyleConfiguration
  let tintColor: Color?
  
  @State private var isHovering = false
  
  private var effectiveColor: Color {
    tintColor ?? .accentColor
  }
  
  var body: some View {
    configuration.label
      .padding(.horizontal, UIConstants.Spacing.large)
      .padding(.vertical, UIConstants.Spacing.medium)
      .background(
        RoundedRectangle(cornerRadius: UIConstants.CornerRadius.large)
          .fill(effectiveColor.opacity(configuration.isPressed ? 0.2 : (isHovering ? 0.15 : 0.1)))
      )
      .overlay(
        RoundedRectangle(cornerRadius: UIConstants.CornerRadius.large)
          .stroke(effectiveColor.opacity(configuration.isPressed ? 0.5 : (isHovering ? 0.4 : 0.3)), lineWidth: 1)
      )
      .foregroundStyle(effectiveColor)
      .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
      .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
      .animation(.easeOut(duration: 0.15), value: isHovering)
      .onHover { isHovering = $0 }
  }
}

private struct FallbackGlassProminentButton: View {
  let configuration: ButtonStyleConfiguration
  
  @State private var isHovering = false
  
  var body: some View {
    configuration.label
      .padding(.horizontal, UIConstants.Spacing.extraLarge)
      .padding(.vertical, UIConstants.Spacing.medium)
      .background(
        RoundedRectangle(cornerRadius: UIConstants.CornerRadius.large)
          .fill(Color.accentColor.opacity(configuration.isPressed ? 0.9 : (isHovering ? 0.85 : 0.8)))
      )
      .foregroundStyle(.white)
      .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
      .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
      .animation(.easeOut(duration: 0.15), value: isHovering)
      .onHover { isHovering = $0 }
  }
}

// MARK: - ButtonStyle Extension

public extension ButtonStyle where Self == AdaptiveGlassButtonStyle {
  /// Adaptive glass button style - uses Liquid Glass on macOS 26+, falls back to custom style on older versions
  static func adaptiveGlass(_ configuration: AdaptiveGlassConfiguration = .regular) -> AdaptiveGlassButtonStyle {
    AdaptiveGlassButtonStyle(configuration)
  }
}

public extension ButtonStyle where Self == AdaptiveGlassProminentButtonStyle {
  /// Adaptive glass prominent button style - uses Liquid Glass on macOS 26+, falls back to custom style on older versions
  static var adaptiveGlassProminent: AdaptiveGlassProminentButtonStyle {
    AdaptiveGlassProminentButtonStyle()
  }
}

// MARK: - Pressable Button Style

/// A button style that provides press feedback with scale animation and optional icon bounce.
struct PressableButtonStyle: ButtonStyle {
  let color: Color
  let isHovering: Bool
  
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.97 : (isHovering ? 1.01 : 1.0))
      .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
  }
}

// MARK: - Pointer Hover Modifier

/// A view modifier that changes the cursor to pointing hand on hover.
struct PointerHoverModifier: ViewModifier {
  @State private var isHovering = false
  let onHover: ((Bool) -> Void)?
  
  init(onHover: ((Bool) -> Void)? = nil) {
    self.onHover = onHover
  }
  
  func body(content: Content) -> some View {
    content
      .onHover { hovering in
        isHovering = hovering
        onHover?(hovering)
        if hovering {
          NSCursor.pointingHand.push()
        } else {
          NSCursor.pop()
        }
      }
  }
}

extension View {
  /// Adds pointer cursor on hover with optional callback.
  func pointerOnHover(onHover: ((Bool) -> Void)? = nil) -> some View {
    modifier(PointerHoverModifier(onHover: onHover))
  }
}

// MARK: - Staggered Appear Modifier

/// A view modifier for staggered fade-in animations.
struct StaggeredAppearModifier: ViewModifier {
  let index: Int
  let baseDelay: Double
  let duration: Double
  
  @State private var isVisible = false
  
  init(index: Int, baseDelay: Double = 0.08, duration: Double = 0.35) {
    self.index = index
    self.baseDelay = baseDelay
    self.duration = duration
  }
  
  func body(content: Content) -> some View {
    content
      .opacity(isVisible ? 1 : 0)
      .offset(y: isVisible ? 0 : 10)
      .onAppear {
        let delay = Double(index) * baseDelay
        withAnimation(.easeOut(duration: duration).delay(delay)) {
          isVisible = true
        }
      }
  }
}

extension View {
  /// Applies a staggered appear animation based on index.
  func staggeredAppear(index: Int, baseDelay: Double = 0.08, duration: Double = 0.35) -> some View {
    modifier(StaggeredAppearModifier(index: index, baseDelay: baseDelay, duration: duration))
  }
}

// MARK: - Interactive Card Modifier

/// A view modifier for interactive cards with hover and press states.
struct InteractiveCardModifier: ViewModifier {
  let color: Color
  let cornerRadius: CGFloat
  
  @State private var isHovering = false
  
  func body(content: Content) -> some View {
    content
      .background(
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(color.opacity(isHovering ? 0.12 : 0.08))
          .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
              .stroke(color.opacity(isHovering ? 0.3 : 0.15), lineWidth: 1)
          )
      )
      .scaleEffect(isHovering ? 1.02 : 1.0)
      .shadow(color: isHovering ? color.opacity(0.15) : .clear, radius: 8)
      .animation(.easeOut(duration: AnimationDuration.normal), value: isHovering)
      .onHover { isHovering = $0 }
  }
}

extension View {
  /// Applies interactive card styling with hover effects.
  func interactiveCard(color: Color, cornerRadius: CGFloat = UIConstants.CornerRadius.medium) -> some View {
    modifier(InteractiveCardModifier(color: color, cornerRadius: cornerRadius))
  }
}

// MARK: - Animated Binding Extension

extension Binding where Value == Bool {
  /// Creates an animated binding that wraps state changes in animation.
  func animated(_ animation: Animation = .spring(response: 0.3, dampingFraction: 0.7)) -> Binding<Value> {
    Binding(
      get: { self.wrappedValue },
      set: { newValue in
        withAnimation(animation) {
          self.wrappedValue = newValue
        }
      }
    )
  }
}
