# Swift + TCA Architecture Reference

Generic reference for macOS/iOS projects using **The Composable Architecture (TCA)**, **Swift Concurrency**, and the **Client/Service** dependency pattern.

---

## Stack technique

| Layer | Technology |
|-------|-----------|
| UI | SwiftUI |
| Architecture | TCA (`@Reducer`, `@ObservableState`, `@Shared`) |
| Concurrency | async/await, actors |
| Dependencies | `@Dependency` (swift-dependencies) |
| Persistence | `@Shared` (swift-sharing) |
| Platform | macOS 14+ / iOS 17+ |

---

## Structure de projet recommandée

```
AppName/
├── App/                          # Point d'entrée, AppDelegate, Environment keys
├── Components/                   # Composants UI réutilisables et génériques
├── Extensions/                   # Extensions Swift (Color+Hex, SharedKeys, etc.)
├── Features/                     # Features TCA
│   ├── App/                      # Feature racine (tabs, navigation globale)
│   ├── [Feature]/                # Une feature par domaine
│   │   ├── [Feature]Feature.swift
│   │   ├── [Feature]Feature+View.swift
│   │   └── Actions/
│   │       ├── [Feature]Feature+ViewActions.swift
│   │       ├── [Feature]Feature+InternalActions.swift
│   │       ├── [Feature]Feature+BindingActions.swift
│   │       └── [Feature]Feature+AnalyticsActions.swift
├── Helpers/                      # Utilitaires partagés (non-UI)
├── Models/                       # Modèles de données, Constants.swift
└── Services/                     # Services métier (Client + Service pattern)
    └── [Domain]Service/
        ├── [Domain]+Client.swift
        └── [Domain]+Service.swift
```

---

## Feature TCA

### Structure d'un Reducer

```swift
@Reducer
public struct MyFeature: Sendable {

  // 1. Dependencies
  @Dependency(\.myClient) var myClient
  @Dependency(\.loggingClient) var loggingClient

  // 2. State
  @ObservableState
  public struct State: Equatable {
    var items: [Item] = []
    var isLoading: Bool = false
    @Shared(.mySharedKey) var sharedValue

    public static var initial: Self { State() }
  }

  // 3. Actions
  @CasePathable
  public enum Action: BindableAction, ViewAction, Equatable, Sendable {
    case analytics(Analytics)
    case binding(BindingAction<State>)
    case delegate(Delegate)
    case `internal`(Internal)
    case view(View)

    enum Analytics: Sendable, Equatable {
      case screenViewed
      case actionPerformed(itemId: String)
    }

    enum Delegate: Sendable, Equatable {
      case itemSelected(Item)
      case dismissed
    }

    enum Internal: Sendable, Equatable {
      case loadingStarted
      case loadingFailed(String)
      case itemsLoaded([Item])
      case observeSharedValue
    }

    enum View: Sendable, Equatable {
      case onAppear
      case itemTapped(Item.ID)
      case refreshTapped
    }
  }

  // 4. Body
  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .analytics(let action): return handleAnalyticsAction(action, state: &state)
      case .binding(let action):   return handleBindingAction(action, state: &state)
      case .delegate:              return .none  // Géré par le parent
      case .internal(let action):  return handleInternalAction(action, state: &state)
      case .view(let action):      return handleViewAction(action, state: &state)
      }
    }
  }
}
```

### Convention des 5 types d'actions

| Type | Rôle | Mute l'état ? | Retourne des effets ? |
|------|------|:-----------:|:-------------------:|
| `analytics` | Métriques, logs | ✗ | ✗ (fire & forget) |
| `binding` | Bindings SwiftUI | via BindingReducer | ✗ |
| `delegate` | Signal vers le parent | ✗ | ✗ |
| `internal` | Réactions, effets async | ✓ | ✓ |
| `view` | Intentions utilisateur | rarement | ✓ |

### Handlers d'actions (fichiers séparés)

**`+ViewActions.swift`**
```swift
extension MyFeature {
  func handleViewAction(_ action: Action.View, state: inout State) -> EffectOf<Self> {
    switch action {
    case .onAppear:
      return .merge(
        .send(.analytics(.screenViewed)),
        .send(.internal(.loadingStarted))
      )

    case .itemTapped(let id):
      guard let item = state.items[id: id] else { return .none }
      return .send(.delegate(.itemSelected(item)))

    case .refreshTapped:
      return .send(.internal(.loadingStarted))
    }
  }
}
```

**`+InternalActions.swift`**
```swift
extension MyFeature {
  func handleInternalAction(_ action: Action.Internal, state: inout State) -> EffectOf<Self> {
    switch action {
    case .loadingStarted:
      state.isLoading = true
      return .run { send in
        do {
          let items = try await myClient.fetchItems()
          await send(.internal(.itemsLoaded(items)))
        } catch {
          await send(.internal(.loadingFailed(error.localizedDescription)))
        }
      }

    case .itemsLoaded(let items):
      state.isLoading = false
      state.items = items
      return .none

    case .loadingFailed(let message):
      state.isLoading = false
      // handle error...
      return .none

    case .observeSharedValue:
      return .publisher {
        state.$sharedValue.publisher
          .dropFirst()
          .map { _ in Action.internal(.loadingStarted) }
      }
    }
  }
}
```

**`+AnalyticsActions.swift`**
```swift
extension MyFeature {
  func handleAnalyticsAction(_ action: Action.Analytics, state: inout State) -> EffectOf<Self> {
    switch action {
    case .screenViewed:
      loggingClient.logScreenView("MyFeature")
      return .none

    case .actionPerformed(let id):
      loggingClient.logUserAction("my_feature", "action_performed", ["id": id])
      return .none
    }
  }
}
```

---

## Vue TCA

```swift
// MyFeature+View.swift
@ViewAction(for: MyFeature.self)
public struct MyFeatureView: View {
  @Bindable public var store: StoreOf<MyFeature>

  public var body: some View {
    List(store.items) { item in
      ItemRow(item: item)
        .onTapGesture { send(.itemTapped(item.id)) }
    }
    .overlay { if store.isLoading { ProgressView() } }
    .refreshable { send(.refreshTapped) }
    .onAppear { send(.onAppear) }
  }
}
```

### Règles des vues

- Utiliser `@ViewAction(for:)` pour accéder à `send(_:)`
- Utiliser `@Bindable var store` pour les bindings
- Bindings : `$store.searchText.sending(\.binding)`
- Extraire les sous-vues dans `Views/` si complexes
- Aucune logique métier dans les vues

---

## Pattern Client / Service

### Client (Interface de dépendance)

```swift
// MyDomain+Client.swift
struct MyDomainClient {
  var fetchItems: @Sendable () async throws -> [Item]
  var saveItem: @Sendable (Item) async throws -> Void
  var deleteItem: @Sendable (Item.ID) async throws -> Void
}

extension MyDomainClient: DependencyKey {
  static let liveValue: Self = {
    let service = MyDomainService()
    return .init(
      fetchItems: { try await service.fetchItems() },
      saveItem:   { try await service.saveItem($0) },
      deleteItem: { try await service.deleteItem($0) }
    )
  }()

  // OBLIGATOIRE — lève une erreur si appelé sans override dans les tests
  static let testValue: Self = .init(
    fetchItems: unimplemented("MyDomainClient.fetchItems"),
    saveItem:   unimplemented("MyDomainClient.saveItem"),
    deleteItem: unimplemented("MyDomainClient.deleteItem")
  )

  static let previewValue: Self = .init(
    fetchItems: { Item.previews },
    saveItem:   { _ in },
    deleteItem: { _ in }
  )
}

extension DependencyValues {
  var myDomainClient: MyDomainClient {
    get { self[MyDomainClient.self] }
    set { self[MyDomainClient.self] = newValue }
  }
}
```

### Service (Implémentation)

```swift
// MyDomain+Service.swift
actor MyDomainService {
  @Dependency(\.fileClient) var fileClient  // peut dépendre d'autres clients
  private let logger = Logger(subsystem: "app", category: "MyDomain")

  func fetchItems() async throws -> [Item] {
    logger.info("Fetching items")
    // implémentation...
  }

  func saveItem(_ item: Item) async throws {
    logger.debug("Saving item \(item.id)")
    // implémentation...
  }

  func deleteItem(_ id: Item.ID) async throws {
    // implémentation...
  }
}
```

### Règles Client/Service

- Le Client est une **struct avec des closures** (pas un protocol)
- Les closures sont toujours `@Sendable`
- Le Service est un **actor** pour la thread-safety
- Toujours fournir `testValue` et `previewValue`
- Le liveValue instancie le Service et wrap ses méthodes

---

## État partagé (@Shared)

### Définition d'une clé partagée

```swift
// Extensions/SharedKeys.swift

// 1. Le type
public struct MySettings: Equatable, Sendable, Codable {
  public var isEnabled: Bool = true
  public var count: Int = 0
}

// 2. L'URL de stockage (pour FileStorage)
extension URL {
  static let mySettings = Self.documentsDirectory.appending(component: "my-settings.json")
}

// 3. La clé
extension SharedKey where Self == FileStorageKey<MySettings>.Default {
  static var mySettings: Self {
    Self[.fileStorage(.mySettings), default: MySettings()]
  }
}

// Pour les valeurs simples en mémoire :
extension SharedKey where Self == InMemoryKey<Bool>.Default {
  static var isOnboarded: Self {
    Self[.inMemory("isOnboarded"), default: false]
  }
}
```

### Usage dans le State

```swift
@ObservableState
public struct State: Equatable {
  @Shared(.mySettings) var settings
  @Shared(.isOnboarded) var isOnboarded
}
```

### Mutation

```swift
// Depuis une action
state.$settings.withLock { $0.isEnabled.toggle() }
state.$settings.withLock { $0.count += 1 }
```

### Observation

```swift
case .observeSettings:
  return .publisher {
    state.$settings.publisher
      .dropFirst()
      .map { Action.internal(.settingsChanged($0)) }
  }
```

---

## Navigation

### Tabs (AppFeature)

```swift
@Reducer
struct AppFeature {
  enum Tab: Equatable, Hashable, CaseIterable {
    case home, settings, profile
  }

  @ObservableState
  struct State: Equatable {
    var selectedTab: Tab = .home
    var home: HomeFeature.State = .initial
    var settings: SettingsFeature.State = .initial
  }

  var body: some ReducerOf<Self> {
    Scope(state: \.home, action: \.home) { HomeFeature() }
    Scope(state: \.settings, action: \.settings) { SettingsFeature() }
    Reduce { state, action in
      switch action {
      case .tabSelected(let tab):
        state.selectedTab = tab
        return .none
      // Intercepter les delegates des enfants :
      case .home(.delegate(.goToSettings)):
        state.selectedTab = .settings
        return .none
      default:
        return .none
      }
    }
  }
}

// Vue
TabView(selection: $store.selectedTab.sending(\.tabSelected)) {
  HomeView(store: store.scope(state: \.home, action: \.home))
    .tag(AppFeature.Tab.home)
}
```

### Modales (@Presents)

```swift
// State
@ObservableState
struct State: Equatable {
  @Presents var detail: DetailFeature.State?
}

// Actions
enum Action {
  case detail(PresentationAction<DetailFeature.Action>)
  case showDetailTapped(Item)
}

// Reducer
case .showDetailTapped(let item):
  state.detail = DetailFeature.State(item: item)
  return .none

case .detail(.presented(.delegate(.dismissed))):
  state.detail = nil
  return .none

// Scope
.ifLet(\.$detail, action: \.detail) { DetailFeature() }

// Vue
.sheet(item: $store.scope(state: \.detail, action: \.detail)) { store in
  DetailView(store: store)
}
```

### Communication cross-feature

```swift
// Enfant → Parent via delegate
case .saveButtonTapped:
  return .send(.delegate(.itemSaved(state.item)))

// Parent intercepte
case .child(.delegate(.itemSaved(let item))):
  state.items.append(item)
  return .none
```

---

## Patterns d'Effects

```swift
// Aucun effet
return .none

// Envoyer une action
return .send(.internal(.loadingStarted))

// Async (avec gestion d'erreur)
return .run { send in
  do {
    let result = try await client.doWork()
    await send(.internal(.workDone(result)))
  } catch {
    await send(.internal(.workFailed(error.localizedDescription)))
  }
}

// Async avec catch séparé
return .run { send in
  let result = try await client.doWork()
  await send(.internal(.workDone(result)))
} catch: { error, send in
  await send(.internal(.workFailed(error.localizedDescription)))
}

// Parallèle
return .merge(
  .send(.analytics(.screenViewed)),
  .send(.internal(.observeFilters))
)

// Séquentiel
return .concatenate(
  .send(.internal(.step1)),
  .send(.internal(.step2))
)

// Publisher
return .publisher {
  somePublisher.map { Action.internal(.valueChanged($0)) }
}

// Annulation
return .run { send in ... }.cancellable(id: CancelID.fetch)
// ...
return .cancel(id: CancelID.fetch)

enum CancelID { case fetch }
```

---

## Règles d'or

### À faire
- `static var initial: Self` pour l'état par défaut
- `testValue` et `previewValue` pour chaque Client
- `guard let` / `if let` plutôt que les force unwrap
- `actor` pour les Services
- Séparer les actions en View / Internal / Binding / Analytics / Delegate
- `loggingClient` pour les logs (jamais `print`)
- Constantes dans `Constants.swift`

### À éviter
- Force unwrap `!`
- Logique métier dans les vues
- Code dupliqué — extraire dans des helpers
- Valeurs hardcodées (dimensions, strings, durées)
- `[Effect]` — utiliser `.merge()` ou `.concatenate()`
- Protocols pour les clients (utiliser des structs avec closures)

---

## Skills Claude à utiliser

| Skill | Quand |
|-------|-------|
| `pwf-composable-architecture` | Reducers, Effects, Store, Scope, TCA patterns |
| `pwf-sharing` | `@Shared`, persistance, observation de publishers |
| `pwf-dependencies` | `@Dependency`, Clients, testValue, DependencyKey |
| `pwf-swift-navigation` | Navigation, alerts, sheets, `@Presents` |
| `pwf-modern-swiftui` | `@Observable`, bindings modernes, SwiftUI tips |
| `swift-concurrency` | async/await, actors, Task, Sendable |
| `swiftui-expert-skill` | Création et review de vues SwiftUI |
| `xcodebuildmcp` | Build, test, run, debug iOS/macOS |

---

## Checklist nouvelle Feature

- [ ] `[Nom]Feature.swift` — Reducer + State + Action enums + body routing
- [ ] `[Nom]Feature+View.swift` — `@ViewAction`, `@Bindable var store`
- [ ] `Actions/[Nom]Feature+ViewActions.swift`
- [ ] `Actions/[Nom]Feature+InternalActions.swift`
- [ ] `Actions/[Nom]Feature+AnalyticsActions.swift` (si analytics)
- [ ] `[Nom]+Client.swift` avec `liveValue`, `testValue`, `previewValue`
- [ ] `[Nom]+Service.swift` comme `actor`
- [ ] Clé `@Shared` dans `SharedKeys.swift` (si persistance)
- [ ] Feature scopée dans le parent (`Scope` + `.ifLet` si modal)
