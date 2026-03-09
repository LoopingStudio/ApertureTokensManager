# Architecture du projet

## Stack technique

- **SwiftUI** - Interface utilisateur
- **TCA (The Composable Architecture)** - Architecture avec `@Reducer`, `@ObservableState`, `@Shared`
- **Swift Concurrency** - async/await, actors
- **macOS 14+** - Plateforme cible

## Arborescence

```
ApertureTokensManager/
├── App/                          # Point d'entree + Environment keys
├── Components/                   # Composants UI reutilisables
├── Extensions/                   # Extensions Swift (Color+Hex, SharedKeys, String+Date)
├── Features/                     # Features TCA (voir section dediee)
│   ├── Analysis/                 # Analyse d'usage des tokens
│   ├── App/                      # Feature racine (tabs, navigation)
│   ├── Compare/                  # Comparaison de versions
│   ├── Home/                     # Dashboard principal
│   ├── Import/                   # Import et visualisation des tokens
│   ├── Settings/                 # Parametres de l'app
│   ├── TokenBrowser/             # Navigation dans l'arbre de tokens
│   └── Tutorial/                 # Onboarding
├── Helpers/                      # Utilitaires partages (TokenHelpers, FuzzyMatching)
├── Models/                       # Modeles de donnees
│   ├── Constants.swift           # Constantes centralisees
│   ├── TokenNode.swift           # Modele principal des tokens
│   └── ...
└── Services/                     # Services metier (Client + Service pattern)
    ├── ComparisonService/        # Comparaison de tokens
    ├── ExportService/            # Export XCAssets + Swift
    ├── FileService/              # Gestion fichiers
    ├── HistoryService/           # Historique imports
    ├── LoggingService/           # Analytics et logs
    ├── SuggestionService/        # Auto-suggestions
    └── UsageService/             # Analyse d'usage
```

## Structure d'une Feature TCA

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
    └── TokenDetailView.swift                # Sous-vues specifiques
```

## Conventions de nommage

| Type | Convention | Exemple |
|------|------------|---------|
| Feature principale | `[Nom]Feature.swift` | `ImportFeature.swift` |
| Vue principale | `[Nom]Feature+View.swift` | `ImportFeature+View.swift` |
| Actions handlers | `[Nom]Feature+[Type]Actions.swift` | `ImportFeature+ViewActions.swift` |
| Sous-vues | `[Nom]View.swift` | `TokenDetailView.swift` |
| Client | `[Nom]+Client.swift` | `Export+Client.swift` |
| Service | `[Nom]+Service.swift` | `Export+Service.swift` |
