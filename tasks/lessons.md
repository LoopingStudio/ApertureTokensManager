# Lessons Learned

## Table des matières
1. [Architecture TCA](#architecture-tca)
2. [Services & Clients](#services--clients)
3. [State Management](#state-management)
4. [Modèles de données](#modèles-de-données)
5. [Opérations récursives](#opérations-récursives)
6. [Fuzzy Matching](#fuzzy-matching)
7. [Export](#export)
8. [SwiftUI Patterns](#swiftui-patterns)
9. [Performance](#performance)
10. [Conventions de nommage](#conventions-de-nommage)

---

## Architecture TCA

### Organisation des Features
Chaque feature suit une structure cohérente :
- `Feature.swift` - Reducer principal avec State et Actions
- `Feature+View.swift` - Vue SwiftUI avec `@ViewAction`
- `Actions/Feature+ViewActions.swift` - Handler des actions utilisateur
- `Actions/Feature+InternalActions.swift` - Handler des résultats async
- `Views/` - Sous-vues spécifiques à la feature

### Hiérarchie des Actions
```swift
enum Action: BindableAction, ViewAction, Equatable, Sendable {
  case binding(BindingAction<State>)
  case `internal`(Internal)
  case view(View)
  case delegate(Delegate)  // Pour communication cross-feature
}
```

**Règles** :
- `View` = actions initiées par l'utilisateur (imperatif: `buttonTapped`, `fileTapped`)
- `Internal` = résultats async (passé: `fileLoaded`, `exportCompleted`)
- `Delegate` = effets cross-feature (`compareWithBase`, `baseUpdated`)
- Toujours `@CasePathable`, `Equatable`, `Sendable`
- Actions triées par ordre alphabétique

### ViewAction Pattern
Conformer `Action` à `ViewAction` pour utiliser `send()` au lieu de `store.send(.view())` :
```swift
@ViewAction(for: TokenFeature.self)
struct TokenView: View {
  @Bindable var store: StoreOf<TokenFeature>

  var body: some View {
    Button("Load") { send(.loadButtonTapped) }  // Pas store.send(.view(...))
  }
}
```

---

## Services & Clients

### Pattern Client-Service
Chaque service a deux fichiers :
1. **Client** (`File+Client.swift`) - Interface avec closures `@Sendable`
2. **Service** (`File+Service.swift`) - Implémentation actor

```swift
// Client - Interface
struct FileClient {
  var pickFile: @Sendable () async throws -> URL?
  var loadTokenExport: @Sendable (URL) async throws -> TokenExport
}

// Service - Implémentation
actor FileService {
  @MainActor
  func pickFile() async throws -> URL? { /* NSOpenPanel */ }
}
```

### Trois valeurs obligatoires
Toujours fournir pour chaque client :
- `liveValue` - Implémentation réelle avec le service actor
- `testValue` - Retourne des valeurs vides/mock pour les tests
- `previewValue` - Souvent égal à testValue, pour les previews SwiftUI

```swift
extension FileClient: DependencyKey {
  static let liveValue: Self = { let service = FileService(); return .init(...) }()
  static let testValue: Self = .init(pickFile: { nil }, loadTokenExport: { _ in .empty })
  static let previewValue: Self = testValue
}
```

### Actors pour thread-safety
Les services utilisent `actor` pour la sécurité des threads sans locks explicites.

---

## State Management

### @Shared pour état persistant
Utiliser `@Shared` (Sharing library) pour l'état partagé entre features :
```swift
@ObservableState
struct State: Equatable {
  // État local UI
  var isLoading: Bool = false

  // État partagé/persistant
  @Shared(.designSystemBase) var designSystemBase: DesignSystemBase?
  @Shared(.tokenFilters) var filters: TokenFilters
}
```

### SharedKeys
Définir les clés dans `Extensions/SharedKeys.swift` :
```swift
extension SharedKey where Self == FileStorageKey<DesignSystemBase?>.Default {
  static var designSystemBase: Self {
    Self[.fileStorage(.designSystemBase), default: nil]
  }
}
```

### Mutation atomique avec withLock
```swift
state.$designSystemBase.withLock {
  $0 = DesignSystemBase(fileName: ..., bookmarkData: ..., metadata: ..., tokens: ...)
}
```

---

## Modèles de données

### UUID sur decode, pas encode
Générer un nouvel UUID à chaque décodage pour éviter les collisions :
```swift
public init(from decoder: Decoder) throws {
  self.id = UUID()  // Nouveau ID à chaque import
  self.name = try container.decode(String.self, forKey: .name)
}

public func encode(to encoder: Encoder) throws {
  // NE PAS encoder l'ID
  try container.encode(name, forKey: .name)
}
```

### Modèles de projection légers
Utiliser `TokenSummary` au lieu de `TokenNode` dans les collections pour réduire la mémoire :
```swift
public struct TokenSummary: Equatable, Sendable, Identifiable {
  public let id = UUID()
  let name: String
  let path: String
  let modes: TokenThemes?

  init(from node: TokenNode) { /* projeter les champs */ }
}
```

### Flag + Message pour erreurs
Stocker à la fois le booléen et le message :
```swift
var loadingError: Bool
var errorMessage: String?
```

---

## Opérations récursives

### Mutation in-place avec index
Utiliser des boucles avec index pour muter des structures imbriquées :
```swift
private func updateNodeRecursively(nodes: inout [TokenNode], targetId: TokenNode.ID) {
  for i in 0..<nodes.count {
    if nodes[i].id == targetId {
      nodes[i].toggleRecursively(newState)
      return
    }
    if nodes[i].children != nil {
      updateNodeRecursively(nodes: &nodes[i].children!, targetId: targetId)
    }
  }
}
```

### Cascade de désactivation
Passer un flag `forceDisabled` pour propager l'état parent aux enfants :
```swift
private func applyFiltersRecursively(
  nodes: inout [TokenNode],
  filters: TokenFilters,
  forceDisabled: Bool = false
) {
  for i in 0..<nodes.count {
    var shouldDisableChildren = forceDisabled

    if nodes[i].type == .group && nodes[i].name == "Utility" && filters.excludeUtilityGroup {
      nodes[i].isEnabled = false
      shouldDisableChildren = true
    }

    if nodes[i].children != nil {
      applyFiltersRecursively(nodes: &nodes[i].children!, filters: filters, forceDisabled: shouldDisableChildren)
    }
  }
}
```

---

## Fuzzy Matching

### Hiérarchie des critères
Pour le matching de tokens de design, prioriser :
1. **Couleur (50%)** - Le plus important car on cherche un remplacement visuel
2. **Contexte d'usage (30%)** - Marqueurs sémantiques (`bg`, `fg`, `hover`, `solid`, `surface`, etc.)
3. **Structure/Path (20%)** - Moins important si couleur et contexte matchent

**Règle** : Ne jamais prioriser le path/nom sur la couleur. L'utilisateur cherche une équivalence visuelle, pas de nomenclature.

### Marqueurs sémantiques
Groupes de contexte pour matcher des usages similaires :
- **Fond** : `bg`, `background`, `surface`, `fill`, `canvas`
- **Premier plan** : `fg`, `foreground`, `text`, `label`, `title`, `content`
- **Bordures** : `border`, `stroke`, `outline`, `divider`, `separator`
- **États interactifs** : `hover`, `hovered`, `active`, `pressed`, `focus`, `focused`
- **États désactivés** : `disabled`, `inactive`, `muted`
- **Variantes** : `solid`, `filled`, `ghost`, `subtle`, `tinted`
- **Hiérarchie** : `primary`, `secondary`, `tertiary`
- **Feedback** : `error`, `warning`, `success`, `info`, `danger`

---

## Export

### Pattern temp directory + move
Assure une opération atomique :
```swift
@MainActor
func exportDesignSystem(nodes: [TokenNode]) async throws {
  // 1. Créer dans un dossier temporaire
  let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try await createColorsXCAssets(from: filtered, at: tempURL)
  try await createApertureColorsSwift(from: filtered, at: tempURL)

  // 2. Déplacer vers destination finale
  try FileManager.default.copyItem(at: tempURL, to: destinationURL)
  try? FileManager.default.removeItem(at: tempURL)
}
```

**Avantages** : Pas d'export partiel en cas d'erreur.

### Security-scoped bookmarks
Pour accéder aux fichiers sélectionnés par l'utilisateur après redémarrage :
```swift
let bookmarkData = url.securityScopedBookmark()
// Plus tard...
if let url = URL(resolvingBookmarkData: bookmarkData, ...) {
  _ = url.startAccessingSecurityScopedResource()
  defer { url.stopAccessingSecurityScopedResource() }
  // Utiliser url
}
```

---

## SwiftUI Patterns

### ViewBuilder pour sections logiques
Utiliser des computed properties `@ViewBuilder` pour découper les vues :
```swift
struct MyView: View {
  var body: some View {
    VStack {
      headerSection
      contentSection
      footerSection
    }
  }

  @ViewBuilder
  private var headerSection: some View { /* ... */ }

  @ViewBuilder
  private var contentSection: some View { /* ... */ }
}
```

### State machine avec ViewBuilder
Plusieurs `@State` bools + `@ViewBuilder` = états UI clairs :
```swift
@State private var isLoading = false
@State private var hasError = false
@State private var isLoaded = false

@ViewBuilder
private var iconView: some View {
  if isLoading {
    ProgressView()
  } else if hasError {
    Image(systemName: "exclamationmark.circle.fill")
  } else if isLoaded {
    Image(systemName: "checkmark.circle.fill")
  } else {
    Image(systemName: "doc.text")
  }
}
```

### ViewModifier pour effets réutilisables
```swift
struct StaggeredAppearModifier: ViewModifier {
  let index: Int
  @State private var isVisible = false

  func body(content: Content) -> some View {
    content
      .opacity(isVisible ? 1 : 0)
      .offset(y: isVisible ? 0 : 10)
      .onAppear {
        withAnimation(.easeOut(duration: 0.35).delay(Double(index) * 0.08)) {
          isVisible = true
        }
      }
  }
}

extension View {
  func staggeredAppear(index: Int) -> some View {
    modifier(StaggeredAppearModifier(index: index))
  }
}
```

---

## Performance

### Aplatir pour recherche
Éviter la traversée récursive pour chaque recherche :
```swift
static func flattenTokens(_ tokens: [TokenNode]) -> [TokenNode] {
  var result: [TokenNode] = []
  func flatten(_ nodes: [TokenNode]) {
    for node in nodes {
      if node.type == .token { result.append(node) }
      if let children = node.children { flatten(children) }
    }
  }
  flatten(tokens)
  return result
}
```

### Filtrage lazy avec publisher
Appliquer les filtres une seule fois au chargement, puis réappliquer uniquement quand les filtres changent :
```swift
case .observeFilters:
  return .publisher {
    state.$filters.publisher
      .dropFirst()
      .map { Action.internal(.filtersChanged($0)) }
  }
```

---

## Conventions de nommage

### Actions
- **View** : Impératif présent (`selectFileTapped`, `exportButtonTapped`)
- **Internal** : Passé composé (`fileLoaded`, `exportCompleted`, `filtersChanged`)
- **Delegate** : Verbe d'action (`compareWithBase`, `navigateToTab`)

### Modèles
- **Concrets** : `TokenNode`, `TokenExport`, `DesignSystemBase`
- **Projections** : `TokenSummary` (léger)
- **Entries** : `ImportHistoryEntry`, `ComparisonHistoryEntry`
- **Changes** : `ComparisonChanges`, `TokenModification`, `ColorChange`

### Services
- **Clients** : `FileClient`, `ExportClient` (interfaces)
- **Services** : `FileService`, `ExportService` (actors)

### Constantes
Regrouper dans `Constants.swift` :
```swift
enum Brand: String, CaseIterable { case legacy, newBrand }
enum ThemeType: String { case light, dark }
enum GroupNames { static let utility = "utility" }
```

---

## Token Usage Analysis

### Architecture de l'analyse
L'analyse d'utilisation suit le pattern standard :
```
AnalysisFeature
    ↓ (startAnalysisTapped)
UsageClient.analyzeUsage()
    ↓
UsageService (actor)
    ↓ (utilise)
TokenUsageHelpers (static methods)
    ↓
TokenUsageReport → affiché dans les vues
```

### Patterns de recherche
Pour détecter les usages de tokens dans les fichiers Swift :
```swift
enum UsagePattern {
  // .tokenName (shorthand)
  static let dotPrefix = #"\.([a-z][a-zA-Z0-9]*)"#

  // Color.tokenName ou Aperture.Foundations.Color.tokenName
  static let fullyQualified = #"(?:Aperture\.Foundations\.)?Color\.([a-z][a-zA-Z0-9]*)"#

  // theme.color(.tokenName)
  static let themeColor = #"\.color\(\s*\.([a-z][a-zA-Z0-9]*)\s*\)"#
}
```

### Conversion nom → enumCase
Les tokens exportés utilisent camelCase :
```swift
// "bg-brand-solid" → "bgBrandSolid"
static func tokenNameToEnumCase(_ name: String) -> String {
  let cleanName = name
    .replacingOccurrences(of: "-", with: " ")
    .replacingOccurrences(of: "_", with: " ")

  let components = cleanName.split(separator: " ")
  let firstComponent = String(components[0]).lowercased()
  let otherComponents = components.dropFirst().map { String($0).capitalized }

  return firstComponent + otherComponents.joined()
}
```

### Filtering des fichiers
Ignorer les dossiers non pertinents lors du scan :
```swift
let ignoredDirs = ["DerivedData", ".build", "Pods", "Carthage", ".xcodeproj", ".xcworkspace"]
```

Options de config :
- `ignoreTestFiles` - Fichiers contenant "test" ou "spec"
- `ignorePreviewFiles` - Fichiers contenant "preview"

---

## Recherche dans TokenTree

### Architecture
La recherche est gérée au niveau du composant `TokenTree` sans créer de feature TCA séparée :
```swift
struct TokenTree: View {
  let nodes: [TokenNode]
  let searchText: String  // Passé depuis le parent
  // ...
}
```

### TokenTreeSearchHelper
Helper statique pour le filtrage et le highlight :
```swift
enum TokenTreeSearchHelper {
  /// Filtre les nodes et retourne les IDs des parents à auto-expand
  static func filterNodes(
    _ nodes: [TokenNode],
    searchText: String
  ) -> (nodes: [TokenNode], autoExpandedIds: Set<TokenNode.ID>)

  /// Crée un Text avec le match highlighté
  static func highlightedText(
    _ text: String,
    searchText: String,
    baseColor: Color
  ) -> Text
}
```

### Auto-expand des parents
Quand un enfant matche, tous ses parents sont automatiquement expand :
```swift
private var effectiveExpandedNodes: Set<TokenNode.ID> {
  expandedNodes.union(filteredData.autoExpandedIds)
}
```

### Highlight avec Text concatenation
Utiliser `+` pour concaténer des `Text` avec styles différents :
```swift
Text(before).foregroundStyle(baseColor) +
Text(match).foregroundStyle(.purple).bold() +
Text(after).foregroundStyle(baseColor)
```

---

## Liquid Glass (macOS 26)

### Styles de boutons
```swift
// Bouton standard avec teinte
.buttonStyle(.glass(.regular.tint(.blue)))

// Bouton proéminent (action principale)
.buttonStyle(.glassProminent)
```

### Effet sur conteneurs
```swift
// Appliquer l'effet glass à un conteneur
.glassEffect(.regular.tint(.green), in: .rect(cornerRadius: 16))
```

### Migration depuis styles custom
Remplacer les anciens styles par les nouveaux :
- `PressableButtonStyle` → `.buttonStyle(.glass)`
- `InteractiveCardModifier` → `.glassEffect()` ou `.buttonStyle(.glass)`

---

## Logging avec OSLog

### Architecture
Le système de logging suit le pattern Client-Service standard :
```
LoggingClient (TCA @Dependency)
    ↓
LoggingService (actor)
    ↓
AppLogger (OSLog loggers par catégorie)
```

### AppLogger - Loggers par catégorie
```swift
enum AppLogger {
  static let `import` = Logger(subsystem: subsystem, category: "Import")
  static let compare = Logger(subsystem: subsystem, category: "Compare")
  static let analysis = Logger(subsystem: subsystem, category: "Analysis")
  static let export = Logger(subsystem: subsystem, category: "Export")
  static let file = Logger(subsystem: subsystem, category: "File")
  static let history = Logger(subsystem: subsystem, category: "History")
  static let suggestion = Logger(subsystem: subsystem, category: "Suggestion")
  static let usage = Logger(subsystem: subsystem, category: "Usage")
  static let navigation = Logger(subsystem: subsystem, category: "Navigation")
  static let app = Logger(subsystem: subsystem, category: "App")
}
```

### LogEvent - Événements structurés
```swift
public struct LogEvent: Equatable, Sendable {
  public let category: Category  // userAction, systemEvent, error, performance
  public let action: String
  public let label: String?
  public let value: Int?
  public let metadata: [String: String]
  public let timestamp: Date
}
```

### Actions Analytics dans les Reducers
Chaque feature a un enum `Analytics` séparé des autres actions :
```swift
enum Action: BindableAction, ViewAction, Equatable, Sendable {
  case binding(BindingAction<State>)
  case analytics(Analytics)  // ← Actions de logging séparées
  case `internal`(Internal)
  case view(View)
  case delegate(Delegate)
}

@CasePathable
enum Analytics: Sendable, Equatable {
  case screenViewed
  case fileLoaded(fileName: String, tokenCount: Int)
  case exportCompleted(tokenCount: Int)
  case exportFailed(error: String)
}
```

### Utilisation dans le Reducer
```swift
// Déclencher une action analytics depuis view/internal
case .view(.selectFileTapped):
  return .send(.analytics(.screenViewed))

// Handler des analytics
case let .analytics(action):
  switch action {
  case .screenViewed:
    loggingClient.logUserAction(LogFeature.import, "screen_viewed", [:])
  case let .fileLoaded(fileName, tokenCount):
    loggingClient.logSystemEvent(LogFeature.import, "file_loaded", [
      "fileName": fileName,
      "tokenCount": "\(tokenCount)"
    ])
  }
  return .none
```

### LoggingClient API
```swift
loggingClient.logUserAction(feature, action, metadata)   // 🎯 Actions utilisateur
loggingClient.logSystemEvent(feature, event, metadata)   // ⚙️ Événements système
loggingClient.logError(feature, message, error)          // ❌ Erreurs
loggingClient.logPerformance(feature, operation, duration) // ⏱️ Performance
loggingClient.logSuccess(feature, message, metadata)     // ✅ Succès
loggingClient.logWarning(feature, message, metadata)     // ⚠️ Warnings
loggingClient.logDebug(feature, message, metadata)       // 🔍 Debug
```

### Logging dans les Services
Les services utilisent directement `AppLogger` :
```swift
actor FileService {
  func loadTokenExport(from url: URL) async throws -> TokenExport {
    AppLogger.file.systemEvent("Loading file", metadata: ["path": url.lastPathComponent])
    // ...
    AppLogger.file.success("File loaded", metadata: ["tokenCount": "\(count)"])
  }
}
```

---

## Notes pour le futur

### Localisation
Tous les strings UI sont en français. Pour le multi-langue, extraire vers `Localizable.strings`.

### Tests
Utiliser `testValue` des clients pour les tests unitaires. Les reducers peuvent être testés avec `TestStore`.

### Historique
- Max 10 entrées (défini dans le service)
- Déduplication par nom de fichier (imports) ou paires (comparaisons)
- Insertion en tête (plus récent en premier)
