# Aperture Tokens Importer

Une application macOS pour importer, comparer et exporter des design tokens depuis Figma vers Xcode.

## 🎯 Vue d'ensemble

Aperture Tokens Importer est l'application compagnon du plugin Figma **ApertureExporter**. Elle permet de créer une chaîne complète de design tokens depuis Figma jusqu'à votre projet iOS/macOS.

### Workflow complet
1. **Figma** → Utiliser le plugin **ApertureExporter** pour exporter vos design tokens
2. **Import** → Glisser-déposer ou sélectionner les fichiers JSON générés
3. **Comparaison** → Comparer deux versions pour voir les changements
4. **Export** → Générer les fichiers Xcode (Colors.xcassets + Swift extensions)

## ✨ Fonctionnalités

### 📥 Import de Tokens
- **Drag & Drop** : Glissez simplement vos fichiers JSON dans l'app
- **Sélection de fichiers** : Interface native macOS pour choisir vos exports
- **Métadonnées** : Affichage des informations d'export (date, version, générateur)
- **Support multi-format** : Compatible avec les anciens et nouveaux formats d'export

### 🔍 Comparaison de Versions
- **Vue côte à côte** : Comparez facilement deux versions de vos tokens
- **Détection automatique** : Identifie les tokens ajoutés, supprimés et modifiés
- **Visualisation des changements** : Interface claire pour voir les différences
- **Changement de fichiers** : Possibilité d'inverser old/new si nécessaire
- **Confirmation manuelle** : Lancez la comparaison quand vous êtes prêt

### 📤 Export vers Xcode
- **Colors.xcassets** : Génération automatique des color sets Xcode
- **Extensions Swift** : Création d'extensions Color avec vos tokens
- **Structure hiérarchique** : Respect de l'organisation de vos tokens
- **Support multi-thèmes** : Gestion des différentes variantes (legacy, newBrand)
- **Filtrage intelligent** : Exportez uniquement les tokens activés

### 📋 Export Notion
- **Format Markdown** : Export des comparaisons dans un format lisible
- **Tableaux organisés** : Vue claire des modifications pour documentation
- **Métadonnées incluses** : Informations sur les versions comparées
- **Prêt pour Notion** : Format optimisé pour être collé dans Notion

## 🚀 Installation

1. Téléchargez la dernière version depuis les [Releases](../../releases)
2. Glissez l'application dans votre dossier Applications
3. Lancez l'application

## 🔧 Utilisation

### Import simple
1. Ouvrez l'onglet **"Token"**
2. Glissez votre fichier JSON ou cliquez sur **"Sélectionner un fichier"**
3. Explorez vos tokens dans l'arborescence
4. Activez/désactivez les tokens à exporter
5. Cliquez sur **"Exporter Design System"** pour générer les fichiers Xcode

### Comparaison de versions
1. Ouvrez l'onglet **"Comparaison"**
2. Importez votre **ancienne version** (Old)
3. Importez votre **nouvelle version** (New)
4. Cliquez sur **"Confirmer la comparaison"**
5. Explorez les changements détectés
6. Optionnel : Exportez vers Notion pour documentation

## 🔗 Intégration avec ApertureExporter

Cette application est conçue pour fonctionner avec le plugin Figma **ApertureExporter** qui :

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
    "generator": "ApertureExporter Plugin"
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

- **SwiftUI + TCA** : Interface moderne avec architecture The Composable Architecture
- **Actor-based Services** : Gestion sécurisée des opérations asynchrones
- **Separation of Concerns** : Services dédiés pour fichiers, export et comparaisons
- **@Shared State** : Persistance des filtres avec le pattern Sharing de TCA
- **macOS Native** : Intégration complète avec l'écosystème Apple

### Structure du projet
```
ApertureTokensManager/
├── App/                          # Point d'entrée de l'application
├── Components/                   # Composants UI réutilisables (DropZone, ColorPreview...)
├── Extensions/                   # Extensions utilitaires (Color+Hex, String+Date...)
├── Features/                     # Features TCA (Token, Compare)
│   ├── Token/
│   │   ├── Actions/              # Actions séparées (View, Internal, Binding)
│   │   ├── Views/                # Vues spécifiques (NodeRow, NodeTree, TokenDetail)
│   │   ├── TokenFeature.swift    # Reducer principal
│   │   └── TokenFeature+View.swift
│   └── Compare/
│       ├── Actions/
│       ├── Views/
│       ├── CompareFeature.swift
│       └── CompareFeature+View.swift
├── Helpers/                      # Utilitaires partagés (TokenHelpers)
├── Models/                       # Modèles de données (TokenNode, TokenExport...)
└── Services/                     # Services métier
    ├── ExportService/            # Export vers Xcode (XCAssets + Swift)
    ├── ComparisonService/        # Comparaison de versions
    ├── FileService/              # Gestion des fichiers
    └── HistoryService/           # Historique des imports
```

### Filtres d'export
L'application supporte des filtres persistants pour l'export :
- **Tokens commençant par #** : Exclut les tokens de type primitive
- **Tokens finissant par _hover** : Exclut les états hover
- **Groupe Utility** : Exclut le groupe utilitaire complet

## 🎨 Captures d'écran

### Vue Token
Interface d'import et d'exploration des tokens avec métadonnées.

### Vue Comparaison  
Comparaison côte à côte de deux versions avec détection des changements.

### Export Xcode
Génération automatique des fichiers Colors.xcassets et extensions Swift.

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :
- Ouvrir des issues pour signaler des bugs
- Proposer des améliorations  
- Soumettre des pull requests

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 🔗 Liens utiles

- [Plugin Figma ApertureExporter](# "Lien vers le plugin Figma")
- [Documentation Figma Variables](https://help.figma.com/hc/en-us/articles/15339657135383-Guide-to-variables-in-Figma)
- [Xcode Color Assets](https://developer.apple.com/documentation/xcode/customizing-the-appearance-of-your-app)

---

Made with ❤️ for designers and developers who believe in a better design-to-code workflow.