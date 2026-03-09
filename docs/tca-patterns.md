# Patterns TCA

## Structure complete d'un Reducer

```swift
@Reducer
public struct ImportFeature: Sendable {
  // 1. Dependencies (injection)
  @Dependency(\.exportClient) var exportClient
  @Dependency(\.fileClient) var fileClient
  @Dependency(\.loggingClient) var loggingClient

  // 2. State
  @ObservableState
  public struct State: Equatable {
    var rootNodes: [TokenNode] = []
    var isLoading: Bool = false
    @Shared(.tokenFilters) var filters

    public static var initial: Self { State() }
  }

  // 3. Actions (voir section dediee)
  @CasePathable
  public enum Action: BindableAction, ViewAction, Equatable, Sendable {
    case analytics(Analytics)
    case binding(BindingAction<State>)
    case delegate(Delegate)
    case `internal`(Internal)
    case view(View)
  }

  // 4. Body - routing vers les handlers
  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .analytics(let action): handleAnalyticsAction(action, state: &state)
      case .binding(let action): handleBindingAction(action, state: &state)
      case .delegate: .none  // Handled by parent
      case .internal(let action): handleInternalAction(action, state: &state)
      case .view(let action): handleViewAction(action, state: &state)
      }
    }
  }
}
```

### Conformances

| Protocole/Macro | Raison |
|-----------------|--------|
| `@Reducer` | Macro TCA qui genere la conformance au protocole Reducer |
| `Sendable` | Requis pour Swift Concurrency - garantit thread-safety |
| `@ObservableState` | Permet l'observation automatique du state dans SwiftUI |
| `Equatable` (State) | Requis pour la comparaison d'etat et l'optimisation des updates |
| `@CasePathable` | Genere les case paths pour le routing des actions |
| `BindableAction` | Permet `$store.property.sending(\.binding)` dans les vues |
| `ViewAction` | Permet `@ViewAction(for:)` macro sur les vues |

---

## Les 5 types d'actions

```swift
@CasePathable
public enum Action: BindableAction, ViewAction, Equatable, Sendable {
  case analytics(Analytics)           // Metriques & telemetry
  case binding(BindingAction<State>)  // Bindings SwiftUI
  case delegate(Delegate)             // Communication vers le parent
  case `internal`(Internal)           // Effets internes & reactions
  case view(View)                     // Interactions UI utilisateur
}
```

### 1. `analytics` - Metriques (non-bloquant)
```swift
enum Analytics: Sendable, Equatable {
  case exportCompleted(tokenCount: Int)
  case fileLoaded(fileName: String, tokenCount: Int)
  case screenViewed
}

// Handler - jamais de mutation d'etat, uniquement logging
func handleAnalyticsAction(_ action: Action.Analytics, state: inout State) -> EffectOf<Self> {
  switch action {
  case .exportCompleted(let count):
    loggingClient.logUserAction(LogFeature.import, "export_completed", ["count": "\(count)"])
    return .none
  }
}
```

### 2. `binding` - Bindings SwiftUI
```swift
case binding(BindingAction<State>)

// Handler - generalement vide car gere par BindingReducer()
func handleBindingAction(_ action: BindingAction<State>, state: inout State) -> EffectOf<Self> {
  return .none
}

// Usage dans la vue
TextField("Search", text: $store.searchText.sending(\.binding))
```

### 3. `delegate` - Communication parent
```swift
enum Delegate: Sendable, Equatable {
  case baseUpdated
  case goToImport
  case compareWithBase(tokens: [TokenNode], metadata: TokenMetadata)
}

// Jamais gere dans la feature elle-meme - le parent intercepte
// Dans AppFeature:
case .home(.delegate(.goToImport)):
  state.selectedTab = .importer
  return .none
```

### 4. `internal` - Effets et reactions
```swift
enum Internal: Sendable, Equatable {
  case fileLoadingStarted
  case fileLoadingFailed(String)
  case loadFile(URL)
  case exportLoaded(TokenExport, URL)
  case filtersChanged(TokenFilters)
  case observeFilters
}

// Handler - peut muter l'etat et retourner des effets
func handleInternalAction(_ action: Action.Internal, state: inout State) -> EffectOf<Self> {
  switch action {
  case .fileLoadingStarted:
    state.isLoading = true
    return .none

  case .loadFile(let url):
    return .run { send in
      do {
        let export = try await fileClient.loadTokenExport(url)
        await send(.internal(.exportLoaded(export, url)))
      } catch {
        await send(.internal(.fileLoadingFailed(error.localizedDescription)))
      }
    }
  }
}
```

### 5. `view` - Interactions UI
```swift
enum View: Sendable, Equatable {
  case selectFileTapped
  case exportButtonTapped
  case toggleNode(TokenNode.ID)
  case onAppear
}

// Handler - declenche souvent des actions internal
func handleViewAction(_ action: Action.View, state: inout State) -> EffectOf<Self> {
  switch action {
  case .selectFileTapped:
    return .run { send in
      await send(.internal(.fileLoadingStarted))
      guard let url = try? await fileClient.pickFile() else { return }
      await send(.internal(.loadFile(url)))
    }

  case .exportButtonTapped:
    return .run { [nodes = state.rootNodes] send in
      try await exportClient.exportDesignSystem(nodes)
      await send(.analytics(.exportCompleted(tokenCount: nodes.count)))
    } catch: { error, send in
      await send(.analytics(.exportFailed(error: error.localizedDescription)))
    }
  }
}
```

---

## Patterns d'Effects

```swift
// Aucun effet
return .none

// Envoyer une action
return .send(.internal(.fileLoadingStarted))

// Travail async
return .run { send in
  let result = try await client.doWork()
  await send(.internal(.workCompleted(result)))
}

// Avec gestion d'erreur
return .run { send in
  try await client.doWork()
} catch: { error, send in
  await send(.internal(.workFailed(error.localizedDescription)))
}

// Plusieurs effets en parallele
return .merge(
  .send(.analytics(.screenViewed)),
  .run { send in await send(.internal(.loadData)) }
)

// Effets sequentiels
return .concatenate(
  .send(.internal(.step1)),
  .send(.internal(.step2))
)

// Observer un publisher
return .publisher {
  state.$filters.publisher
    .dropFirst()
    .map { Action.internal(.filtersChanged($0)) }
}
```

---

## Navigation et Presentation

### Navigation par tabs (AppFeature)

```swift
@Reducer
struct AppFeature {
  enum Tab: Equatable, Hashable, CaseIterable {
    case home, importer, compare, analysis
  }

  @ObservableState
  struct State: Equatable {
    var selectedTab: Tab = .home
    var home: HomeFeature.State = .initial
    var importer: ImportFeature.State = .initial
  }

  var body: some ReducerOf<Self> {
    Scope(state: \.home, action: \.home) { HomeFeature() }
    Scope(state: \.importer, action: \.importer) { ImportFeature() }
  }
}

// Vue
TabView(selection: $store.selectedTab.sending(\.tabSelected)) {
  HomeView(store: store.scope(state: \.home, action: \.home))
    .tag(AppFeature.Tab.home)
}
```

### Presentation modale (@Presents)

```swift
@ObservableState
struct State: Equatable {
  @Presents var settings: SettingsFeature.State?
  @Presents var tutorial: TutorialFeature.State?
}

enum Action {
  case settings(PresentationAction<SettingsFeature.Action>)
  case settingsButtonTapped
}

var body: some ReducerOf<Self> {
  Reduce { state, action in
    case .settingsButtonTapped:
      state.settings = .initial
      return .none

    case .settings(.presented(.delegate(.dismissed))):
      state.settings = nil
      return .none
  }
  .ifLet(\.$settings, action: \.settings) {
    SettingsFeature()
  }
}

// Vue
.sheet(item: $store.scope(state: \.settings, action: \.settings)) { store in
  SettingsView(store: store)
}
```

### Navigation cross-feature via Delegate

```swift
// HomeFeature envoie une action delegate
case .compareButtonTapped:
  return .send(.delegate(.compareWithBase(tokens: state.tokens, metadata: state.metadata)))

// AppFeature intercepte et route
case .home(.delegate(.compareWithBase(let tokens, let metadata))):
  state.selectedTab = .compare
  return .send(.compare(.internal(.setBaseAsOldFile(tokens: tokens, metadata: metadata))))
```

---

## Creer une nouvelle Feature - Checklist

1. **Creer le fichier principal** `[Nom]Feature.swift`
   - Definir le State avec `@ObservableState`
   - Definir toutes les Action enums
   - Implementer le body avec routing

2. **Creer la vue** `[Nom]Feature+View.swift`
   - Utiliser `@ViewAction(for: [Nom]Feature.self)`
   - Utiliser `@Bindable var store`

3. **Creer les handlers d'actions** dans `Actions/`
   - `+ViewActions.swift`
   - `+InternalActions.swift`
   - `+AnalyticsActions.swift` (si analytics)

4. **Si besoin d'un service**
   - `[Nom]+Client.swift` avec `testValue` et `previewValue`
   - `[Nom]+Service.swift` comme `actor`

5. **Si besoin de persistance**
   - Ajouter la cle dans `SharedKeys.swift`
   - Utiliser `@Shared` dans le State
