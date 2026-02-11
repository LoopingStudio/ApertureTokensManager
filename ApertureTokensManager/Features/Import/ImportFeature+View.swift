import SwiftUI
import ComposableArchitecture
import UniformTypeIdentifiers

@ViewAction(for: ImportFeature.self)
struct ImportView: View {
  @Bindable var store: StoreOf<ImportFeature>
  @FocusState private var isSearchFocused: Bool

  var body: some View {
    VStack(spacing: 0) {
      header
      if store.isFileLoaded {
        contentView
      } else {
        fileSelectionArea
      }
    }
    .searchFocusShortcut($isSearchFocused)
    .alert("Remplacer la base actuelle ?", isPresented: $store.showSetAsBaseConfirmation) {
      Button("Annuler", role: .cancel) {
        send(.dismissSetAsBaseConfirmation)
      }
      Button("Remplacer", role: .destructive) {
        send(.confirmSetAsBase)
      }
    } message: {
      Text("Une base de design system existe déjà (\(store.designSystemBase?.fileName ?? "")). Voulez-vous la remplacer par l'import actuel ?")
    }
  }

  private var header: some View {
    VStack(spacing: 12) {
      HStack {
        Text("Aperture Tokens Viewer")
          .font(.title)
          .fontWeight(.bold)
        
        Spacer()

        if store.isFileLoaded {
          Button("Nouvel Import") { send(.resetFile) }
            .buttonStyle(.adaptiveGlass())
            .controlSize(.small)
          
          setAsBaseButton
          
          Button("Exporter Design System") {
            send(.exportButtonTapped)
          }
          .buttonStyle(.adaptiveGlassProminent)
          .controlSize(.small)
        }
      }
      
      if store.isFileLoaded {
        HStack {
          Text("Filtres d'export:")
            .font(.caption)
            .foregroundStyle(.secondary)
          
          Toggle("Exclure tokens commençant par #", isOn: $store.filters.excludeTokensStartingWithHash)
            .font(.caption)
            .controlSize(.mini)
          
          Toggle("Exclure tokens finissant par _hover", isOn: $store.filters.excludeTokensEndingWithHover)
            .font(.caption)
            .controlSize(.mini)
          
          Toggle("Exclure groupe Utility", isOn: $store.filters.excludeUtilityGroup)
            .font(.caption)
            .controlSize(.mini)
          
          Spacer()
        }
        .padding(.top, 4)
      }
      
      if let errorMessage = store.errorMessage {
        Text(errorMessage)
          .foregroundStyle(.red)
          .font(.caption)
      }
      
      Divider()
    }
    .padding()
  }
  
  // MARK: - Set As Base Button
  
  private var isCurrentImportTheBase: Bool {
    guard let baseMetadata = store.designSystemBase?.metadata,
          let currentMetadata = store.metadata else {
      return false
    }
    return baseMetadata == currentMetadata
  }
  
  @ViewBuilder
  private var setAsBaseButton: some View {
    if isCurrentImportTheBase {
      // L'import actuel est déjà la base - afficher un indicateur
      HStack(spacing: 4) {
        Image(systemName: "checkmark.seal.fill")
          .foregroundStyle(.green)
        Text("Base actuelle")
          .foregroundStyle(.secondary)
      }
      .font(.callout)
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .background(
        Capsule()
          .fill(Color.green.opacity(0.1))
          .overlay(
            Capsule()
              .strokeBorder(Color.green.opacity(0.3), lineWidth: 1)
          )
      )
    } else {
      // Bouton normal pour définir comme base
      Button {
        send(.setAsBaseButtonTapped)
      } label: {
        Label("Définir comme base", systemImage: "checkmark.seal")
      }
      .buttonStyle(.adaptiveGlass(.regular.tint(.green)))
      .controlSize(.small)
    }
  }
  
  private var fileSelectionArea: some View {
    VStack(spacing: 24) {
      DropZone(
        title: "Fichier de Tokens",
        subtitle: "Glissez votre fichier JSON ici ou cliquez pour le sélectionner",
        isLoaded: store.isFileLoaded,
        isLoading: store.isLoading,
        hasError: store.loadingError,
        errorMessage: store.errorMessage,
        primaryColor: .purple,
        onDrop: { providers in
          guard let provider = providers.first else { return false }
          send(.fileDroppedWithProvider(provider))
          return true
        },
        onSelectFile: { send(.selectFileTapped) },
        metadata: store.metadata
      )
      
      if !store.importHistory.isEmpty {
        ImportHistoryView(
          history: store.importHistory,
          onEntryTapped: { send(.historyEntryTapped($0)) },
          onRemove: { send(.removeHistoryEntry($0)) },
          onClear: { send(.clearHistory) }
        )
        .frame(maxWidth: 500)
      }
    }
    .padding()
    .frame(maxHeight: .infinity)
    .onAppear { send(.onAppear) }
  }

  private var contentView: some View {
    HSplitView {
      nodesView
        .frame(minWidth: 250, maxHeight: .infinity)
      
      rightView
        .frame(minWidth: 400, idealWidth: 600, maxHeight: .infinity)
    }
  }

  /// Données filtrées pour la recherche
  private var filteredData: (nodes: [TokenNode], autoExpandedIds: Set<TokenNode.ID>) {
    guard !store.searchText.isEmpty else {
      return (store.rootNodes, [])
    }
    return TokenTreeSearchHelper.filterNodes(store.rootNodes, searchText: store.searchText)
  }
  
  /// Nombre de tokens filtrés
  private var filteredTokenCount: Int {
    TokenTreeSearchHelper.countFilteredTokens(filteredData.nodes)
  }
  
  /// Nombre total de tokens
  private var totalTokenCount: Int {
    TokenHelpers.countLeafTokens(store.rootNodes)
  }
  
  private var nodesView: some View {
    VStack(spacing: 0) {
      SearchField(
        text: $store.searchText,
        resultCount: store.searchText.isEmpty ? nil : filteredTokenCount,
        totalCount: store.searchText.isEmpty ? nil : totalTokenCount,
        isFocused: $isSearchFocused
      )
      
      Divider()
      
      TokenTree(
        nodes: store.rootNodes,
        selectedNodeId: store.selectedNode?.id,
        expandedNodes: store.expandedNodes,
        isEditable: true,
        searchText: store.searchText,
        onSelect: { send(.selectNode($0)) },
        onExpand: { nodeId in
          if store.expandedNodes.contains(nodeId) {
            send(.collapseNode(nodeId))
          } else {
            send(.expandNode(nodeId))
          }
        },
        onToggleEnabled: { send(.toggleNode($0)) }
      )
      .background(Color(nsColor: .controlBackgroundColor))
      .tokenTreeKeyboardNavigation(
        nodes: store.rootNodes,
        expandedNodes: store.expandedNodes,
        selectedNodeId: store.selectedNode?.id,
        onSelect: { send(.selectNode($0)) },
        onExpand: { send(.expandNode($0)) },
        onCollapse: { send(.collapseNode($0)) }
      )
    }
  }

  @ViewBuilder
  private var rightView: some View {
    if let selectedNode = store.selectedNode {
      TokenDetailView(node: selectedNode)
    } else {
      ContentUnavailableView("Sélectionnez un token", systemImage: "paintbrush")
    }
  }
}
// MARK: - Previews

#if DEBUG
#Preview("Empty State") {
  ImportView(
    store: Store(initialState: .initial) {
      ImportFeature()
    }
  )
  .frame(width: 800, height: 600)
}

#Preview("With File Loaded") {
  ImportView(
    store: Store(initialState: ImportFeature.State(
      rootNodes: PreviewData.rootNodes,
      isFileLoaded: true,
      isLoading: false,
      loadingError: false,
      errorMessage: nil,
      metadata: PreviewData.metadata,
      selectedNode: PreviewData.singleToken,
      expandedNodes: [PreviewData.colorsGroup.id, PreviewData.brandGroup.id],
      allNodes: [],
      currentFileURL: nil
    )) {
      ImportFeature()
    }
  )
  .frame(width: 900, height: 600)
}

#Preview("Loading State") {
  ImportView(
    store: Store(initialState: ImportFeature.State(
      rootNodes: [],
      isFileLoaded: false,
      isLoading: true,
      loadingError: false,
      errorMessage: nil,
      metadata: nil,
      selectedNode: nil,
      expandedNodes: [],
      allNodes: [],
      currentFileURL: nil
    )) {
      ImportFeature()
    }
  )
  .frame(width: 800, height: 600)
}
#endif

