import SwiftUI

// MARK: - Tutorial Constants

enum TutorialConstants {
  static let windowWidth: CGFloat = 820
  static let windowHeight: CGFloat = 580
  static let sidebarWidth: CGFloat = 220
  static let imageHeight: CGFloat = 200
  static let figmaPluginURL = URL(string: "https://www.figma.com/community/plugin/1601261816129528282/multibrand-token-exporter")!
  
  enum Animation {
    static let spring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.8)
    static let springBouncy = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.7)
    static let smooth = SwiftUI.Animation.easeInOut(duration: 0.35)
  }
}

// MARK: - Step Color Helper

func tutorialStepColor(for colorName: String) -> Color {
  switch colorName {
  case "purple": return .purple
  case "pink": return .pink
  case "blue": return .blue
  case "orange": return .orange
  case "green": return .green
  case "teal": return .teal
  default: return .accentColor
  }
}

// MARK: - Sidebar Step Row

struct TutorialSidebarStepRow: View {
  let step: TutorialFeature.TutorialStep
  let isSelected: Bool
  let isCompleted: Bool
  let namespace: Namespace.ID
  let onTap: () -> Void
  
  private var stepColor: Color {
    tutorialStepColor(for: step.color)
  }
  
  var body: some View {
    Button(action: onTap) {
      HStack(spacing: UIConstants.Spacing.large) {
        // Step indicator
        ZStack {
          Circle()
            .fill(isSelected ? stepColor : (isCompleted ? .green : Color.secondary.opacity(0.15)))
            .frame(width: UIConstants.Size.sidebarIndicatorSize, height: UIConstants.Size.sidebarIndicatorSize)
          
          if isCompleted && !isSelected {
            Image(systemName: "checkmark")
              .font(.caption)
              .fontWeight(.bold)
              .foregroundStyle(.white)
          } else {
            Text("\(step.rawValue)")
              .font(.caption)
              .fontWeight(.semibold)
              .foregroundStyle(isSelected ? .white : .secondary)
          }
        }
        
        // Title
        Text(step.title)
          .font(.subheadline)
          .fontWeight(isSelected ? .semibold : .regular)
          .foregroundStyle(isSelected ? .primary : .secondary)
        
        Spacer()
        
        // Selected indicator
        if isSelected {
          Circle()
            .fill(stepColor)
            .frame(width: UIConstants.Spacing.medium, height: UIConstants.Spacing.medium)
        }
      }
      .padding(.horizontal, UIConstants.Spacing.large)
      .padding(.vertical, UIConstants.Spacing.large)
      .background {
        if isSelected {
          RoundedRectangle(cornerRadius: UIConstants.CornerRadius.extraLarge)
            .fill(stepColor.opacity(0.12))
            .matchedGeometryEffect(id: "selectedStep", in: namespace)
        }
      }
    }
    .buttonStyle(.plain)
  }
}

// MARK: - Image Placeholder

struct TutorialImagePlaceholder: View {
  let label: String
  let icon: String
  let color: Color
  
  var body: some View {
    VStack(spacing: UIConstants.Spacing.large) {
      ZStack {
        RoundedRectangle(cornerRadius: UIConstants.CornerRadius.large)
          .fill(color.opacity(0.08))
        
        VStack(spacing: 8) {
          Image(systemName: icon)
            .font(.largeTitle)
            .foregroundStyle(color.opacity(0.4))
          
          Text(label)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .frame(height: TutorialConstants.imageHeight)
      .overlay(
        RoundedRectangle(cornerRadius: UIConstants.CornerRadius.large)
          .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
          .foregroundStyle(color.opacity(0.3))
      )
    }
  }
}

// MARK: - Dotted Arrow

struct TutorialDottedArrow: View {
  var body: some View {
    HStack(spacing: UIConstants.Spacing.small) {
      ForEach(0..<4, id: \.self) { _ in
        Circle()
          .fill(Color.blue.opacity(0.4))
          .frame(width: UIConstants.Spacing.small, height: UIConstants.Spacing.small)
      }
      Image(systemName: "chevron.right")
        .font(.caption2)
        .foregroundStyle(.blue.opacity(0.6))
    }
  }
}

// MARK: - Feature Card

struct TutorialFeatureCard: View {
  let icon: String
  let title: String
  let subtitle: String
  let color: Color
  let delay: Double
  let appeared: Bool
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: UIConstants.Spacing.large) {
        Image(systemName: icon)
          .font(.title2)
          .foregroundStyle(color)
        
        Text(title)
          .font(.headline)
      }
      
      Text(subtitle)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(UIConstants.Spacing.extraLarge)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(color.opacity(0.1))
    )
    .scaleEffect(appeared ? 1 : 0.9)
    .opacity(appeared ? 1 : 0)
    .animation(TutorialConstants.Animation.springBouncy.delay(delay), value: appeared)
  }
}

// MARK: - Export File View

struct TutorialExportFileView: View {
  let icon: String
  let filename: String
  let description: String
  let color: Color
  let delay: Double
  let appeared: Bool
  
  var body: some View {
    VStack(spacing: UIConstants.Spacing.large) {
      ZStack {
        RoundedRectangle(cornerRadius: UIConstants.CornerRadius.xxLarge)
          .fill(color.opacity(0.12))
          .frame(width: UIConstants.Size.tutorialIconSize, height: UIConstants.Size.tutorialIconSize)
        
        Image(systemName: icon)
          .font(.system(size: 32))
          .foregroundStyle(color)
      }
      
      VStack(spacing: UIConstants.Spacing.extraSmall) {
        Text(filename)
          .font(.caption)
          .fontWeight(.medium)
        Text(description)
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }
    .scaleEffect(appeared ? 1 : 0.8)
    .opacity(appeared ? 1 : 0)
    .animation(TutorialConstants.Animation.springBouncy.delay(delay), value: appeared)
  }
}

// MARK: - Illustration Background

struct TutorialIllustrationBackground<Content: View>: View {
  let color: Color
  @ViewBuilder let content: () -> Content
  
  var body: some View {
    content()
      .padding(UIConstants.Spacing.xxLarge)
      .background(
        RoundedRectangle(cornerRadius: UIConstants.CornerRadius.xxLarge)
          .fill(color.opacity(0.06))
          .overlay(
            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.xxLarge)
              .strokeBorder(color.opacity(0.1), lineWidth: 1)
          )
      )
  }
}
