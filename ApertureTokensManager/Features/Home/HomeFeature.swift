import AppKit
import ComposableArchitecture
import Foundation

@Reducer
struct HomeFeature: Sendable {
  @Dependency(\.exportClient) var exportClient
  @Dependency(\.fileClient) var fileClient
  @Dependency(\.loggingClient) var loggingClient

  // MARK: - State

  @ObservableState
  struct State: Equatable {
    @Shared(.designSystemBase) var designSystemBase: DesignSystemBase?
    @Shared(.tokenFilters) var filters: TokenFilters
    @Shared(.importHistory) var importHistory: [ImportHistoryEntry]
    @Shared(.comparisonHistory) var comparisonHistory: [ComparisonHistoryEntry]
    
    // UI State
    var isExportPopoverPresented: Bool = false
    var historyFilter: HistoryFilter = .all
    
    // Token Browser Presentation
    @Presents var tokenBrowser: TokenBrowserFeature.State?
    
    // Computed
    var unifiedHistory: [UnifiedHistoryItem] {
      let all = UnifiedHistoryItem.merge(imports: importHistory, comparisons: comparisonHistory)
      switch historyFilter {
      case .all: return all
      case .imports: return all.filter { if case .imported = $0 { return true }; return false }
      case .comparisons: return all.filter { if case .comparison = $0 { return true }; return false }
      }
    }
    
    static var initial: State { .init() }
  }
  
  // MARK: - History Filter
  
  enum HistoryFilter: String, CaseIterable, Equatable, Sendable {
    case all = "Tout"
    case imports = "Imports"
    case comparisons = "Comparaisons"
  }

  // MARK: - Action
  
  @CasePathable
  enum Action: BindableAction, ViewAction, Equatable, Sendable {
    case analytics(Analytics)
    case binding(BindingAction<State>)
    case delegate(Delegate)
    case `internal`(Internal)
    case tokenBrowser(PresentationAction<TokenBrowserFeature.Action>)
    case view(View)

    @CasePathable
    enum Analytics: Equatable, Sendable {
      case baseCleared
      case compareWithBaseTapped
      case exportCompleted(tokenCount: Int)
      case exportFailed(error: String)
      case historyFilterChanged(filter: String)
      case historyItemTapped(type: String, fileName: String)
      case openFileTapped
      case tokenBrowserOpened
    }

    @CasePathable
    enum Delegate: Equatable, Sendable {
      case compareWithBase(tokens: [TokenNode], metadata: TokenMetadata)
      case goToImport
      case openImportHistory(ImportHistoryEntry)
      case openComparisonHistory(ComparisonHistoryEntry)
    }

    @CasePathable
    enum Internal: Equatable, Sendable {
    }

    @CasePathable
    enum View: Equatable, Sendable {
      case clearBaseButtonTapped
      case compareWithBaseButtonTapped
      case confirmExportButtonTapped
      case dismissExportPopover
      case exportButtonTapped
      case goToImportTapped
      case historyFilterChanged(HistoryFilter)
      case historyItemTapped(UnifiedHistoryItem)
      case openFileButtonTapped
      case tokenCountTapped
    }
  }

  // MARK: - Body

  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .analytics(let action): handleAnalyticsAction(action, state: &state)
      case .binding: .none
      case .delegate: .none
      case .internal: .none
      case .tokenBrowser: .none
      case .view(let action): handleViewAction(action, state: &state)
      }
    }
    .ifLet(\.$tokenBrowser, action: \.tokenBrowser) { TokenBrowserFeature() }
  }
}
