import ComposableArchitecture
import Foundation
import SwiftUI

extension ImportFeature {
  func handleViewAction(_ action: Action.View, state: inout State) -> EffectOf<Self> {
    switch action {
    case .fileDroppedWithProvider(let provider):
      return .run { send in
        await send(.internal(.fileLoadingStarted))
        if let url = await fileClient.handleFileDrop(provider) {
          await send(.internal(.loadFile(url)))
        } else {
          await send(.internal(.fileLoadingFailed("Impossible de lire le fichier")))
        }
      }
    case .resetFile:
      let history = state.importHistory
      state = .initial
      state.importHistory = history
      return .none
      
    case .onAppear:
      return .merge(
        .send(.analytics(.screenViewed)),
        .run { send in
          let history = await historyClient.getImportHistory()
          await send(.internal(.historyLoaded(history)))
        }
      )
      
    case .historyEntryTapped(let entry):
      return .merge(
        .send(.analytics(.historyEntryTapped(fileName: entry.fileName))),
        .send(.internal(.loadFromHistoryEntry(entry)))
      )
      
    case .removeHistoryEntry(let id):
      return .merge(
        .send(.analytics(.historyEntryRemoved)),
        .run { send in
          await historyClient.removeImportEntry(id)
          let history = await historyClient.getImportHistory()
          await send(.internal(.historyLoaded(history)))
        }
      )
      
    case .clearHistory:
      return .merge(
        .send(.analytics(.historyCleared)),
        .run { send in
          await historyClient.clearImportHistory()
          await send(.internal(.historyLoaded([])))
        }
      )
      
    case .setAsBaseButtonTapped:
      // Si une base existe déjà, demander confirmation
      if state.designSystemBase != nil {
        state.showSetAsBaseConfirmation = true
        return .none
      }
      // Sinon, définir directement
      return setAsBase(state: &state)
      
    case .confirmSetAsBase:
      state.showSetAsBaseConfirmation = false
      return setAsBase(state: &state)
      
    case .dismissSetAsBaseConfirmation:
      state.showSetAsBaseConfirmation = false
      return .none
      
    case .toggleNode(let id):
      updateNodeRecursively(nodes: &state.rootNodes, targetId: id)
      // Mettre à jour selectedNode si c'est le node toggleé ou un de ses descendants
      if let selectedNode = state.selectedNode {
        state.selectedNode = findNode(by: selectedNode.id, in: state.rootNodes)
      }
      // Log le toggle avec le path du node
      if let node = findNode(by: id, in: state.rootNodes) {
        return .send(.analytics(.nodeToggled(path: node.path ?? node.name, enabled: node.isEnabled)))
      }
      return .none
    case .selectNode(let node):
      state.selectedNode = node
      return .none
    case .expandNode(let id):
      state.expandedNodes.insert(id)
      return .none
    case .collapseNode(let id):
      state.expandedNodes.remove(id)
      return .none
    case .selectFileTapped:
      return .run { send in
        await send(.internal(.fileLoadingStarted))
        guard let url = try? await fileClient.pickFile() else { 
          await send(.internal(.fileLoadingFailed("Aucun fichier sélectionné")))
          return 
        }
        await send(.internal(.loadFile(url)))
      }
    case .exportButtonTapped:
      let tokenCount = TokenHelpers.countLeafTokens(state.rootNodes)
      return .run { [nodesToSave = state.rootNodes] send in
        try await exportClient.exportDesignSystem(nodesToSave)
        await send(.analytics(.exportCompleted(tokenCount: tokenCount)))
      } catch: { error, send in
        await send(.analytics(.exportFailed(error: error.localizedDescription)))
      }
    case .keyPressed(let key):
      switch key {
      case .upArrow:
        navigateInDirection(.up, state: &state)
      case .downArrow:
        navigateInDirection(.down, state: &state)
      case .leftArrow:
        if let selectedNode = state.selectedNode {
          if !state.expandedNodes.contains(selectedNode.id) || selectedNode.children?.isEmpty != false {
            navigateToParent(state: &state)
          } else {
            state.expandedNodes.remove(selectedNode.id)
          }
        }
      case .rightArrow:
        if let selectedNode = state.selectedNode, let children = selectedNode.children, !children.isEmpty {
          state.expandedNodes.insert(selectedNode.id)
        }
      default: break
      }
      return .none
    }
  }

  private enum NavigationDirection {
    case up, down
  }

  private func navigateInDirection(_ direction: NavigationDirection, state: inout State) {
    guard !state.allNodes.isEmpty else { return }
    
    let visibleNodes = getVisibleNodes(state: state)
    
    if let currentNode = state.selectedNode {
      if let currentIndex = visibleNodes.firstIndex(where: { $0.id == currentNode.id }) {
        var newIndex: Int
        switch direction {
        case .up:
          newIndex = currentIndex > 0 ? currentIndex - 1 : visibleNodes.count - 1
        case .down:
          newIndex = currentIndex < visibleNodes.count - 1 ? currentIndex + 1 : 0
        }
        state.selectedNode = visibleNodes[newIndex]
      }
    } else if !visibleNodes.isEmpty {
      state.selectedNode = visibleNodes[0]
    }
  }
  
  private func getVisibleNodes(state: State) -> [TokenNode] {
    var visibleNodes: [TokenNode] = []
    
    func addVisibleNodesRecursively(_ nodes: [TokenNode]) {
      for node in nodes {
        visibleNodes.append(node)
        if state.expandedNodes.contains(node.id), let children = node.children {
          addVisibleNodesRecursively(children)
        }
      }
    }
    
    addVisibleNodesRecursively(state.rootNodes)
    return visibleNodes
  }
  
  private func navigateToParent(state: inout State) {
    guard
      let selectedNode = state.selectedNode,
      let parentNode = findParentNode(selectedNodeId: selectedNode.id, in: state.rootNodes)
    else { return }
    state.selectedNode = parentNode
  }
  
  private func findParentNode(selectedNodeId: TokenNode.ID, in nodes: [TokenNode]) -> TokenNode? {
    for node in nodes {
      if let children = node.children {
        // Vérifier si l'un des enfants directs est le nœud sélectionné
        if children.contains(where: { $0.id == selectedNodeId }) {
          return node
        }
        // Rechercher récursivement dans les enfants
        if let parent = findParentNode(selectedNodeId: selectedNodeId, in: children) {
          return parent
        }
      }
    }
    return nil
  }

  // Helper de mutation in-place pour les structs récursives
  private func updateNodeRecursively(nodes: inout [TokenNode], targetId: TokenNode.ID) {
    for i in 0..<nodes.count {
      if nodes[i].id == targetId {
        let newState = !nodes[i].isEnabled
        nodes[i].toggleRecursively(newState)
        return
      }
      if nodes[i].children != nil {
        updateNodeRecursively(nodes: &nodes[i].children!, targetId: targetId)
      }
    }
  }
  
  // Helper pour retrouver un node par son ID dans l'arbre
  private func findNode(by id: TokenNode.ID, in nodes: [TokenNode]) -> TokenNode? {
    for node in nodes {
      if node.id == id {
        return node
      }
      if let children = node.children, let found = findNode(by: id, in: children) {
        return found
      }
    }
    return nil
  }
  
  // Helper pour définir la base
  private func setAsBase(state: inout State) -> Effect<Action> {
    guard let metadata = state.metadata else { return .none }
    let fileName = state.currentFileURL?.lastPathComponent ?? "Unknown"
    let bookmarkData = state.currentFileURL?.securityScopedBookmark()
    state.$designSystemBase.withLock {
      $0 = DesignSystemBase(
        fileName: fileName,
        bookmarkData: bookmarkData,
        metadata: metadata,
        tokens: state.rootNodes
      )
    }
    return .merge(
      .send(.analytics(.setAsBaseTapped(fileName: fileName))),
      .send(.delegate(.baseUpdated))
    )
  }
}
