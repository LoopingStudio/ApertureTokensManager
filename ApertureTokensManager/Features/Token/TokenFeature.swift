import ComposableArchitecture
import Foundation
import Sharing
import SwiftUI

@Reducer
public struct TokenFeature: Sendable {
  @Dependency(\.exportClient) var exportClient
  @Dependency(\.fileClient) var fileClient
  @Dependency(\.historyClient) var historyClient

  @ObservableState
  public struct State: Equatable {
    var rootNodes: [TokenNode]
    var isFileLoaded: Bool
    var isLoading: Bool
    var loadingError: Bool
    var errorMessage: String?
    var metadata: TokenMetadata?
    var selectedNode: TokenNode?
    var expandedNodes: Set<TokenNode.ID> = []
    var allNodes: [TokenNode] = []
    var currentFileURL: URL?
    
    // History
    var importHistory: [ImportHistoryEntry] = []
    
    // Export filters (persisted)
    @Shared(.tokenFilters) var filters
    
    // UI State
    var splitViewRatio: Double = 0.6

    public static var initial: Self {
      .init(
        rootNodes: [],
        isFileLoaded: false,
        isLoading: false,
        loadingError: false,
        errorMessage: nil,
        metadata: nil,
        selectedNode: nil,
        expandedNodes: [],
        allNodes: [],
        currentFileURL: nil,
        splitViewRatio: 0.6
      )
    }
  }

  @CasePathable
  public enum Action: BindableAction, ViewAction, Equatable, Sendable {
    case binding(BindingAction<State>)
    case `internal`(Internal)
    case view(View)

    @CasePathable
    public enum Internal: Sendable, Equatable {
      case loadFile(URL)
      case exportLoaded(TokenExport, URL)
      case fileLoadingStarted
      case fileLoadingFailed(String)
      case applyFilters
      case historyLoaded([ImportHistoryEntry])
      case filtersChanged(TokenFilters)
      case observeFilters
    }

    @CasePathable
    public enum View: Sendable, Equatable {
      case exportButtonTapped
      case fileDroppedWithProvider(NSItemProvider)
      case selectFileTapped
      case resetFile
      case selectNode(TokenNode)
      case toggleNode(TokenNode.ID)
      case expandNode(TokenNode.ID)
      case collapseNode(TokenNode.ID)
      case keyPressed(KeyEquivalent)
      case onAppear
      case historyEntryTapped(ImportHistoryEntry)
      case removeHistoryEntry(UUID)
      case clearHistory
    }
  }

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding(let action): handleBindingAction(action, state: &state)
      case .internal(let action): handleInternalAction(action, state: &state)
      case .view(let action): handleViewAction(action, state: &state)
      }
    }
  }
}
