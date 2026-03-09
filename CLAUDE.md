# CLAUDE.md - ApertureTokensManager

## Description du projet

Application macOS pour importer, visualiser, filtrer et exporter des design tokens depuis Figma vers Xcode. Fonctionne avec le plugin Figma **ApertureExporter**.

## 🔍 Environment Adaptation

This project supports two Claude development environments:
- **Xcode 26.3+ Claude Agent SDK** - Uses Xcode built-in MCP tools
- **Pure Claude Code** - Uses command line Claude Code

### Environment Detection

Judge the current environment by checking the `CLAUDE_CONFIG_DIR` environment variable:

- ✅ **Contains `Xcode/CodingAssistant`** → Use configuration from [CLAUDE-XCODE.md](CLAUDE-XCODE.md)
  - Example: `~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig`
- ❌ **Does not contain or is another path** → Use configuration from [CLAUDE-PURE.md](CLAUDE-PURE.md)
  - Example: `~/.config/claude` or other standard configuration paths

## Stack technique

- **SwiftUI** - Interface utilisateur
- **TCA (The Composable Architecture)** - Architecture avec `@Reducer`, `@ObservableState`, `@Shared`
- **Swift Concurrency** - async/await, actors
- **macOS 14+** - Plateforme cible

## Architecture du projet

```
ApertureTokensManager/
├── App/                          # Point d'entrée + Environment keys
├── Components/                   # Composants UI réutilisables
├── Extensions/                   # Extensions Swift (Color+Hex, SharedKeys, String+Date)
├── Features/                     # Features TCA (voir section dédiée)
│   ├── Analysis/                 # Analyse d'usage des tokens
│   ├── App/                      # Feature racine (tabs, navigation)
│   ├── Compare/                  # Comparaison de versions
│   ├── Home/                     # Dashboard principal
│   ├── Import/                   # Import et visualisation des tokens
│   ├── Settings/                 # Paramètres de l'app
│   ├── TokenBrowser/             # Navigation dans l'arbre de tokens
│   └── Tutorial/                 # Onboarding
├── Helpers/                      # Utilitaires partagés (TokenHelpers, FuzzyMatching)
├── Models/                       # Modèles de données
│   ├── Constants.swift           # Constantes centralisées
│   ├── TokenNode.swift           # Modèle principal des tokens
│   └── ...
└── Services/                     # Services métier (Client + Service pattern)
    ├── ComparisonService/        # Comparaison de tokens
    ├── ExportService/            # Export XCAssets + Swift
    ├── FileService/              # Gestion fichiers
    ├── HistoryService/           # Historique imports
    ├── LoggingService/           # Analytics et logs
    ├── SuggestionService/        # Auto-suggestions
    └── UsageService/             # Analyse d'usage
```

---

## Structure d'une Feature TCA

### Organisation des fichiers

Chaque feature complexe suit cette structure :

```
Features/Import/
├── ImportFeature.swift                      # Reducer + State + Action enums
├── ImportFeature+View.swift                 # Vue SwiftUI principale
├── Actions/
│   ├── ImportFeature+ViewActions.swift      # handleViewAction(_:state:)
│   ├── ImportFeature+InternalActions.swift  # handleInternalAction(_:state:)
│   ├── ImportFeature+BindingActions.swift   # handleBindingAction(_:state:)
│   └── ImportFeature+AnalyticsActions.swift # handleAnalyticsAction(_:state:)
└── Views/
    └── TokenDetailView.swift                # Sous-vues spécifiques
```

### Conventions de nommage

| Type | Convention | Exemple |
|------|------------|---------|
| Feature principale | `[Nom]Feature.swift` | `ImportFeature.swift` |
| Vue principale | `[Nom]Feature+View.swift` | `ImportFeature+View.swift` |
| Actions handlers | `[Nom]Feature+[Type]Actions.swift` | `ImportFeature+ViewActions.swift` |
| Sous-vues | `[Nom]View.swift` | `TokenDetailView.swift` |
| Client | `[Nom]+Client.swift` | `Export+Client.swift` |
| Service | `[Nom]+Service.swift` | `Export+Service.swift` |

---

## Pattern Reducer TCA

### Structure complète d'un Reducer

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

  // 3. Actions (voir section dédiée)
  @CasePathable
  public enum Action: BindableAction, ViewAction, Equatable, Sendable {
    case analytics(Analytics)
    case binding(BindingAction<State>)
    case delegate(Delegate)
    case `internal`(Internal)
    case view(View)

    // Nested enums defined here...
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

### Pourquoi ces conformances ?

| Protocole/Macro | Raison |
|-----------------|--------|
| `@Reducer` | Macro TCA qui génère la conformance au protocole Reducer |
| `Sendable` | Requis pour Swift Concurrency - garantit thread-safety |
| `@ObservableState` | Permet l'observation automatique du state dans SwiftUI |
| `Equatable` (State) | Requis pour la comparaison d'état et l'optimisation des updates |
| `@CasePathable` | Génère les case paths pour le routing des actions |
| `BindableAction` | Permet `$store.property.sending(\.binding)` dans les vues |
| `ViewAction` | Permet `@ViewAction(for:)` macro sur les vues |

---

## Organisation des Actions

### Les 5 types d'actions

```swift
@CasePathable
public enum Action: BindableAction, ViewAction, Equatable, Sendable {
  case analytics(Analytics)      // Métriques & telemetry
  case binding(BindingAction<State>)  // Bindings SwiftUI
  case delegate(Delegate)        // Communication vers le parent
  case `internal`(Internal)      // Effets internes & réactions
  case view(View)               // Interactions UI utilisateur
}
```

#### 1. `analytics` - Métriques (non-bloquant)
```swift
enum Analytics: Sendable, Equatable {
  case exportCompleted(tokenCount: Int)
  case fileLoaded(fileName: String, tokenCount: Int)
  case screenViewed
}

// Handler - jamais de mutation d'état, uniquement logging
func handleAnalyticsAction(_ action: Action.Analytics, state: inout State) -> EffectOf<Self> {
  switch action {
  case .exportCompleted(let count):
    loggingClient.logUserAction(LogFeature.import, "export_completed", ["count": "\(count)"])
    return .none
  }
}
```

#### 2. `binding` - Bindings SwiftUI
```swift
case binding(BindingAction<State>)

// Handler - généralement vide car géré par BindingReducer()
func handleBindingAction(_ action: BindingAction<State>, state: inout State) -> EffectOf<Self> {
  return .none
}

// Usage dans la vue
TextField("Search", text: $store.searchText.sending(\.binding))
```

#### 3. `delegate` - Communication parent
```swift
enum Delegate: Sendable, Equatable {
  case baseUpdated
  case goToImport
  case compareWithBase(tokens: [TokenNode], metadata: TokenMetadata)
}

// Jamais géré dans la feature elle-même - le parent intercepte
// Dans AppFeature:
case .home(.delegate(.goToImport)):
  state.selectedTab = .importer
  return .none
```

#### 4. `internal` - Effets et réactions
```swift
enum Internal: Sendable, Equatable {
  case fileLoadingStarted
  case fileLoadingFailed(String)
  case loadFile(URL)
  case exportLoaded(TokenExport, URL)
  case filtersChanged(TokenFilters)
  case observeFilters
}

// Handler - peut muter l'état et retourner des effets
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

#### 5. `view` - Interactions UI
```swift
enum View: Sendable, Equatable {
  case selectFileTapped
  case exportButtonTapped
  case toggleNode(TokenNode.ID)
  case onAppear
}

// Handler - déclenche souvent des actions internal
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

## Pattern Client/Service

### Client (Interface)

```swift
// Export+Client.swift
struct ExportClient {
  var exportDesignSystem: @Sendable ([TokenNode]) async throws -> Void
  var exportToDirectory: @Sendable ([TokenNode], URL) async throws -> Void
}

extension ExportClient: DependencyKey {
  static let liveValue: Self = {
    let service = ExportService()
    return .init(
      exportDesignSystem: { try await service.exportDesignSystem(nodes: $0) },
      exportToDirectory: { try await service.exportToDirectory(nodes: $0, at: $1) }
    )
  }()

  // TOUJOURS fournir testValue et previewValue
  static let testValue: Self = .init(
    exportDesignSystem: { _ in },
    exportToDirectory: { _, _ in }
  )

  static let previewValue: Self = testValue
}

extension DependencyValues {
  var exportClient: ExportClient {
    get { self[ExportClient.self] }
    set { self[ExportClient.self] = newValue }
  }
}
```

### Service (Implémentation)

```swift
// Export+Service.swift
actor ExportService {
  @Dependency(\.fileClient) var fileClient  // Peut dépendre d'autres clients
  private let logger = AppLogger.export

  func exportDesignSystem(nodes: [TokenNode]) async throws {
    logger.info("Starting export with \(nodes.count) nodes")

    guard let destinationURL = try await fileClient.pickDirectory() else {
      logger.debug("Export cancelled by user")
      return
    }

    try await exportToDirectory(nodes: nodes, at: destinationURL)
  }

  func exportToDirectory(nodes: [TokenNode], at url: URL) async throws {
    // Implémentation...
  }
}
```

### Règles importantes

- **Toujours** fournir `testValue` et `previewValue`
- Les closures doivent être `@Sendable`
- Le Service est un `actor` pour la thread-safety
- Le Client est une struct avec des closures (pas un protocol)

---

## State partagé (@Shared)

### Définition des clés

```swift
// Extensions/SharedKeys.swift

// 1. Définir le type
public struct TokenFilters: Equatable, Sendable, Codable {
  public var excludeTokensStartingWithHash: Bool = false
  public var excludeTokensEndingWithHover: Bool = false
  public var excludeUtilityGroup: Bool = false
}

// 2. Définir le chemin de stockage
extension URL {
  static let tokenFilters = Self.documentsDirectory.appending(component: "token-filters.json")
}

// 3. Définir la clé partagée
extension SharedKey where Self == FileStorageKey<TokenFilters>.Default {
  static var tokenFilters: Self {
    Self[.fileStorage(.tokenFilters), default: TokenFilters()]
  }
}
```

### Usage dans le State

```swift
@ObservableState
public struct State: Equatable {
  @Shared(.tokenFilters) var filters
  @Shared(.designSystemBase) var designSystemBase: DesignSystemBase?
  @Shared(.importHistory) var importHistory: [ImportHistoryEntry]
}
```

### Observation des changements

```swift
case .observeFilters:
  return .publisher {
    state.$filters.publisher
      .dropFirst()  // Ignorer la valeur initiale
      .map { Action.internal(.filtersChanged($0)) }
  }
```

### Mutation avec lock

```swift
// Pour muter un @Shared depuis une action
state.$tokenFilters.withLock { $0.excludeTokensStartingWithHash.toggle() }
```

### Clés partagées du projet

| Clé | Type | Usage |
|-----|------|-------|
| `.tokenFilters` | `TokenFilters` | Filtres d'export |
| `.designSystemBase` | `DesignSystemBase?` | Base de tokens importée |
| `.importHistory` | `[ImportHistoryEntry]` | Historique des imports |
| `.comparisonHistory` | `[ComparisonHistoryEntry]` | Historique des comparaisons |
| `.analysisDirectories` | `[ScanDirectory]` | Dossiers à analyser |
| `.appSettings` | `AppSettings` | Paramètres de l'app |
| `.onboardingState` | `OnboardingState` | État du tutoriel |

---

## Navigation et Présentation

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
    // ...
  }

  var body: some ReducerOf<Self> {
    Scope(state: \.home, action: \.home) { HomeFeature() }
    Scope(state: \.importer, action: \.importer) { ImportFeature() }
    // ...
  }
}

// Vue
TabView(selection: $store.selectedTab.sending(\.tabSelected)) {
  HomeView(store: store.scope(state: \.home, action: \.home))
    .tag(AppFeature.Tab.home)
}
```

### Présentation modale (@Presents)

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
      state.settings = .initial  // Ouvre la modale
      return .none

    case .settings(.presented(.delegate(.dismissed))):
      state.settings = nil  // Ferme la modale
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

// Plusieurs effets en parallèle
return .merge(
  .send(.analytics(.screenViewed)),
  .run { send in await send(.internal(.loadData)) }
)

// Effets séquentiels
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

## Créer une nouvelle Feature

### Checklist

1. **Créer le fichier principal** `[Nom]Feature.swift`
   - Définir le State avec `@ObservableState`
   - Définir toutes les Action enums
   - Implémenter le body avec routing

2. **Créer la vue** `[Nom]Feature+View.swift`
   - Utiliser `@ViewAction(for: [Nom]Feature.self)`
   - Utiliser `@Bindable var store`

3. **Créer les handlers d'actions** dans `Actions/`
   - `+ViewActions.swift`
   - `+InternalActions.swift`
   - `+AnalyticsActions.swift` (si analytics)

4. **Si besoin d'un service**
   - `[Nom]+Client.swift` avec `testValue` et `previewValue`
   - `[Nom]+Service.swift` comme `actor`

5. **Si besoin de persistance**
   - Ajouter la clé dans `SharedKeys.swift`
   - Utiliser `@Shared` dans le State

---

## Commandes

### Build et test
```bash
xcodebuild -scheme ApertureTokensManager build
xcodebuild -scheme ApertureTokensManager test
```

---

## Skills de référence

| Skill | Quand l'utiliser |
|-------|-----------------|
| `pwf-composable-architecture` | Reducers, Effects, Store, Scope |
| `pwf-sharing` | `@Shared`, persistance, publishers |
| `pwf-dependencies` | `@Dependency`, Clients, testValue |
| `pwf-swift-navigation` | Navigation, alerts, sheets, @Presents |
| `pwf-modern-swiftui` | `@Observable`, bindings modernes |
| `swift-concurrency` | async/await, actors, Task |
| `swiftui-expert-skill` | SwiftUI, création de views |

---

## Points d'attention

### À faire
- Toujours fournir `testValue` et `previewValue` pour les clients
- Utiliser `TokenHelpers` pour les opérations sur les arbres de tokens
- Centraliser les constantes dans `Constants.swift`
- Séparer les actions en View/Internal/Binding/Analytics/Delegate
- Utiliser `static var initial` pour l'état par défaut

### À éviter
- Force unwraps (`!`) - préférer `guard let` ou `if let`
- Code dupliqué pour l'aplatissement des tokens
- Valeurs hardcodées (dimensions, durées, noms de groupes)
- `print()` pour le debug (utiliser `loggingClient`)
- Actions TCA trop larges (séparer par type)
- Tableaux d'Effects (`[Effect]`) - utiliser `.merge()` ou `.concatenate()`

---

## Workflow Orchestration

### 1. Plan Mode Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately - don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Subagent Strategy to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One task per subagent for focused execution

### 3. Self-Improvement Loop
- After ANY correction from the user: update 'tasks/lessons.md' with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

### 4. Verification Before Done
- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

### 5. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes - don't over-engineer
- Challenge your own work before presenting it

### 6. Autonomous Bug Fixing
- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests -> then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

## Task Management
1. **Plan First**: Write plan to 'tasks/todo.md' with checkable items
2. **Verify Plan**: Check in before starting implementation
3. **Track Progress**: Mark items complete as you go
4. **Explain Changes**: High-level summary at each step
5. **Document Results**: Add review to 'tasks/todo.md'
6. **Capture Lessons**: Update 'tasks/lessons.md' after corrections

## Core Principles
- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what's necessary. Avoid introducing bugs.
