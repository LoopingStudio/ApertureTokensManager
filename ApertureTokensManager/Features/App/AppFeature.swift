import ComposableArchitecture
import Foundation

@Reducer
struct AppFeature {
  
  enum Tab: Equatable, Hashable {
    case home
    case importer
    case compare
    case analysis
  }
  
  @ObservableState
  struct State: Equatable {
    var selectedTab: Tab = .home
    var home: HomeFeature.State = .initial
    var importer: ImportFeature.State = .initial
    var compare: CompareFeature.State = .initial
    var analysis: AnalysisFeature.State = .initial
    
    // Settings presentation
    @Presents var settings: SettingsFeature.State?
  }
  
  enum Action {
    case tabSelected(Tab)
    case analysis(AnalysisFeature.Action)
    case compare(CompareFeature.Action)
    case home(HomeFeature.Action)
    case importer(ImportFeature.Action)
    case settings(PresentationAction<SettingsFeature.Action>)
    case settingsButtonTapped
  }
  
  var body: some ReducerOf<Self> {
    Scope(state: \.analysis, action: \.analysis) { AnalysisFeature() }
    Scope(state: \.compare, action: \.compare) { CompareFeature() }
    Scope(state: \.home, action: \.home) { HomeFeature() }
    Scope(state: \.importer, action: \.importer) { ImportFeature() }
    Reduce { state, action in
      switch action {
      case .tabSelected(let tab):
        state.selectedTab = tab
        return .none
      // MARK: - Settings
      case .settingsButtonTapped:
        state.settings = .initial
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
  }
}
