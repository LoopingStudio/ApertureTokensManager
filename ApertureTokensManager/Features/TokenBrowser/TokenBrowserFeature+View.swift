import SwiftUI
import ComposableArchitecture

@ViewAction(for: TokenBrowserFeature.self)
struct TokenBrowserView: View {
  @Bindable var store: StoreOf<TokenBrowserFeature>
  @Environment(\.dismiss) private var dismiss
  @FocusState private var isSearchFocused: Bool
  
  var body: some View {
    VStack(spacing: 0) {
      header
      Divider()
      browserContent
    }
    .frame(minWidth: UIConstants.Size.windowMinWidth, idealWidth: UIConstants.Size.windowDefaultWidth, minHeight: UIConstants.Size.windowMinHeight, idealHeight: UIConstants.Size.windowMinHeight)
    .searchFocusShortcut($isSearchFocused)
  }
  
  private var header: some View {
    HStack {
      Image(systemName: "paintpalette.fill")
        .font(.title2)
        .foregroundStyle(.purple)
      
      VStack(alignment: .leading, spacing: UIConstants.Spacing.extraSmall) {
        Text("Tokens du Design System")
          .font(.title3)
          .fontWeight(.semibold)
        
        HStack(spacing: UIConstants.Spacing.medium) {
          Text("Version \(store.metadata.version)")
            .font(.caption)
            .foregroundStyle(.secondary)
          
          Text("•")
            .foregroundStyle(.tertiary)
          
          Text("\(store.tokenCount) tokens")
            .font(.caption)
            .foregroundStyle(.purple)
        }
      }
      
      Spacer()
      
      Button {
        dismiss()
      } label: {
        Image(systemName: "xmark.circle.fill")
          .font(.title2)
          .foregroundStyle(.secondary)
      }
      .buttonStyle(.plain)
      .keyboardShortcut(.escape, modifiers: [])
    }
    .padding()
  }
  
  private var browserContent: some View {
    HSplitView {
      tokenListView
        .frame(minWidth: UIConstants.Size.splitViewMinWidth, maxHeight: .infinity)
      
      tokenDetailView
        .frame(minWidth: UIConstants.Size.previewWidth, idealWidth: UIConstants.Size.splitViewIdealWidth, maxHeight: .infinity)
    }
  }
  
  /// Données filtrées pour la recherche
  private var filteredData: (nodes: [TokenNode], autoExpandedIds: Set<TokenNode.ID>) {
    guard !store.searchText.isEmpty else {
      return (store.tokens, [])
    }
    return TokenTreeSearchHelper.filterNodes(store.tokens, searchText: store.searchText)
  }
  
  /// Nombre de tokens filtrés
  private var filteredTokenCount: Int {
    TokenTreeSearchHelper.countFilteredTokens(filteredData.nodes)
  }
  
  private var tokenListView: some View {
    VStack(spacing: 0) {
      SearchField(
        text: $store.searchText,
        resultCount: store.searchText.isEmpty ? nil : filteredTokenCount,
        totalCount: store.searchText.isEmpty ? nil : store.tokenCount,
        isFocused: $isSearchFocused
      )
      
      Divider()
      
      TokenTree(
        nodes: store.tokens,
        selectedNodeId: store.selectedNode?.id,
        expandedNodes: store.expandedNodes,
        isEditable: false,
        searchText: store.searchText,
        onSelect: { send(.selectNode($0)) },
        onExpand: { send(.toggleNode($0)) }
      )
      .background(Color(nsColor: .controlBackgroundColor))
      .tokenTreeKeyboardNavigation(
        nodes: store.tokens,
        expandedNodes: store.expandedNodes,
        selectedNodeId: store.selectedNode?.id,
        onSelect: { send(.selectNode($0)) },
        onExpand: { send(.toggleNode($0)) },
        onCollapse: { send(.toggleNode($0)) }
      )
    }
  }
  
  @ViewBuilder
  private var tokenDetailView: some View {
    if let selectedNode = store.selectedNode {
      TokenDetailView(node: selectedNode)
    } else {
      ContentUnavailableView(
        "Sélectionnez un token",
        systemImage: "paintbrush",
        description: Text("Choisissez un token dans la liste pour voir ses détails")
      )
    }
  }
}

// MARK: - Previews

#if DEBUG
#Preview("Token Browser") {
  TokenBrowserView(
    store: Store(initialState: TokenBrowserFeature.State(
      tokens: PreviewData.rootNodes,
      metadata: PreviewData.metadata
    )) {
      TokenBrowserFeature()
    }
  )
  .frame(width: UIConstants.Size.windowMinWidth, height: UIConstants.Size.windowMinHeight)
}

#Preview("Token Browser - With Selection") {
  TokenBrowserView(
    store: Store(initialState: TokenBrowserFeature.State(
      tokens: PreviewData.rootNodes,
      metadata: PreviewData.metadata,
      selectedNode: PreviewData.singleToken,
      expandedNodes: [PreviewData.colorsGroup.id, PreviewData.brandGroup.id]
    )) {
      TokenBrowserFeature()
    }
  )
  .frame(width: UIConstants.Size.windowMinWidth, height: UIConstants.Size.windowMinHeight)
}
#endif
