import SwiftUI
import ComposableArchitecture

@ViewAction(for: HomeFeature.self)
struct HomeView: View {
  @Bindable var store: StoreOf<HomeFeature>
  
  @State private var showHeader = false
  @State private var showStats = false
  @State private var showActions = false
  @State private var showHistory = false
  @State private var showEmptyContent = false
  @State private var iconPulse = false
  
  var body: some View {
    VStack(spacing: 0) {
      header
      Divider()
      
      if let base = store.designSystemBase {
        designSystemBaseContent(base)
      } else {
        emptyBaseContent
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .sheet(item: $store.scope(state: \.tokenBrowser, action: \.tokenBrowser)) { browserStore in
      TokenBrowserView(store: browserStore)
    }
  }
}

// MARK: - Header

extension HomeView {
  private var header: some View {
    HStack {
      Text("Accueil")
        .font(.title)
        .fontWeight(.bold)
      
      Spacer()
      
      if store.designSystemBase != nil {
        headerMenu
      }
    }
    .padding()
  }
  
  private var headerMenu: some View {
    Menu {
      Button(action: { send(.openFileButtonTapped) }) {
        Label("Afficher dans le Finder", systemImage: "folder")
      }
      Divider()
      Button(role: .destructive, action: { send(.clearBaseButtonTapped) }) {
        Label("Supprimer la base", systemImage: "trash")
      }
    } label: {
      Image(systemName: "ellipsis.circle")
        .font(.title2)
        .foregroundStyle(.secondary)
    }
    .menuStyle(.borderlessButton)
    .menuIndicator(.hidden)
    .fixedSize()
  }
}

// MARK: - Empty State

extension HomeView {
  private var emptyBaseContent: some View {
    VStack(spacing: UIConstants.Spacing.large) {
      emptyStateIcon
      emptyStateText
      emptyStateButton
    }
    .padding(UIConstants.Spacing.extraLarge)
    .frame(maxHeight: .infinity)
    .onAppear {
      withAnimation(.easeOut(duration: 0.5)) {
        showEmptyContent = true
      }
      withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
        iconPulse = true
      }
    }
  }
  
  private var emptyStateIcon: some View {
    ZStack {
      Circle()
        .fill(Color.purple.opacity(0.1))
        .frame(width: UIConstants.Size.emptyStateIconSize, height: UIConstants.Size.emptyStateIconSize)
        .scaleEffect(iconPulse ? 1.1 : 1.0)
      
      Image(systemName: "square.stack.3d.up.slash")
        .font(.system(size: UIConstants.Size.iconLarge))
        .foregroundStyle(.purple.opacity(0.6))
    }
    .opacity(showEmptyContent ? 1 : 0)
    .scaleEffect(showEmptyContent ? 1 : 0.8)
  }
  
  private var emptyStateText: some View {
    VStack(spacing: UIConstants.Spacing.small) {
      Text("Aucun Design System défini")
        .font(.title2)
        .fontWeight(.semibold)
      
      Text("Importez un fichier de tokens et définissez-le comme base\npour accéder à l'accueil.")
        .font(.body)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .opacity(showEmptyContent ? 1 : 0)
    .offset(y: showEmptyContent ? 0 : 10)
  }
  
  private var emptyStateButton: some View {
    Button {
      send(.goToImportTapped)
    } label: {
      HStack(spacing: UIConstants.Spacing.medium) {
        Image(systemName: "arrow.right.circle.fill")
          .foregroundStyle(.purple)
        Text("Utilisez l'onglet Importer pour charger un Design System")
      }
      .font(.callout)
      .foregroundStyle(.secondary)
      .padding(.horizontal, UIConstants.Spacing.extraLarge)
      .padding(.vertical, UIConstants.Spacing.large)
      .background(
        Capsule()
          .fill(Color.purple.opacity(0.1))
      )
      .opacity(showEmptyContent ? 1 : 0)
      .offset(y: showEmptyContent ? 0 : 15)
    }
    .buttonStyle(.plain)
  }
}

// MARK: - Design System Content

extension HomeView {
  private func designSystemBaseContent(_ base: DesignSystemBase) -> some View {
    ScrollView {
      VStack(spacing: UIConstants.Spacing.large) {
        headerCard(base)
          .opacity(showHeader ? 1 : 0)
          .offset(y: showHeader ? 0 : -15)
        
        statsSection(base)
          .opacity(showStats ? 1 : 0)
          .offset(y: showStats ? 0 : 15)
        
        actionsSection
          .opacity(showActions ? 1 : 0)
          .offset(y: showActions ? 0 : 20)
        
        UnifiedHistoryView(
          items: store.unifiedHistory,
          filter: store.historyFilter,
          onFilterChange: { send(.historyFilterChanged($0)) },
          onItemTapped: { send(.historyItemTapped($0)) }
        )
        .opacity(showHistory ? 1 : 0)
        .offset(y: showHistory ? 0 : 25)
        
        Spacer(minLength: UIConstants.Spacing.xxLarge)
      }
      .padding(UIConstants.Spacing.large)
    }
    .onAppear { animateContentAppearance() }
  }
  
  private func animateContentAppearance() {
    withAnimation(.easeOut(duration: 0.35)) {
      showHeader = true
    }
    withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
      showStats = true
    }
    withAnimation(.easeOut(duration: 0.45).delay(0.2)) {
      showActions = true
    }
    withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
      showHistory = true
    }
  }
}

// MARK: - Header Card

extension HomeView {
  private func headerCard(_ base: DesignSystemBase) -> some View {
    HStack(spacing: UIConstants.Spacing.medium) {
      headerCardIcon
      headerCardInfo(base)
      Spacer()
    }
    .padding(UIConstants.Spacing.medium)
    .background(headerCardBackground)
  }
  
  private var headerCardIcon: some View {
    ZStack {
      Circle()
        .fill(Color.green.opacity(0.15))
        .frame(width: UIConstants.Size.headerIconSize, height: UIConstants.Size.headerIconSize)
      
      Image(systemName: "checkmark.seal.fill")
        .font(.title)
        .foregroundStyle(.green)
    }
  }
  
  private func headerCardInfo(_ base: DesignSystemBase) -> some View {
    VStack(alignment: .leading, spacing: UIConstants.Spacing.small) {
      HStack(spacing: UIConstants.Spacing.medium) {
        Text("Design System Actif")
          .font(.caption)
          .fontWeight(.medium)
          .foregroundStyle(.green)
          .padding(.horizontal, UIConstants.Spacing.medium)
          .padding(.vertical, UIConstants.Spacing.extraSmall)
          .background(
            Capsule()
              .fill(Color.green.opacity(0.15))
          )
      }
      
      Text(base.fileName)
        .font(.title3)
        .fontWeight(.semibold)
        .lineLimit(1)
      
      if !base.metadata.version.isEmpty {
        Text("Version \(base.metadata.version)")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }
  
  private var headerCardBackground: some View {
    RoundedRectangle(cornerRadius: UIConstants.CornerRadius.large)
      .fill(Color.green.opacity(0.08))
      .overlay(
        RoundedRectangle(cornerRadius: UIConstants.CornerRadius.large)
          .stroke(Color.green.opacity(0.2), lineWidth: 1)
      )
  }
}

// MARK: - Stats Section

extension HomeView {
  private func statsSection(_ base: DesignSystemBase) -> some View {
    HStack(spacing: UIConstants.Spacing.medium) {
      StatCard(
        title: "Tokens",
        value: "\(base.tokenCount)",
        subtitle: "dans le design system",
        color: .blue,
        icon: "paintpalette.fill",
        action: { send(.tokenCountTapped) }
      )
      .staggeredAppear(index: 0)
      
      StatCard(
        title: "Défini le",
        value: base.setAt.shortFormatted,
        subtitle: "comme base de référence",
        color: .orange,
        icon: "calendar"
      )
      .staggeredAppear(index: 1)
      
      StatCard(
        title: "Exporté le",
        value: base.metadata.exportedAt.toShortDate(),
        subtitle: "avec \(base.metadata.generator)",
        color: .purple,
        icon: "arrow.up.doc.fill"
      )
      .staggeredAppear(index: 2)
    }
  }
}

// MARK: - Actions Section

extension HomeView {
  private var actionsSection: some View {
    VStack(alignment: .leading, spacing: UIConstants.Spacing.medium) {
      Text("Actions rapides")
        .font(.headline)
        .foregroundStyle(.secondary)
      
      HStack(spacing: UIConstants.Spacing.medium) {
        ExportActionCard(store: store)
          .staggeredAppear(index: 0, duration: 0.4)
        
        ActionCard(
          title: "Comparer avec un nouvel import",
          subtitle: "Détecter les changements",
          icon: "doc.text.magnifyingglass",
          color: .green
        ) {
          send(.compareWithBaseButtonTapped)
        }
        .staggeredAppear(index: 1, baseDelay: 0.1, duration: 0.4)
      }
    }
  }
}

// MARK: - Previews

#if DEBUG
#Preview("With Base") {
  HomeView(
    store: Store(initialState: HomeFeature.State(
      designSystemBase: Shared(wrappedValue: DesignSystemBase(
        fileName: "aperture-tokens-v2.1.0.json",
        bookmarkData: nil,
        metadata: TokenMetadata(
          exportedAt: "2026-01-28 14:30:45",
          timestamp: 1737982245000,
          version: "2.1.0",
          generator: "ApertureExporter Plugin"
        ),
        tokens: PreviewData.rootNodes
      ), .designSystemBase)
    )) {
      HomeFeature()
    }
  )
  .frame(width: UIConstants.Size.windowMinWidth, height: UIConstants.Size.windowMinHeight)
}

#Preview("Empty") {
  HomeView(
    store: Store(initialState: .initial) {
      HomeFeature()
    }
  )
  .frame(width: UIConstants.Size.windowMinWidth, height: UIConstants.Size.windowMinHeight)
}
#endif
