import SwiftUI
import ComposableArchitecture

@ViewAction(for: TokenBrowserFeature.self)
struct TokenBrowserView: View {
  @Bindable var store: StoreOf<TokenBrowserFeature>
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    VStack(spacing: 0) {
      header
      Divider()
      browserContent
    }
    .frame(minWidth: 700, idealWidth: 900, minHeight: 500, idealHeight: 600)
  }
  
  private var header: some View {
    HStack {
      Image(systemName: "paintpalette.fill")
        .font(.title2)
        .foregroundStyle(.purple)
      
      VStack(alignment: .leading, spacing: 2) {
        Text("Tokens du Design System")
          .font(.title3)
          .fontWeight(.semibold)
        
        HStack(spacing: 8) {
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
        .frame(minWidth: 250, maxHeight: .infinity)
      
      tokenDetailView
        .frame(minWidth: 400, idealWidth: 600, maxHeight: .infinity)
    }
  }
  
  private var tokenListView: some View {
    VStack(spacing: 0) {
      // Search field
      HStack(spacing: 8) {
        Image(systemName: "magnifyingglass")
          .foregroundStyle(.secondary)
        TextField("Rechercher...", text: $store.searchText)
          .textFieldStyle(.plain)
        if !store.searchText.isEmpty {
          Button {
            store.searchText = ""
          } label: {
            Image(systemName: "xmark.circle.fill")
              .foregroundStyle(.secondary)
          }
          .buttonStyle(.plain)
        }
      }
      .padding(8)
      .background(Color(nsColor: .controlBackgroundColor))
      
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
  .frame(width: 800, height: 500)
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
  .frame(width: 800, height: 500)
}
#endif
