# Aperture Tokens Manager

Une application macOS pour importer, comparer, analyser et exporter des design tokens depuis Figma vers Xcode.

## 🎯 Vue d'ensemble

Aperture Tokens Manager est l'application compagnon du plugin Figma **[Multibrand Token Exporter](https://www.figma.com/community/plugin/1601261816129528282/multibrand-token-exporter)**. Elle permet de créer une chaîne complète de design tokens depuis Figma jusqu'à votre projet iOS/macOS.

### Workflow complet
1. **Figma** → Utiliser le plugin **Multibrand Token Exporter** pour exporter vos design tokens
2. **Import** → Glisser-déposer ou sélectionner les fichiers JSON générés
3. **Comparaison** → Comparer deux versions pour voir les changements
4. **Analyse** → Scanner vos projets Swift pour détecter l'utilisation des tokens
5. **Export** → Générer les fichiers Xcode (Colors.xcassets + Swift extensions)

## ✨ Fonctionnalités

### 🏠 Accueil
- **Statistiques** : Aperçu de votre base de design system (tokens, groupes)
- **Actions rapides** : Accès direct aux fonctionnalités principales
- **Historique unifié** : Timeline de vos imports et comparaisons récentes
- **Filtres d'historique** : Tout / Imports / Comparaisons

### 📥 Import de Tokens
- **Drag & Drop** : Glissez simplement vos fichiers JSON dans l'app
- **Sélection de fichiers** : Interface native macOS pour choisir vos exports
- **Métadonnées** : Affichage des informations d'export (date, version, générateur)
- **Recherche** : Filtrage en temps réel avec Cmd+F et auto-expansion des groupes
- **Historique** : Accès rapide aux imports précédents
- **Base de référence** : Définir un fichier comme "base" pour comparaisons

### 🔍 Comparaison de Versions
- **Vue par onglets** : Vue d'ensemble, Ajoutés, Supprimés, Modifiés
- **Détection automatique** : Identifie les tokens ajoutés, supprimés et modifiés
- **Suggestions intelligentes** : Fuzzy matching pour suggérer des remplacements
- **Score de confiance** : Couleur indicative (vert >70%, orange 50-70%, gris <50%)
- **Diff visuel des couleurs** : Badge cliquable montrant l'amplitude du changement (Minimal/Subtil/Modéré/Majeur) avec détails HSL
- **Export Notion** : Génération de Markdown pour documentation

### 📊 Analyse d'Utilisation
- **Scan de projets** : Analyser plusieurs dossiers Swift
- **Tokens utilisés** : Liste avec occurrences (fichier, ligne, contexte)
- **Tokens orphelins** : Tokens non utilisés groupés par catégorie
- **Progression en temps réel** : Barre de progression avec nombre de fichiers scannés
- **Annulation** : Possibilité d'annuler un scan en cours
- **Scan parallélisé** : Performance optimisée avec TaskGroup
- **Persistance** : Les dossiers scannés sont mémorisés entre les sessions
- **Patterns détectés** : `.tokenName`, `Color.tokenName`, `.color(.tokenName)`

### 📤 Export vers Xcode
- **Colors.xcassets** : Génération automatique des color sets Xcode
- **Extensions Swift** : Création d'extensions Color avec vos tokens
- **Structure hiérarchique** : Respect de l'organisation de vos tokens
- **Support multi-thèmes** : Gestion des variantes (legacy, newBrand × light, dark)
- **Filtrage intelligent** : Exportez uniquement les tokens activés

### ⚙️ Paramètres
- **Filtres d'export** : Configurer les exclusions (tokens #, _hover, groupe Utility)
- **Historique** : Limiter le nombre d'entrées conservées (5-50)
- **Données** : Accès au dossier de stockage, reset complet
- **Logs** : Journal d'activité consultable et exportable
- **À propos** : Informations sur l'application et accès au tutoriel

### 📖 Tutoriel intégré
- **Guide de démarrage** : Tutoriel interactif en 5 étapes au premier lancement
- **Animations fluides** : Transitions élégantes entre les étapes
- **Lien plugin Figma** : Accès direct à Multibrand Token Exporter
- **Réaccessible** : Bouton "?" dans la toolbar ou via Paramètres

## 🚀 Installation

### Prérequis
- macOS 26 ou supérieur
- Xcode 17+ (pour le développement)

### Depuis les sources
```bash
git clone https://github.com/your-org/ApertureTokensManager.git
cd ApertureTokensManager
open ApertureTokensManager.xcodeproj
```

## 🔧 Utilisation

### Import simple
1. Ouvrez l'onglet **"Importer"**
2. Glissez votre fichier JSON ou cliquez sur **"Sélectionner un fichier"**
3. Explorez vos tokens dans l'arborescence (recherche avec Cmd+F)
4. Activez/désactivez les tokens à exporter
5. Cliquez sur **"Exporter Design System"** pour générer les fichiers Xcode

### Comparaison de versions
1. Ouvrez l'onglet **"Comparer"**
2. Importez votre **ancienne version** (Old)
3. Importez votre **nouvelle version** (New)
4. Cliquez sur **"Confirmer la comparaison"**
5. Explorez les changements détectés par onglet
6. Consultez les suggestions de remplacement pour les tokens supprimés
7. Optionnel : Exportez vers Notion pour documentation

### Analyse d'utilisation
1. Ouvrez l'onglet **"Analyser"**
2. Ajoutez les dossiers de votre projet Swift à scanner
3. Cliquez sur **"Lancer l'analyse"**
4. Consultez les tokens utilisés avec leurs occurrences
5. Identifiez les tokens orphelins à potentiellement supprimer

## 🔗 Intégration avec Multibrand Token Exporter

Cette application est conçue pour fonctionner avec le plugin Figma **[Multibrand Token Exporter](https://www.figma.com/community/plugin/1601261816129528282/multibrand-token-exporter)** qui :

- Extrait automatiquement tous vos design tokens depuis Figma
- Génère des fichiers JSON structurés avec métadonnées
- Supporte les variables Figma et les modes
- Maintient la hiérarchie et l'organisation de vos tokens

### Format de fichier supporté
```json
{
  "metadata": {
    "exportedAt": "2026-01-28 14:30:45",
    "timestamp": 1737982245000,
    "version": "1.2.0",
    "generator": "Multibrand Token Exporter"
  },
  "tokens": [
    {
      "id": "token-id",
      "name": "primary-blue",
      "path": "colors/primary/blue",
      "value": "#007AFF",
      "isEnabled": true,
      "modes": {
        "legacy": {
          "light": "#007AFF",
          "dark": "#0A84FF"
        },
        "newBrand": {
          "light": "#0066CC",
          "dark": "#3399FF"
        }
      }
    }
  ]
}
```

## 🛠 Architecture technique

### Stack
- **SwiftUI + TCA** : Interface moderne avec The Composable Architecture
- **OSLog** : Système de logging structuré par catégorie
- **Actor-based Services** : Gestion thread-safe des opérations async
- **@Shared State** : Persistance avec le pattern Sharing de TCA
- **Swift Testing** : Suite de tests avec le nouveau framework

### Structure du projet
```
ApertureTokensManager/
├── App/                          # Point d'entrée
├── Components/                   # Composants UI réutilisables
│   ├── ActionCard.swift          # Carte d'action avec Liquid Glass
│   ├── ColorPreviewComponents.swift # Prévisualisation des couleurs
│   ├── DropZone.swift            # Zone de drag & drop
│   ├── HistoryRow.swift          # Ligne d'historique
│   ├── RecentHistoryView.swift   # Historique récent
│   ├── SearchField.swift         # Champ de recherche avec Cmd+F
│   ├── SectionComponents.swift   # Composants de section
│   ├── StatCard.swift            # Carte de statistique
│   ├── TokenTree.swift           # Arborescence de tokens
│   ├── UnifiedHistoryView.swift  # Timeline d'historique
│   └── ViewModifiers.swift       # Modificateurs (Liquid Glass adaptatif)
├── Extensions/                   # Extensions Swift
│   ├── Color+Hex.swift           # Conversion hex ↔ Color + ColorDelta
│   ├── SharedKeys.swift          # Clés @Shared pour persistance
│   ├── String+Date.swift         # Formatage de dates
│   └── UTType+Extensions.swift   # Types de fichiers supportés
├── Features/                     # Features TCA
│   ├── App/                      # Coordination des onglets
│   ├── Home/                     # Accueil avec stats et historique
│   ├── Import/                   # Import et export de tokens
│   ├── Compare/                  # Comparaison de versions
│   ├── Analysis/                 # Analyse d'utilisation
│   ├── Settings/                 # Paramètres de l'application
│   ├── TokenBrowser/             # Navigation dans les tokens
│   └── Tutorial/                 # Tutoriel de démarrage
├── Helpers/                      # Utilitaires
│   ├── AnalysisReportFormatter.swift # Formatage des rapports
│   ├── FuzzyMatchingHelpers.swift # Algorithmes de similarité
│   ├── TokenHelpers.swift        # Manipulation de tokens
│   └── TokenUsageHelpers.swift   # Détection d'usages Swift
├── Models/                       # Modèles de données
│   ├── Constants.swift           # Constantes UI et métier
│   ├── DesignSystemBase.swift    # Base du design system
│   ├── HistoryEntry.swift        # Entrées d'historique
│   ├── PreviewData.swift         # Données pour les previews
│   ├── TokenComparison.swift     # Résultats de comparaison
│   ├── TokenExport.swift         # Format d'export Figma
│   ├── TokenNode.swift           # Structure d'un token
│   └── UsageAnalysis.swift       # Rapport d'analyse
└── Services/                     # Services métier
    ├── FileService/              # Lecture de fichiers JSON
    ├── ExportService/            # Export XCAssets + Swift
    ├── ComparisonService/        # Comparaison de tokens
    ├── SuggestionService/        # Suggestions de remplacement
    ├── UsageService/             # Analyse d'utilisation
    ├── HistoryService/           # Gestion de l'historique
    └── LoggingService/           # Logging OSLog centralisé
```

### Pattern TCA
Chaque feature suit une structure cohérente :
```
Feature/
├── FeatureName.swift              # State + Actions + Reducer
├── FeatureName+View.swift         # Vue SwiftUI avec @ViewAction
└── Actions/
    ├── FeatureName+ViewActions.swift      # Actions utilisateur
    ├── FeatureName+InternalActions.swift  # Résultats async
    └── FeatureName+AnalyticsActions.swift # Logging séparé
```

### Hiérarchie des Actions
```swift
enum Action: BindableAction, ViewAction {
  case binding(BindingAction<State>)
  case analytics(Analytics)  // Logging séparé
  case `internal`(Internal)  // Résultats async
  case view(View)            // Actions utilisateur
  case delegate(Delegate)    // Communication cross-feature
}
```

### Filtres d'export
L'application supporte des filtres persistants pour l'export :
- **Tokens commençant par #** : Exclut les tokens de type primitive
- **Tokens finissant par _hover** : Exclut les états hover
- **Groupe Utility** : Exclut le groupe utilitaire complet

## 🧪 Tests

```bash
# Lancer tous les tests
xcodebuild test -scheme ApertureTokensManager

# Tests disponibles (81 tests)
- FuzzyMatchingHelpersTests (24 tests)
- TokenUsageHelpersTests (18 tests)
- TokenHelpersTests (17 tests)
- SuggestionServiceTests (9 tests)
- ComparisonServiceTests (11 tests)
```

## 🎨 Design System

L'application utilise **Liquid Glass** (macOS 26) :
- `.buttonStyle(.glass(.regular.tint(.blue)))` pour les boutons
- `.glassEffect()` pour les conteneurs
- Design moderne et cohérent avec macOS

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :
- Ouvrir des issues pour signaler des bugs
- Proposer des améliorations
- Soumettre des pull requests

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 🔗 Liens utiles

- [Plugin Figma Multibrand Token Exporter](https://www.figma.com/community/plugin/1601261816129528282/multibrand-token-exporter)
- [Documentation TCA](https://github.com/pointfreeco/swift-composable-architecture)
- [Figma Variables](https://help.figma.com/hc/en-us/articles/15339657135383-Guide-to-variables-in-Figma)
- [Xcode Color Assets](https://developer.apple.com/documentation/xcode/customizing-the-appearance-of-your-app)

---

Made with ❤️ for designers and developers who believe in a better design-to-code workflow.
