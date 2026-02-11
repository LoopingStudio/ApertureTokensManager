import ComposableArchitecture
import SwiftUI

// MARK: - Constants

private enum TutorialConstants {
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

@ViewAction(for: TutorialFeature.self)
struct TutorialView: View {
  @Bindable var store: StoreOf<TutorialFeature>
  @Namespace private var animation
  @State private var contentAppeared = false
  @State private var illustrationAppeared = false
  @State private var scrollProxy: ScrollViewProxy?
  
  var body: some View {
    HStack(spacing: 0) {
      // Sidebar
      sidebarView
        .frame(width: TutorialConstants.sidebarWidth)
      
      Divider()
      
      // Main content
      mainContentView
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .frame(width: TutorialConstants.windowWidth, height: TutorialConstants.windowHeight)
    .background(Color(nsColor: .windowBackgroundColor))
    .onAppear {
      send(.onAppear)
      withAnimation(TutorialConstants.Animation.spring.delay(0.1)) {
        contentAppeared = true
      }
      withAnimation(TutorialConstants.Animation.springBouncy.delay(0.3)) {
        illustrationAppeared = true
      }
    }
    .onChange(of: store.currentStep) { _, _ in
      illustrationAppeared = false
      withAnimation(TutorialConstants.Animation.springBouncy.delay(0.15)) {
        illustrationAppeared = true
      }
      // Reset scroll to top
      withAnimation(TutorialConstants.Animation.smooth) {
        scrollProxy?.scrollTo("stepHeader", anchor: .top)
      }
    }
  }
  
  // MARK: - Sidebar
  
  private var sidebarView: some View {
    VStack(spacing: 0) {
      // Header
      VStack(alignment: .leading, spacing: 4) {
        Text("Guide")
          .font(.title2)
          .fontWeight(.bold)
        Text("Aperture Tokens Manager")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding()
      
      Divider()
        .padding(.horizontal)
      
      // Steps
      ScrollView {
        VStack(spacing: 2) {
          ForEach(TutorialFeature.TutorialStep.allCases, id: \.self) { step in
            SidebarStepRow(
              step: step,
              isSelected: store.currentStep == step,
              isCompleted: step.rawValue < store.currentStep.rawValue,
              namespace: animation
            ) {
              send(.stepTapped(step))
            }
          }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
      }
      
      Spacer()
      
      // Skip button
      if !store.currentStep.isLast {
        Button("Passer le tutoriel") {
          send(.skipTapped)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .buttonStyle(.plain)
        .padding()
      }
    }
    .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
  }
  
  // MARK: - Main Content
  
  private var mainContentView: some View {
    VStack(spacing: 0) {
      // Close button
      HStack {
        Spacer()
        Button {
          send(.closeTapped)
        } label: {
          Image(systemName: "xmark.circle.fill")
            .font(.title2)
            .foregroundStyle(.tertiary)
            .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .help("Fermer")
      }
      .padding(.horizontal)
      .padding(.top, 12)
      
      // Content
      ScrollViewReader { proxy in
        ScrollView {
          VStack(alignment: .leading, spacing: 24) {
            // Step header with animated icon
            stepHeaderView
              .id("stepHeader")
              .opacity(contentAppeared ? 1 : 0)
              .offset(y: contentAppeared ? 0 : 20)
            
            // Description
            Text(store.currentStep.description)
              .font(.body)
              .lineSpacing(6)
              .foregroundStyle(.secondary)
              .fixedSize(horizontal: false, vertical: true)
              .opacity(contentAppeared ? 1 : 0)
              .offset(y: contentAppeared ? 0 : 10)
            
            // Image placeholder / Illustration
            illustrationView
              .opacity(illustrationAppeared ? 1 : 0)
              .scaleEffect(illustrationAppeared ? 1 : 0.95)
          }
          .padding(24)
        }
        .onAppear { scrollProxy = proxy }
      }
      
      // Navigation
      navigationView
    }
  }
  
  // MARK: - Step Header
  
  private var stepHeaderView: some View {
    HStack(spacing: 16) {
      // Animated icon
      ZStack {
        Circle()
          .fill(stepColor.opacity(0.15))
          .frame(width: 64, height: 64)
        
        Circle()
          .fill(stepColor.opacity(0.1))
          .frame(width: 64, height: 64)
          .scaleEffect(illustrationAppeared ? 1.2 : 1)
          .opacity(illustrationAppeared ? 0 : 0.5)
        
        Image(systemName: store.currentStep.icon)
          .font(.system(size: 28))
          .fontWeight(.medium)
          .foregroundStyle(stepColor)
          .symbolEffect(.bounce, value: store.currentStep)
      }
      
      VStack(alignment: .leading, spacing: 4) {
        Text(store.currentStep.subtitle)
          .font(.subheadline)
          .foregroundStyle(.secondary)
        
        Text(store.currentStep.title)
          .font(.title)
          .fontWeight(.bold)
      }
      
      Spacer()
    }
  }
  
  // MARK: - Illustration View
  
  @ViewBuilder
  private var illustrationView: some View {
    switch store.currentStep {
    case .welcome: welcomeIllustration
    case .exportFigma: figmaIllustration
    case .importTokens: importIllustration
    case .setAsBase: baseIllustration
    case .compareAnalyze: compareIllustration
    case .exportXcode: exportIllustration
    }
  }
  
  // MARK: - Welcome
  
  private var welcomeIllustration: some View {
    VStack(spacing: 24) {
      // Workflow animation
      HStack(spacing: 20) {
        workflowIcon(icon: "rectangle.3.group", label: "Figma", color: .pink, delay: 0)
        
        animatedArrow(delay: 0.1)
        
        workflowIcon(icon: "app.badge.checkmark", label: "Cette app", color: .purple, delay: 0.2)
        
        animatedArrow(delay: 0.3)
        
        workflowIcon(icon: "hammer.fill", label: "Xcode", color: .blue, delay: 0.4)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 32)
    }
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(stepColor.opacity(0.06))
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .strokeBorder(stepColor.opacity(0.1), lineWidth: 1)
        )
    )
  }
  
  private func workflowIcon(icon: String, label: String, color: Color, delay: Double) -> some View {
    VStack(spacing: 10) {
      ZStack {
        Circle()
          .fill(color.opacity(0.15))
          .frame(width: 56, height: 56)
        
        Image(systemName: icon)
          .font(.title2)
          .foregroundStyle(color)
      }
      .scaleEffect(illustrationAppeared ? 1 : 0.5)
      .animation(TutorialConstants.Animation.springBouncy.delay(delay), value: illustrationAppeared)
      
      Text(label)
        .font(.caption)
        .fontWeight(.medium)
        .foregroundStyle(.secondary)
    }
  }
  
  private func animatedArrow(delay: Double) -> some View {
    Image(systemName: "arrow.right")
      .font(.title3)
      .foregroundStyle(.tertiary)
      .opacity(illustrationAppeared ? 1 : 0)
      .offset(x: illustrationAppeared ? 0 : -10)
      .animation(TutorialConstants.Animation.smooth.delay(delay), value: illustrationAppeared)
  }
  
  // MARK: - Figma
  
  private var figmaIllustration: some View {
    VStack(spacing: 20) {
      // Plugin link card
      Link(destination: TutorialConstants.figmaPluginURL) {
        HStack(spacing: 16) {
          ZStack {
            RoundedRectangle(cornerRadius: 12)
              .fill(Color.pink.opacity(0.15))
              .frame(width: 52, height: 52)
            
            Image(systemName: "puzzlepiece.extension.fill")
              .font(.title2)
              .foregroundStyle(.pink)
          }
          
          VStack(alignment: .leading, spacing: 4) {
            Text("Multibrand Token Exporter")
              .font(.headline)
              .foregroundStyle(.primary)
            Text("Ouvrir sur Figma Community")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          
          Spacer()
          
          Image(systemName: "arrow.up.right.circle.fill")
            .font(.title2)
            .foregroundStyle(.pink.opacity(0.8))
        }
        .padding(16)
        .background(
          RoundedRectangle(cornerRadius: 14)
            .fill(Color(nsColor: .controlBackgroundColor))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
        .overlay(
          RoundedRectangle(cornerRadius: 14)
            .strokeBorder(Color.pink.opacity(0.2), lineWidth: 1)
        )
      }
      .buttonStyle(.plain)
      .scaleEffect(illustrationAppeared ? 1 : 0.95)
      .animation(TutorialConstants.Animation.spring, value: illustrationAppeared)

      Image(.plugin)
        .resizable()
        .scaledToFit()
        .frame(maxWidth: .infinity)
    }
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(stepColor.opacity(0.06))
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .strokeBorder(stepColor.opacity(0.1), lineWidth: 1)
        )
    )
  }
  
  // MARK: - Import
  
  private var importIllustration: some View {
    VStack(spacing: 20) {
      // Animated import flow
      HStack(spacing: 24) {
        VStack(spacing: 8) {
          ZStack {
            RoundedRectangle(cornerRadius: 8)
              .fill(Color.blue.opacity(0.1))
              .frame(width: 64, height: 80)
            
            VStack(spacing: 4) {
              Image(systemName: "doc.text.fill")
                .font(.title)
                .foregroundStyle(.blue)
              Text(".json")
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
          }
          .scaleEffect(illustrationAppeared ? 1 : 0.8)
          .animation(TutorialConstants.Animation.springBouncy, value: illustrationAppeared)
          
          Text("Fichier exporté")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        
        // Animated dotted line
        DottedArrow()
          .opacity(illustrationAppeared ? 1 : 0)
          .animation(TutorialConstants.Animation.smooth.delay(0.2), value: illustrationAppeared)
        
        VStack(spacing: 8) {
          ZStack {
            RoundedRectangle(cornerRadius: 12)
              .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
              .foregroundStyle(.blue.opacity(0.4))
              .frame(width: 80, height: 80)
            
            Image(systemName: "square.and.arrow.down")
              .font(.title)
              .foregroundStyle(.blue)
              .symbolEffect(.pulse, options: .repeating, value: illustrationAppeared)
          }
          .scaleEffect(illustrationAppeared ? 1 : 0.8)
          .animation(TutorialConstants.Animation.springBouncy.delay(0.1), value: illustrationAppeared)
          
          Text("Drop Zone")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 16)
    }
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(stepColor.opacity(0.06))
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .strokeBorder(stepColor.opacity(0.1), lineWidth: 1)
        )
    )
  }
  
  // MARK: - Base
  
  private var baseIllustration: some View {
    VStack(spacing: 20) {
      // Animated seal
      HStack(spacing: 20) {
        ZStack {
          Circle()
            .fill(Color.orange.opacity(0.15))
            .frame(width: 72, height: 72)
          
          Image(systemName: "checkmark.seal.fill")
            .font(.system(size: 36))
            .foregroundStyle(.orange)
            .symbolEffect(.bounce, value: illustrationAppeared)
        }
        .scaleEffect(illustrationAppeared ? 1 : 0.5)
        .animation(TutorialConstants.Animation.springBouncy, value: illustrationAppeared)
        
        VStack(alignment: .leading, spacing: 6) {
          Text("Design System de référence")
            .font(.headline)
          Text("Ce fichier sera utilisé comme base de comparaison pour les futures versions.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        .opacity(illustrationAppeared ? 1 : 0)
        .offset(x: illustrationAppeared ? 0 : 20)
        .animation(TutorialConstants.Animation.smooth.delay(0.15), value: illustrationAppeared)
      }
      .padding(16)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(Color.orange.opacity(0.08))
      )
      
      // Image placeholder
      ImagePlaceholder(
        label: "Capture de la page d'accueil avec base définie",
        icon: "house.fill",
        color: .orange
      )
    }
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(stepColor.opacity(0.06))
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .strokeBorder(stepColor.opacity(0.1), lineWidth: 1)
        )
    )
  }
  
  // MARK: - Compare
  
  private var compareIllustration: some View {
    VStack(spacing: 20) {
      // Feature cards
      HStack(spacing: 16) {
        FeatureCard(
          icon: "doc.text.magnifyingglass",
          title: "Comparer",
          subtitle: "+12 ajoutés • -3 supprimés • ~8 modifiés",
          color: .green,
          delay: 0,
          appeared: illustrationAppeared
        )
        
        FeatureCard(
          icon: "chart.bar.doc.horizontal",
          title: "Analyser",
          subtitle: "45 utilisés • 12 orphelins",
          color: .mint,
          delay: 0.1,
          appeared: illustrationAppeared
        )
      }
    }
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(stepColor.opacity(0.06))
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .strokeBorder(stepColor.opacity(0.1), lineWidth: 1)
        )
    )
  }
  
  // MARK: - Export
  
  private var exportIllustration: some View {
    VStack(spacing: 20) {
      // Export outputs
      HStack(spacing: 24) {
        ExportFileView(
          icon: "folder.fill.badge.plus",
          filename: "Colors.xcassets",
          description: "Asset Catalog",
          color: .teal,
          delay: 0,
          appeared: illustrationAppeared
        )
        
        ExportFileView(
          icon: "swift",
          filename: "Aperture+Colors.swift",
          description: "Extensions Swift",
          color: .orange,
          delay: 0.15,
          appeared: illustrationAppeared
        )
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 8)
    }
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(stepColor.opacity(0.06))
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .strokeBorder(stepColor.opacity(0.1), lineWidth: 1)
        )
    )
  }
  
  // MARK: - Navigation
  
  private var navigationView: some View {
    HStack {
      // Progress indicator
      HStack(spacing: 8) {
        ForEach(TutorialFeature.TutorialStep.allCases, id: \.self) { step in
          Capsule()
            .fill(store.currentStep.rawValue >= step.rawValue ? stepColor : Color.secondary.opacity(0.2))
            .frame(width: store.currentStep == step ? 24 : 8, height: 8)
            .animation(TutorialConstants.Animation.spring, value: store.currentStep)
        }
      }
      
      Spacer()
      
      // Navigation buttons
      HStack(spacing: 12) {
        if !store.currentStep.isFirst {
          Button {
            send(.backTapped)
          } label: {
            HStack(spacing: 4) {
              Image(systemName: "chevron.left")
              Text("Précédent")
            }
          }
          .buttonStyle(.adaptiveGlass())
        }
        
        Button {
          send(.nextTapped)
        } label: {
          HStack(spacing: 4) {
            Text(store.currentStep.isLast ? "Commencer" : "Suivant")
            Image(systemName: store.currentStep.isLast ? "checkmark" : "chevron.right")
          }
        }
        .buttonStyle(.adaptiveGlassProminent)
      }
    }
    .padding(20)
    .background(Color(nsColor: .windowBackgroundColor))
  }
  
  // MARK: - Helpers
  
  private var stepColor: Color {
    switch store.currentStep.color {
    case "purple": return .purple
    case "pink": return .pink
    case "blue": return .blue
    case "orange": return .orange
    case "green": return .green
    case "teal": return .teal
    default: return .accentColor
    }
  }
}

// MARK: - Sidebar Step Row

private struct SidebarStepRow: View {
  let step: TutorialFeature.TutorialStep
  let isSelected: Bool
  let isCompleted: Bool
  let namespace: Namespace.ID
  let onTap: () -> Void
  
  private var stepColor: Color {
    switch step.color {
    case "purple": return .purple
    case "pink": return .pink
    case "blue": return .blue
    case "orange": return .orange
    case "green": return .green
    case "teal": return .teal
    default: return .accentColor
    }
  }
  
  var body: some View {
    Button(action: onTap) {
      HStack(spacing: 12) {
        // Step indicator
        ZStack {
          Circle()
            .fill(isSelected ? stepColor : (isCompleted ? .green : Color.secondary.opacity(0.15)))
            .frame(width: 28, height: 28)
          
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
            .frame(width: 6, height: 6)
        }
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 10)
      .background {
        if isSelected {
          RoundedRectangle(cornerRadius: 10)
            .fill(stepColor.opacity(0.12))
            .matchedGeometryEffect(id: "selectedStep", in: namespace)
        }
      }
    }
    .buttonStyle(.plain)
  }
}

// MARK: - Image Placeholder

private struct ImagePlaceholder: View {
  let label: String
  let icon: String
  let color: Color
  
  var body: some View {
    VStack(spacing: 12) {
      ZStack {
        RoundedRectangle(cornerRadius: 8)
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
        RoundedRectangle(cornerRadius: 8)
          .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
          .foregroundStyle(color.opacity(0.3))
      )
    }
  }
}

// MARK: - Dotted Arrow

private struct DottedArrow: View {
  var body: some View {
    HStack(spacing: 4) {
      ForEach(0..<4, id: \.self) { _ in
        Circle()
          .fill(Color.blue.opacity(0.4))
          .frame(width: 4, height: 4)
      }
      Image(systemName: "chevron.right")
        .font(.caption2)
        .foregroundStyle(.blue.opacity(0.6))
    }
  }
}

// MARK: - Feature Card

private struct FeatureCard: View {
  let icon: String
  let title: String
  let subtitle: String
  let color: Color
  let delay: Double
  let appeared: Bool
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 10) {
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
    .padding(16)
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

private struct ExportFileView: View {
  let icon: String
  let filename: String
  let description: String
  let color: Color
  let delay: Double
  let appeared: Bool
  
  var body: some View {
    VStack(spacing: 12) {
      ZStack {
        RoundedRectangle(cornerRadius: 12)
          .fill(color.opacity(0.12))
          .frame(width: 72, height: 72)
        
        Image(systemName: icon)
          .font(.system(size: 32))
          .foregroundStyle(color)
      }
      
      VStack(spacing: 2) {
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

// MARK: - Preview

#if DEBUG
#Preview {
  TutorialView(
    store: Store(initialState: .initial) {
      TutorialFeature()
    }
  )
}
#endif
