import ComposableArchitecture
import SwiftUI

// MARK: - Tutorial View

@ViewAction(for: TutorialFeature.self)
struct TutorialView: View {
  @Bindable var store: StoreOf<TutorialFeature>
  @Namespace private var animation
  @State private var contentAppeared = false
  @State private var illustrationAppeared = false
  @State private var scrollProxy: ScrollViewProxy?
  
  var body: some View {
    HStack(spacing: 0) {
      sidebarView
        .frame(width: TutorialConstants.sidebarWidth)
      
      Divider()
      
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
      withAnimation(TutorialConstants.Animation.smooth) {
        scrollProxy?.scrollTo("stepHeader", anchor: .top)
      }
    }
  }
  
  private var stepColor: Color {
    tutorialStepColor(for: store.currentStep.color)
  }
}

// MARK: - Sidebar

extension TutorialView {
  private var sidebarView: some View {
    VStack(spacing: 0) {
      sidebarHeader
      
      Divider()
        .padding(.horizontal)
      
      sidebarStepsList
      
      Spacer()
      
      if !store.currentStep.isLast {
        skipButton
      }
    }
    .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
  }
  
  private var sidebarHeader: some View {
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
  }
  
  private var sidebarStepsList: some View {
    ScrollView {
      VStack(spacing: 2) {
        ForEach(TutorialFeature.TutorialStep.allCases, id: \.self) { step in
          TutorialSidebarStepRow(
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
  }
  
  private var skipButton: some View {
    Button("Passer le tutoriel") {
      send(.skipTapped)
    }
    .font(.caption)
    .foregroundStyle(.secondary)
    .buttonStyle(.plain)
    .padding()
  }
}

// MARK: - Main Content

extension TutorialView {
  private var mainContentView: some View {
    VStack(spacing: 0) {
      closeButtonRow
      
      ScrollViewReader { proxy in
        ScrollView {
          VStack(alignment: .leading, spacing: 24) {
            stepHeaderView
              .id("stepHeader")
              .opacity(contentAppeared ? 1 : 0)
              .offset(y: contentAppeared ? 0 : 20)
            
            Text(store.currentStep.description)
              .font(.body)
              .lineSpacing(6)
              .foregroundStyle(.secondary)
              .fixedSize(horizontal: false, vertical: true)
              .opacity(contentAppeared ? 1 : 0)
              .offset(y: contentAppeared ? 0 : 10)
            
            illustrationView
              .opacity(illustrationAppeared ? 1 : 0)
              .scaleEffect(illustrationAppeared ? 1 : 0.95)
          }
          .padding(UIConstants.Spacing.section)
        }
        .onAppear { scrollProxy = proxy }
      }
      
      navigationView
    }
  }
  
  private var closeButtonRow: some View {
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
    .padding(.top, UIConstants.Spacing.large)
  }
  
  private var stepHeaderView: some View {
    HStack(spacing: UIConstants.Spacing.extraLarge) {
      ZStack {
        Circle()
          .fill(stepColor.opacity(0.15))
          .frame(width: UIConstants.Size.colorSquare, height: UIConstants.Size.colorSquare)
        
        Circle()
          .fill(stepColor.opacity(0.1))
          .frame(width: UIConstants.Size.colorSquare, height: UIConstants.Size.colorSquare)
          .scaleEffect(illustrationAppeared ? 1.2 : 1)
          .opacity(illustrationAppeared ? 0 : 0.5)
        
        Image(systemName: store.currentStep.icon)
          .font(.system(size: 28))
          .fontWeight(.medium)
          .foregroundStyle(stepColor)
          .symbolEffect(.bounce, value: store.currentStep)
      }
      
      VStack(alignment: .leading, spacing: UIConstants.Spacing.small) {
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
  
  private var navigationView: some View {
    HStack {
      progressIndicator
      
      Spacer()
      
      navigationButtons
    }
    .padding(UIConstants.Spacing.xxLarge)
    .background(Color(nsColor: .windowBackgroundColor))
  }
  
  private var progressIndicator: some View {
    HStack(spacing: UIConstants.Spacing.medium) {
      ForEach(TutorialFeature.TutorialStep.allCases, id: \.self) { step in
        Capsule()
          .fill(store.currentStep.rawValue >= step.rawValue ? stepColor : Color.secondary.opacity(0.2))
          .frame(width: store.currentStep == step ? UIConstants.Spacing.section : UIConstants.Spacing.medium, height: UIConstants.Spacing.medium)
          .animation(TutorialConstants.Animation.spring, value: store.currentStep)
      }
    }
  }
  
  private var navigationButtons: some View {
    HStack(spacing: UIConstants.Spacing.large) {
      if !store.currentStep.isFirst {
        Button {
          send(.backTapped)
        } label: {
          HStack(spacing: UIConstants.Spacing.small) {
            Image(systemName: "chevron.left")
            Text("Précédent")
          }
        }
        .buttonStyle(.adaptiveGlass())
      }
      
      Button {
        send(.nextTapped)
      } label: {
        HStack(spacing: UIConstants.Spacing.small) {
          Text(store.currentStep.isLast ? "Commencer" : "Suivant")
          Image(systemName: store.currentStep.isLast ? "checkmark" : "chevron.right")
        }
      }
      .buttonStyle(.adaptiveGlassProminent)
    }
  }
}

// MARK: - Illustrations

extension TutorialView {
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
  
  private var welcomeIllustration: some View {
    TutorialIllustrationBackground(color: stepColor) {
      HStack(spacing: UIConstants.Spacing.xxLarge) {
        workflowIcon(icon: "rectangle.3.group", label: "Figma", color: .pink, delay: 0)
        animatedArrow(delay: 0.1)
        workflowIcon(icon: "app.badge.checkmark", label: "Cette app", color: .purple, delay: 0.2)
        animatedArrow(delay: 0.3)
        workflowIcon(icon: "hammer.fill", label: "Xcode", color: .blue, delay: 0.4)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, UIConstants.Spacing.section)
    }
  }
  
  private func workflowIcon(icon: String, label: String, color: Color, delay: Double) -> some View {
    VStack(spacing: UIConstants.Spacing.large) {
      ZStack {
        Circle()
          .fill(color.opacity(0.15))
          .frame(width: UIConstants.Size.headerIconSize, height: UIConstants.Size.headerIconSize)
        
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
  
  private var figmaIllustration: some View {
    TutorialIllustrationBackground(color: stepColor) {
      VStack(spacing: UIConstants.Spacing.xxLarge) {
        figmaPluginLink
          .scaleEffect(illustrationAppeared ? 1 : 0.95)
          .animation(TutorialConstants.Animation.spring, value: illustrationAppeared)

        Image(.plugin)
          .resizable()
          .scaledToFit()
          .frame(maxWidth: .infinity)
      }
    }
  }
  
  private var figmaPluginLink: some View {
    Link(destination: TutorialConstants.figmaPluginURL) {
      HStack(spacing: UIConstants.Spacing.extraLarge) {
        ZStack {
          RoundedRectangle(cornerRadius: 12)
            .fill(Color.pink.opacity(0.15))
            .frame(width: 52, height: 52)
          
          Image(systemName: "puzzlepiece.extension.fill")
            .font(.title2)
            .foregroundStyle(.pink)
        }
        
        VStack(alignment: .leading, spacing: UIConstants.Spacing.small) {
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
  }
  
  private var importIllustration: some View {
    TutorialIllustrationBackground(color: stepColor) {
      HStack(spacing: UIConstants.Spacing.section) {
        importFileIcon
        
        TutorialDottedArrow()
          .opacity(illustrationAppeared ? 1 : 0)
          .animation(TutorialConstants.Animation.smooth.delay(0.2), value: illustrationAppeared)
        
        importDropZoneIcon
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, UIConstants.Spacing.extraLarge)
    }
  }
  
  private var importFileIcon: some View {
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
  }
  
  private var importDropZoneIcon: some View {
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
  
  private var baseIllustration: some View {
    TutorialIllustrationBackground(color: stepColor) {
      VStack(spacing: UIConstants.Spacing.xxLarge) {
        baseSealRow
        
        TutorialImagePlaceholder(
          label: "Capture de la page d'accueil avec base définie",
          icon: "house.fill",
          color: .orange
        )
      }
    }
  }
  
  private var baseSealRow: some View {
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
  }
  
  private var compareIllustration: some View {
    TutorialIllustrationBackground(color: stepColor) {
      HStack(spacing: UIConstants.Spacing.extraLarge) {
        TutorialFeatureCard(
          icon: "doc.text.magnifyingglass",
          title: "Comparer",
          subtitle: "+12 ajoutés • -3 supprimés • ~8 modifiés",
          color: .green,
          delay: 0,
          appeared: illustrationAppeared
        )
        
        TutorialFeatureCard(
          icon: "chart.bar.doc.horizontal",
          title: "Analyser",
          subtitle: "45 utilisés • 12 orphelins",
          color: .mint,
          delay: 0.1,
          appeared: illustrationAppeared
        )
      }
    }
  }
  
  private var exportIllustration: some View {
    TutorialIllustrationBackground(color: stepColor) {
      HStack(spacing: UIConstants.Spacing.section) {
        TutorialExportFileView(
          icon: "folder.fill.badge.plus",
          filename: "Colors.xcassets",
          description: "Asset Catalog",
          color: .teal,
          delay: 0,
          appeared: illustrationAppeared
        )
        
        TutorialExportFileView(
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
