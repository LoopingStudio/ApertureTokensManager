import ComposableArchitecture
import Foundation
import Sharing
import SwiftUI

@Reducer
public struct ImportFeature: Sendable {
  @Dependency(\.exportClient) var exportClient
  @Dependency(\.fileClient) var fileClient
  @Dependency(\.historyClient) var historyClient
  @Dependency(\.loggingClient) var loggingClient

  @ObservableState
  public struct State: Equatable {
    var rootNodes: [TokenNode]
    var originalRootNodes: [TokenNode]  // Tokens sans filtres appliqués
    var isFileLoaded: Bool
    var isLoading: Bool
    var loadingError: Bool
    var errorMessage: String?
    var metadata: TokenMetadata?
    var selectedNode: TokenNode?
    var expandedNodes: Set<TokenNode.ID> = []
    var currentFileURL: URL?
    var searchText: String = ""
    var showSetAsBaseConfirmation: Bool = false
    
    // History
    var importHistory: [ImportHistoryEntry] = []
    
    // Export filters (persisted)
    @Shared(.tokenFilters) var filters
    
    // Design System Base (persisted)
    @Shared(.designSystemBase) var designSystemBase: DesignSystemBase?
    
    public static var initial: Self {
      .init(
        rootNodes: [],
        originalRootNodes: [],
        isFileLoaded: false,
        isLoading: false,
        loadingError: false,
        errorMessage: nil,
        metadata: nil,
        selectedNode: nil,
        expandedNodes: [],
        currentFileURL: nil
      )
    }
  }

  @CasePathable
  public enum Action: BindableAction, ViewAction, Equatable, Sendable {
    case analytics(Analytics)
    case binding(BindingAction<State>)
    case delegate(Delegate)
    case `internal`(Internal)
    case view(View)
    
    @CasePathable
    public enum Analytics: Sendable, Equatable {
      case exportCompleted(tokenCount: Int)
      case exportFailed(error: String)
      case fileLoaded(fileName: String, tokenCount: Int)
      case fileLoadFailed(error: String)
      case historyCleared
      case historyEntryRemoved
      case historyEntryTapped(fileName: String)
      case nodeToggled(path: String, enabled: Bool)
      case screenViewed
      case setAsBaseTapped(fileName: String)
    }
    
    @CasePathable
    public enum Delegate: Sendable, Equatable {
      case baseUpdated
    }

    @CasePathable
    public enum Internal: Sendable, Equatable {
      case applyFilters
      case exportLoaded(TokenExport, URL)
      case fileLoadingFailed(String)
      case fileLoadingStarted
      case filtersChanged(TokenFilters)
      case historyLoaded([ImportHistoryEntry])
      case loadFile(URL)
      case loadFromHistoryEntry(ImportHistoryEntry)
      case observeFilters
    }

    @CasePathable
    public enum View: Sendable, Equatable {
      case clearHistory
      case collapseNode(TokenNode.ID)
      case expandNode(TokenNode.ID)
      case exportButtonTapped
      case fileDroppedWithProvider(NSItemProvider)
      case historyEntryTapped(ImportHistoryEntry)
      case keyPressed(KeyEquivalent)
      case onAppear
      case removeHistoryEntry(UUID)
      case resetFile
      case selectFileTapped
      case selectNode(TokenNode)
      case confirmSetAsBase
      case dismissSetAsBaseConfirmation
      case setAsBaseButtonTapped
      case toggleNode(TokenNode.ID)
    }
  }

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .analytics(let action): handleAnalyticsAction(action, state: &state)
      case .binding(let action): handleBindingAction(action, state: &state)
      case .delegate: .none
      case .internal(let action): handleInternalAction(action, state: &state)
      case .view(let action): handleViewAction(action, state: &state)
      }
    }
  }
}
