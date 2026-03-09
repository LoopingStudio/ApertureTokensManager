# Guidelines et references

## A faire
- Toujours fournir `testValue` et `previewValue` pour les clients
- Utiliser `TokenHelpers` pour les operations sur les arbres de tokens
- Centraliser les constantes dans `Constants.swift`
- Separer les actions en View/Internal/Binding/Analytics/Delegate
- Utiliser `static var initial` pour l'etat par defaut

## A eviter
- Force unwraps (`!`) - preferer `guard let` ou `if let`
- Code duplique pour l'aplatissement des tokens
- Valeurs hardcodees (dimensions, durees, noms de groupes)
- `print()` pour le debug (utiliser `loggingClient`)
- Actions TCA trop larges (separer par type)
- Tableaux d'Effects (`[Effect]`) - utiliser `.merge()` ou `.concatenate()`

## Commandes

```bash
xcodebuild -scheme ApertureTokensManager build
xcodebuild -scheme ApertureTokensManager test
```

## Skills de reference

| Skill | Quand l'utiliser |
|-------|-----------------|
| `pwf-composable-architecture` | Reducers, Effects, Store, Scope |
| `pwf-sharing` | `@Shared`, persistance, publishers |
| `pwf-dependencies` | `@Dependency`, Clients, testValue |
| `pwf-swift-navigation` | Navigation, alerts, sheets, @Presents |
| `pwf-modern-swiftui` | `@Observable`, bindings modernes |
| `swift-concurrency` | async/await, actors, Task |
| `swiftui-expert-skill` | SwiftUI, creation de views |
| `looping-tca-architecture` | Architecture TCA complete du projet |
