import ComposableArchitecture
import Foundation
import SwiftUI

@Reducer
public struct CompareFeature: Sendable {
  @Dependency(\.exportClient) var exportClient
  @Dependency(\.comparisonClient) var comparisonClient
  @Dependency(\.fileClient) var fileClient
  @Dependency(\.historyClient) var historyClient

  // MARK: - File State
  
  @ObservableState
  public struct FileState: Equatable {
    var tokens: [TokenNode]?
    var metadata: TokenMetadata?
    var url: URL?
    var isLoaded: Bool = false
    var isLoading: Bool = false
    
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
    case binding(BindingAction<State>)
    case `internal`(Internal)
    case view(View)

    @CasePathable
    public enum Internal: Sendable, Equatable {
      case comparisonCompleted(ComparisonChanges)
      case exportLoaded(FileType, TokenExport, URL)
      case loadFile(FileType, URL)
      case loadingFailed(String)
      case performComparison
      case historyLoaded([ComparisonHistoryEntry])
    }

    @CasePathable
    public enum View: Sendable, Equatable {
      case compareButtonTapped
      case exportToNotionTapped
      case fileDroppedWithProvider(FileType, NSItemProvider)
      case removeFile(FileType)
      case resetComparison
      case selectChange(TokenModification?)
      case selectFileTapped(FileType)
      case suggestReplacement(removedTokenPath: String, replacementTokenPath: String?)
      case switchFiles
      case tabTapped(ComparisonTab)
      case onAppear
      case historyEntryTapped(ComparisonHistoryEntry)
      case removeHistoryEntry(UUID)
      case clearHistory
    }
  }

  // MARK: - Body
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding: .none
      case .internal(let action): handleInternalAction(action, state: &state)
      case .view(let action): handleViewAction(action, state: &state)
      }
    }
  }
}
