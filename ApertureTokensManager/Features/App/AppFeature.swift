import ComposableArchitecture
import Foundation
import Sharing

@Reducer
struct AppFeature {
  
  enum Tab: Equatable, Hashable, CaseIterable {
    case home
    case importer
    case compare
    case analysis
    case graph

    var index: Int {
      switch self {
      case .home: 1
      case .importer: 2
      case .compare: 3
      case .analysis: 4
      case .graph: 5
      }
    }

    init?(index: Int) {
      switch index {
      case 1: self = .home
      case 2: self = .importer
      case 3: self = .compare
      case 4: self = .analysis
      case 5: self = .graph
      default: return nil
      }
    }
  }
  
  @ObservableState
  struct State: Equatable {
    var selectedTab: Tab = .home
    var home: HomeFeature.State = .initial
    var importer: ImportFeature.State = .initial
    var compare: CompareFeature.State = .initial
    var analysis: AnalysisFeature.State = .initial
    var graph: GraphFeature.State = .initial

    // Filters (shared for menu access)
    @Shared(.tokenFilters) var tokenFilters: TokenFilters
    
    // Onboarding state (to check first launch)
    @Shared(.onboardingState) var onboardingState: OnboardingState
    
    // Presentations
    @Presents var settings: SettingsFeature.State?
    @Presents var tutorial: TutorialFeature.State?
    
    // Computed for menu state
    var canExport: Bool {
      importer.isFileLoaded
    }
  }
  
  enum Action: BindableAction {
    case binding(BindingAction<State>)
    case tabSelected(Tab)
    case analysis(AnalysisFeature.Action)
    case compare(CompareFeature.Action)
    case graph(GraphFeature.Action)
    case home(HomeFeature.Action)
    case importer(ImportFeature.Action)
    case onAppear
    case settings(PresentationAction<SettingsFeature.Action>)
    case settingsButtonTapped
    case tutorial(PresentationAction<TutorialFeature.Action>)
    case tutorialButtonTapped
    
    // Menu actions
    case menu(Menu)
    
    enum Menu {
      case importTokens
      case exportToXcode
      case toggleFilterHash
      case toggleFilterHover
      case toggleFilterUtility
    }
  }
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    Scope(state: \.analysis, action: \.analysis) { AnalysisFeature() }
    Scope(state: \.compare, action: \.compare) { CompareFeature() }
    Scope(state: \.graph, action: \.graph) { GraphFeature() }
    Scope(state: \.home, action: \.home) { HomeFeature() }
    Scope(state: \.importer, action: \.importer) { ImportFeature() }
    Reduce { state, action in
      switch action {
      case .binding:
        return .none
        
      case .tabSelected(let tab):
        state.selectedTab = tab
        return .none
        
      // MARK: - Menu Actions
      case .menu(.importTokens):
        state.selectedTab = .importer
        return .send(.importer(.view(.selectFileTapped)))
        
      case .menu(.exportToXcode):
        return .send(.importer(.view(.exportButtonTapped)))
        
      case .menu(.toggleFilterHash):
        state.$tokenFilters.withLock { $0.excludeTokensStartingWithHash.toggle() }
        return .none
        
      case .menu(.toggleFilterHover):
        state.$tokenFilters.withLock { $0.excludeTokensEndingWithHover.toggle() }
        return .none
        
      case .menu(.toggleFilterUtility):
        state.$tokenFilters.withLock { $0.excludeUtilityGroup.toggle() }
        return .none
        
      // MARK: - Lifecycle
      case .onAppear:
        // Show tutorial on first launch
        if !state.onboardingState.hasCompletedTutorial {
          state.tutorial = .initial
        }
        return .none
        
      // MARK: - Tutorial
      case .tutorialButtonTapped:
        state.tutorial = .initial
        return .none
      case .tutorial(.presented(.delegate(.completed))):
        state.tutorial = nil
        return .none
      case .tutorial(.presented(.delegate(.dismissed))):
        state.tutorial = nil
        return .none
      case .tutorial:
        return .none
        
      // MARK: - Settings
      case .settingsButtonTapped:
        state.settings = .initial
        return .none
      case .settings(.presented(.delegate(.openTutorial))):
        state.settings = nil
        state.tutorial = .initial
        return .none
      case .settings:
        return .none
        
      // MARK: - Home Delegate Actions
      case .home(.delegate(.compareWithBase(let tokens, let metadata))):
        state.selectedTab = .compare
        return .send(.compare(.internal(.setBaseAsOldFile(tokens: tokens, metadata: metadata))))
      case .home(.delegate(.goToImport)):
        state.selectedTab = .importer
        return .none
      case .home(.delegate(.openImportHistory(let entry))):
        state.selectedTab = .importer
        return .send(.importer(.internal(.loadFromHistoryEntry(entry))))
      case .home(.delegate(.openComparisonHistory(let entry))):
        state.selectedTab = .compare
        return .send(.compare(.internal(.loadFromHistoryEntry(entry))))
      case .home:
        return .none
        
      // MARK: - Import Delegate Actions
      case .importer(.delegate(.baseUpdated)):
        // Could trigger dashboard refresh if needed
        return .none
      case .importer:
        return .none
        
      // MARK: - Graph Actions
      case .graph:
        return .none

      // MARK: - Analysis Actions
      case .analysis:
        return .none
        
      // MARK: - Compare Actions
      case .compare:
        return .none
      }
    }
    .ifLet(\.$settings, action: \.settings) {
      SettingsFeature()
    }
    .ifLet(\.$tutorial, action: \.tutorial) {
      TutorialFeature()
    }
  }
}
