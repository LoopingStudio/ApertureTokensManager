import ComposableArchitecture
import Foundation
import SwiftUI

@Reducer
public struct CompareFeature: Sendable {
  @Dependency(\.comparisonClient) var comparisonClient
  @Dependency(\.exportClient) var exportClient
  @Dependency(\.fileClient) var fileClient
  @Dependency(\.historyClient) var historyClient
  @Dependency(\.loggingClient) var loggingClient
  @Dependency(\.suggestionClient) var suggestionClient

  // MARK: - File State
  
  @ObservableState
  public struct FileState: Equatable {
    var tokens: [TokenNode]?
    var metadata: TokenMetadata?
    var url: URL?
    var isLoaded: Bool = false
    var isLoading: Bool = false
    var isFromBase: Bool = false
    
    var fileName: String? {
      url?.lastPathComponent
    }
    
    static var empty: Self { .init() }
    
    mutating func reset() {
      self = .empty
    }
  }

  // MARK: - State
  
  @ObservableState
  public struct State: Equatable {
    var oldFile: FileState = .empty
    var newFile: FileState = .empty
    var changes: ComparisonChanges?
    var loadingError: String?
    var selectedChange: TokenModification?
    
    // History
    var comparisonHistory: [ComparisonHistoryEntry] = []
    
    // UI State
    var selectedTab: ComparisonTab = .overview
    
    public static var initial: Self {
      .init(
        oldFile: .empty,
        newFile: .empty,
        changes: nil,
        loadingError: nil,
        selectedChange: nil,
        selectedTab: .overview
      )
    }
  }

  // MARK: - File Type
  
  public enum FileType: Sendable {
    case old
    case new
  }

  // MARK: - Comparison Tab
  
  public enum ComparisonTab: String, CaseIterable, Equatable, Sendable {
    case overview = "Vue d'ensemble"
    case added = "Ajoutés"
    case removed = "Supprimés"  
    case modified = "Modifiés"
  }

  // MARK: - Actions
  
  @CasePathable
  public enum Action: BindableAction, ViewAction, Equatable, Sendable {
    case analytics(Analytics)
    case binding(BindingAction<State>)
    case `internal`(Internal)
    case view(View)

    @CasePathable
    public enum Analytics: Sendable, Equatable {
      case comparisonCompleted(added: Int, removed: Int, modified: Int)
      case exportToNotionCompleted
      case exportToNotionFailed(error: String)
      case fileLoaded(slot: String, fileName: String)
      case fileLoadFailed(error: String)
      case historyCleared
      case historyEntryTapped(oldFile: String, newFile: String)
      case screenViewed
      case suggestionAccepted(removedPath: String, suggestedPath: String)
      case suggestionRejected(removedPath: String)
      case tabChanged(tab: String)
    }

    @CasePathable
    public enum Internal: Sendable, Equatable {
      case comparisonCompleted(ComparisonChanges)
      case exportLoaded(FileType, TokenExport, URL)
      case historyLoaded([ComparisonHistoryEntry])
      case loadFile(FileType, URL)
      case loadFromHistoryEntry(ComparisonHistoryEntry)
      case loadingFailed(String)
      case performComparison
      case setBaseAsOldFile(tokens: [TokenNode], metadata: TokenMetadata)
      case suggestionsComputed([AutoSuggestion])
    }

    @CasePathable
    public enum View: Sendable, Equatable {
      case acceptAutoSuggestion(removedTokenPath: String)
      case clearHistory
      case compareButtonTapped
      case exportToNotionTapped
      case fileDroppedWithProvider(FileType, NSItemProvider)
      case historyEntryTapped(ComparisonHistoryEntry)
      case onAppear
      case rejectAutoSuggestion(removedTokenPath: String)
      case removeFile(FileType)
      case removeHistoryEntry(UUID)
      case resetComparison
      case selectChange(TokenModification?)
      case selectFileTapped(FileType)
      case suggestReplacement(removedTokenPath: String, replacementTokenPath: String?)
      case switchFiles
      case tabTapped(ComparisonTab)
    }
  }

  // MARK: - Body
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .analytics(let action): handleAnalyticsAction(action, state: &state)
      case .binding: .none
      case .internal(let action): handleInternalAction(action, state: &state)
      case .view(let action): handleViewAction(action, state: &state)
      }
    }
  }
}
