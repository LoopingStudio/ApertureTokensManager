# Todo

## Completed

### [2026-02-06] Feature: Recherche dans TokenTree

- [x] Ajouter `searchText` dans `ImportFeature.State`
- [x] Ajouter `searchText` dans `TokenBrowserFeature.State`
- [x] Modifier `TokenTree` pour accepter `searchText` et filtrer les nodes
- [x] Créer `TokenTreeSearchHelper` avec filtrage et highlight
- [x] Auto-expand des parents quand enfants matchent
- [x] Ajouter champ de recherche dans `ImportFeature+View`
- [x] Ajouter champ de recherche dans `TokenBrowserFeature+View`
- [x] Build et vérification

**Résultat**: Recherche fonctionnelle dans l'arbre de tokens avec filtrage en temps réel, auto-expansion des groupes parents, et highlight du texte recherché en violet.

---

### [2026-02-06] Refactoring: Dashboard → Home (Accueil)

- [x] Renommer `DashboardFeature` → `HomeFeature`
- [x] Renommer `DashboardView` → `HomeView`
- [x] Mettre à jour `AppFeature` (Tab.dashboard → Tab.home)
- [x] Mettre à jour label onglet "Accueil" avec icône `house.fill`

**Résultat**: Nomenclature plus claire, cohérente avec le rôle de la vue.

---

### [2026-02-06] UI: Implémentation Liquid Glass (macOS 26)

- [x] `ActionCard` - `.buttonStyle(.glass(.regular.tint(color)))`
- [x] `StatCard` - `.glassEffect()` pour statique, `.buttonStyle(.glass)` pour interactif
- [x] Boutons dans `HomeFeature`, `ImportFeature`, `CompareFeature`, `AnalysisFeature`
- [x] Nettoyage `ViewModifiers.swift` (suppression styles custom obsolètes)

**Résultat**: Design moderne avec effets Liquid Glass sur les cartes et boutons.

---

### [2026-02-06] Feature: Suggestions intelligentes avec fuzzy matching

- [x] Créer `FuzzyMatchingHelpers.swift` avec algorithmes de similarité
- [x] Ajouter `AutoSuggestion` model dans `TokenComparison.swift`
- [x] Créer `SuggestionService` (actor) et `SuggestionClient`
- [x] Intégrer dans `CompareFeature` avec `@Dependency`
- [x] Ajouter actions `suggestionsComputed`, `acceptAutoSuggestion`, `rejectAutoSuggestion`
- [x] Mettre à jour `RemovedTokensView` avec UI de confiance
- [x] Refactorer hiérarchie: Couleur (50%) > Contexte d'usage (30%) > Structure (20%)
- [x] Ajouter marqueurs sémantiques: `bg`, `fg`, `hover`, `solid`, `surface`, etc.
- [x] Build et vérification preview

**Résultat**: Feature fonctionnelle avec suggestions automatiques affichées dans l'onglet "Supprimés" de la comparaison. Score de confiance visible avec code couleur (vert >70%, orange 50-70%, gris <50%).

---

### [2026-02-06] Feature: Token Usage Analysis

- [x] Créer `TokenUsageHelpers.swift` - Parsing Swift et regex pour détecter les usages
- [x] Créer `UsageAnalysis.swift` model - TokenUsageReport, UsedToken, OrphanedToken
- [x] Créer `UsageService` (actor) et `UsageClient`
- [x] Créer `AnalysisFeature` - TCA reducer avec State/Actions
- [x] Créer `AnalysisFeature+ViewActions.swift` et `AnalysisFeature+InternalActions.swift`
- [x] Créer `AnalysisFeature+View.swift` - UI de configuration avec sélection de dossiers
- [x] Créer `UsageOverviewView.swift` - Vue d'ensemble avec statistiques
- [x] Créer `UsedTokensListView.swift` - Liste des tokens utilisés avec détails
- [x] Créer `OrphanedTokensListView.swift` - Liste des tokens orphelins par catégorie
- [x] Intégrer dans `AppFeature` - Nouvel onglet "Analyser"
- [x] Build et vérification

**Résultat**: Nouvel onglet "Analyser" permettant de scanner des projets Swift pour détecter l'utilisation des tokens. Affiche les tokens utilisés avec leurs occurrences (fichier, ligne, contexte) et les tokens orphelins groupés par catégorie.

---

### [2026-02-06] Quick Wins: Recherche améliorée + Persistance

- [x] Créer composant `SearchField` réutilisable avec support `FocusState`
- [x] Ajouter `SearchFocusModifier` pour raccourci Cmd+F
- [x] Intégrer dans `ImportFeature+View` et `TokenBrowserFeature+View`
- [x] Ajouter `countFilteredTokens` dans `TokenTreeSearchHelper`
- [x] Afficher compteur "X / Y tokens" pendant recherche
- [x] Message "Aucun résultat" quand recherche vide
- [x] Rendre `ScanDirectory` `Codable` avec gestion security-scoped bookmarks
- [x] Ajouter `SharedKey` pour `analysisDirectories` avec `FileStorage`
- [x] Utiliser `@Shared(.analysisDirectories)` dans `AnalysisFeature.State`
- [x] Résolution des bookmarks au `onAppear` pour restaurer URLs valides
- [x] Build et vérification

**Résultat**: Cmd+F focus sur la recherche, compteur de résultats visible, et dossiers d'analyse persistés entre les lancements de l'app.

---

### [2026-02-08] Feature: Historique unifié dans Accueil

- [x] Créer `UnifiedHistoryItem` enum dans `HistoryEntry.swift`
- [x] Créer `UnifiedHistoryView.swift` composant avec filtre (Tout/Imports/Comparaisons)
- [x] Ajouter `@Shared` histories dans `HomeFeature.State`
- [x] Ajouter computed property `unifiedHistory` avec merge et tri par date
- [x] Ajouter actions `historyFilterChanged` et `historyItemTapped`
- [x] Intégrer dans `HomeFeature+View.swift`
- [x] Ajouter delegate actions pour navigation vers Import/Compare
- [x] Créer actions internes `loadFromHistoryEntry` dans Import et Compare
- [x] Gérer navigation dans `AppFeature`
- [x] Build et vérification

**Résultat**: Section "Activité récente" dans l'accueil avec timeline unifiée des imports et comparaisons. Clic sur un item ouvre la feature correspondante et charge le fichier.

---

### [2026-02-08] Qualité: Tests unitaires avec Swift Testing

- [x] Corriger test existant (`assert` → `#expect`)
- [x] Créer `FuzzyMatchingHelpersTests.swift` (24 tests)
- [x] Créer `TokenUsageHelpersTests.swift` (18 tests)
- [x] Créer `SuggestionServiceTests.swift` (9 tests)
- [x] Créer `TokenHelpersTests.swift` (17 tests)
- [x] Créer `ComparisonServiceTests.swift` (11 tests)
- [x] Build et exécution - 81 tests passent

**Résultat**: Suite de tests complète couvrant les Helpers (FuzzyMatching, TokenUsage, Token) et Services (Suggestion, Comparison). Utilise le framework Swift Testing avec `@Suite`, `@Test`, `#expect`, `#require`.

---

### [2026-02-08] Refactoring: TCA conventions

- [x] Remplacer `.run { send in await send() }` par `.concatenate()` dans `ImportFeature+InternalActions`
- [x] Créer actions `internal.loadFromHistoryEntry` pour Import et Compare
- [x] View actions délèguent vers internal actions (évite duplication)

**Résultat**: Meilleure conformité aux conventions TCA - view actions = user interactions, internal actions = async results et cross-feature.

---

### [2026-02-08] Feature: Système de Logging avec OSLog

- [x] Créer `Logger.swift` - `AppLogger` enum avec loggers par catégorie (Import, Compare, Analysis, Export, etc.)
- [x] Créer `LogEvent` struct pour événements structurés (userAction, systemEvent, error, performance)
- [x] Créer `LoggingService` actor avec toute la logique de logging
- [x] Créer `LoggingClient` TCA avec `liveValue`, `testValue`, `previewValue`
- [x] Ajouter actions `Analytics` dans tous les reducers (Import, Compare, Analysis, Home)
- [x] Créer fichiers `*+AnalyticsActions.swift` pour chaque feature
- [x] Intégrer logging dans les services (File, Export, Comparison, Suggestion, Usage)
- [x] Build et vérification

**Résultat**: Système de logging complet avec OSLog, actions Analytics séparées dans chaque reducer (conformité TCA), et logging automatique dans tous les services.

---

## En cours

_Aucune tâche en cours_

---

## Backlog / Roadmap

### 🎯 Quick Wins (Facile, impact immédiat)

1. **Export des résultats d'analyse**
   - Bouton "Exporter" dans UsageOverviewView
   - Format Markdown ou CSV avec tokens utilisés/orphelins

---

### 🔧 Améliorations UX (Moyen)

5. **Recherche dans CompareFeature**
   - Ajouter un champ de recherche au-dessus des listes dans Added/Removed/Modified
   - Filtrer les tokens par nom ou path
   - Utile quand on compare des fichiers avec 100+ changements
   - Réutiliser le pattern de `TokenTreeSearchHelper` pour le highlight

6. **Recherche dans AnalysisFeature**
   - Onglet "Utilisés" : filtrer par nom de token ou par fichier source
   - Onglet "Orphelins" : filtrer par nom ou catégorie
   - Permettre de trouver rapidement "où est utilisé bgBrandSolid ?"

7. **Drag & Drop global avec routing intelligent**
   - **Actuellement** : Le drag & drop ne marche que sur les DropZones spécifiques
   - **Amélioration** : Détecter un fichier JSON droppé n'importe où dans l'app
   - Si on est sur Accueil → proposer "Importer" ou "Comparer avec la base"
   - Si on est sur Comparer avec un slot vide → remplir le slot
   - Si on est sur Importer → charger le fichier
   - Feedback visuel : overlay "Déposez pour importer" sur toute la fenêtre

8. **Notifications système (UserNotifications)**
   - Export terminé → "Design System exporté vers ~/Desktop/ApertureExport"
   - Analyse terminée → "Analyse terminée : 45 tokens utilisés, 12 orphelins"
   - Clic sur la notification → ouvrir l'app sur l'onglet concerné
   - Utile quand l'app est en arrière-plan pendant un export long

9. ~~**Historique unifié dans Accueil**~~ ✅ _Fait le 2026-02-08_

---

### 🚀 Nouvelles Features (Plus complexe)

10. **Diff visuel des couleurs modifiées**
    - Dans ModifiedTokensView, afficher les couleurs old/new côte à côte
    - Mini preview : `[██ #FF0000] → [██ #FF5500]`
    - Animation hover : morphing progressif de l'ancienne vers la nouvelle couleur
    - Calcul du delta : "Rouge +10%, Luminosité -5%"
    - Utile pour valider visuellement si le changement est intentionnel

11. **Export vers Figma Variables**
    - Générer un fichier JSON compatible avec l'import Figma Variables
    - Mapper les modes (Legacy/NewBrand × Light/Dark) vers les modes Figma
    - Support des collections (ex: "Brand Colors", "Semantic Colors")
    - Documentation : https://www.figma.com/developers/api#variables
    - Workflow : Designer exporte de Figma → Dev importe dans l'app → Dev réexporte vers Figma pour sync

12. **Validation accessibilité WCAG**
    - Pour chaque token de type "text" ou "foreground", calculer le contraste avec son background associé
    - Niveaux : AA (4.5:1 pour texte normal), AAA (7:1)
    - Afficher des warnings : "⚠️ fgBrandSubtle sur bgBrandSolid = 3.2:1 (échec AA)"
    - Vue dédiée "Accessibilité" ou badge dans TokenDetailView
    - Algorithme : formule WCAG 2.1 pour le contrast ratio

13. **Intégration Git (avancé)**
    - Pointer vers un repo Git contenant le fichier de tokens
    - Afficher l'historique des commits qui ont modifié le fichier
    - Pour chaque commit : voir les tokens ajoutés/supprimés/modifiés
    - Comparer deux commits entre eux
    - Utilise `git log --follow` et `git diff` en shell
    - Cas d'usage : "Qui a supprimé bgLegacyPrimary et quand ?"

14. **Preview Dark Mode dans l'app**
    - Toggle dans la toolbar pour basculer l'aperçu des couleurs en dark mode
    - TokenDetailView : afficher Light et Dark côte à côte
    - TokenTree : option pour voir les swatches en mode Dark
    - Ne change pas le thème de l'app, juste l'aperçu des tokens

15. **Import depuis URL distante**
    - Champ "URL" dans ImportView en plus du drag & drop
    - Support : HTTPS, GitHub raw URLs, S3 presigned URLs
    - Cache local avec invalidation (ETag/Last-Modified)
    - Polling optionnel : "Vérifier les mises à jour toutes les X heures"
    - Cas d'usage : CI/CD publie le fichier tokens sur un CDN, l'app le récupère automatiquement

---

### 🏗️ Architecture & Qualité

16. **Tests unitaires** _(partiellement fait)_
    - [x] Tests pour les Helpers (FuzzyMatching, TokenUsage, Token)
    - [x] Tests pour les Services (Suggestion, Comparison)
    - [ ] Tests pour les Reducers avec `TestStore`
    - [ ] Tests pour les autres Services (FileService, ExportService, History, Usage)

17. **Tests UI**
    - Tests de snapshot pour les vues principales
    - Tests d'intégration pour les flows critiques

18. **Documentation**
    - README avec instructions d'installation
    - Documentation du format de tokens supporté

19. **Localisation**
    - Extraire les strings vers `Localizable.strings`
    - Support anglais/français

20. **Performance**
    - Lazy loading pour les très gros fichiers de tokens
    - Virtualisation de la liste dans TokenTree

---
