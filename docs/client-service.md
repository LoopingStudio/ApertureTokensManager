# Pattern Client/Service et State partage

## Client (Interface)

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

  static let testValue: Self = .init(
    exportDesignSystem: unimplemented("ExportClient.exportDesignSystem"),
    exportToDirectory: unimplemented("ExportClient.exportToDirectory")
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

## Service (Implementation)

```swift
// Export+Service.swift
actor ExportService {
  @Dependency(\.fileClient) var fileClient
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
    // Implementation...
  }
}
```

## Regles

- **Toujours** fournir `testValue` et `previewValue`
- `testValue` utilise `unimplemented("ClientName.methodName")`
- Les closures doivent etre `@Sendable`
- Le Service est un `actor` pour la thread-safety
- Le Client est une struct avec des closures (pas un protocol)

---

## State partage (@Shared)

### Definition des cles

```swift
// Extensions/SharedKeys.swift

// 1. Definir le type
public struct TokenFilters: Equatable, Sendable, Codable {
  public var excludeTokensStartingWithHash: Bool = false
  public var excludeTokensEndingWithHover: Bool = false
  public var excludeUtilityGroup: Bool = false
}

// 2. Definir le chemin de stockage
extension URL {
  static let tokenFilters = Self.documentsDirectory.appending(component: "token-filters.json")
}

// 3. Definir la cle partagee
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
      .dropFirst()
      .map { Action.internal(.filtersChanged($0)) }
  }
```

### Mutation avec lock

```swift
state.$tokenFilters.withLock { $0.excludeTokensStartingWithHash.toggle() }
```

### Cles partagees du projet

| Cle | Type | Usage |
|-----|------|-------|
| `.tokenFilters` | `TokenFilters` | Filtres d'export |
| `.designSystemBase` | `DesignSystemBase?` | Base de tokens importee |
| `.importHistory` | `[ImportHistoryEntry]` | Historique des imports |
| `.comparisonHistory` | `[ComparisonHistoryEntry]` | Historique des comparaisons |
| `.analysisDirectories` | `[ScanDirectory]` | Dossiers a analyser |
| `.appSettings` | `AppSettings` | Parametres de l'app |
| `.onboardingState` | `OnboardingState` | Etat du tutoriel |
