# Automatiser les releases macOS avec Sparkle + GitHub Actions

Guide complet pour mettre en place un pipeline de release automatisé :
tag git → build → sign → DMG → notarize → appcast → GitHub Release.

---

## Prérequis

- Un projet Xcode macOS (`.xcodeproj`) avec Sparkle intégré via SPM
- Un compte Apple Developer avec un certificat **Developer ID Application**
- Un repo GitHub avec GitHub Pages activé

---

## 1. Version.xcconfig

Créer un fichier `Version.xcconfig` dans le projet (peu importe l'emplacement) :

```
MARKETING_VERSION = 1.0.0
CURRENT_PROJECT_VERSION = 1
```

### Référencer dans Xcode

1. Drag & drop `Version.xcconfig` dans le navigateur Xcode
2. Project (pas target) → onglet **Info** → section **Configurations**
3. Pour chaque configuration (Debug / Release) du **target app** (pas Tests) :
   sélectionner `Version` dans le dropdown
4. Target app → **Build Settings** → chercher `MARKETING_VERSION` et `CURRENT_PROJECT_VERSION`
   → **supprimer les deux** (touche Delete) pour que les valeurs viennent du xcconfig

Vérifier : Build Settings doit afficher les valeurs en vert (= héritées du xcconfig).

---

## 2. Dossier Releases

Créer le dossier à la racine du repo :

```
Releases/
├── MonApp.md          ← Release notes (à écrire avant chaque release)
├── appcast.xml        ← Généré automatiquement par le workflow
└── MonApp.dmg         ← Généré automatiquement par le workflow
```

Créer un premier `Releases/MonApp.md` :

```markdown
### Nouveautés de la version 1.0.0

- Version initiale
```

---

## 3. GitHub Pages

1. GitHub → repo → Settings → Pages
2. Source : **Deploy from a branch**
3. Branch : `main`, dossier : `/ (root)`
4. L'appcast sera accessible à :
   `https://VOTRE_ORG.github.io/VOTRE_REPO/Releases/appcast.xml`

---

## 4. Secrets GitHub

GitHub → repo → Settings → Secrets and variables → Actions → New repository secret

| Secret | Comment l'obtenir |
|--------|------------------|
| `DEV_ID_P12_BASE64` | Keychain Access → exporter le certificat "Developer ID Application" en .p12 → `base64 -i MonCert.p12 \| pbcopy` |
| `DEV_ID_P12_PASSWORD` | Le mot de passe choisi à l'export du .p12 |
| `SIGNING_IDENTITY` | Le nom exact du certificat, ex : `Developer ID Application: Mon Nom (TEAMID123)` |
| `TEAM_ID` | L'identifiant d'équipe Apple à 10 caractères (visible sur developer.apple.com) |
| `APPLE_ID` | L'email du compte Apple Developer |
| `APPLE_APP_PASSWORD` | Généré sur [appleid.apple.com](https://appleid.apple.com) → Connexion et sécurité → Mots de passe pour les apps |
| `SPARKLE_PRIVATE_KEY` | Le contenu du fichier exporté par `generate_keys -x` |

### Exporter le certificat Developer ID

1. Ouvrir **Keychain Access**
2. Onglet **Mes certificats**
3. Déplier le "Developer ID Application: ..." 
4. Clic droit sur la clé privée -→ **Exporter...**
5. Format : `.p12`, choisir un mot de passe
6. Encoder en base64 :
   ```bash
   base64 -i MonCertificat.p12 | pbcopy
   ```
7. Coller dans le secret `DEV_ID_P12_BASE64`

---

## 5. Fichiers workflow

### Le workflow réutilisable

Copier `sparkle-release.yml` dans `.github/workflows/` du repo.
Ce fichier ne contient aucune valeur spécifique au projet — il est identique pour toutes les apps.

### Le workflow caller (spécifique à l'app)

Créer `.github/workflows/release.yml` :

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

permissions:
  contents: write

jobs:
  release:
    uses: ./.github/workflows/sparkle-release.yml
    with:
      app_name: MonApp                    # Nom du .xcodeproj (sans l'extension)
      dmg_volume_name: "Mon App"          # Nom affiché quand le DMG est monté
      github_pages_url: "https://monorg.github.io/monrepo"
    secrets:
      DEV_ID_P12_BASE64: ${{ secrets.DEV_ID_P12_BASE64 }}
      DEV_ID_P12_PASSWORD: ${{ secrets.DEV_ID_P12_PASSWORD }}
      SIGNING_IDENTITY: ${{ secrets.SIGNING_IDENTITY }}
      TEAM_ID: ${{ secrets.TEAM_ID }}
      APPLE_ID: ${{ secrets.APPLE_ID }}
      APPLE_APP_PASSWORD: ${{ secrets.APPLE_APP_PASSWORD }}
      SPARKLE_PRIVATE_KEY: ${{ secrets.SPARKLE_PRIVATE_KEY }}
```

### Inputs optionnels

| Input | Défaut | Description |
|-------|--------|-------------|
| `scheme` | = `app_name` | Nom du scheme Xcode si différent |
| `link_url` | URL du repo | URL du site de l'app |
| `releases_dir` | `Releases` | Dossier pour le DMG et l'appcast |
| `max_appcast_versions` | `0` (illimité) | Nombre max de versions dans l'appcast |
| `runner` | `macos-15` | Runner GitHub Actions |

---

## 6. Releaser

### Avant la release

1. Mettre à jour les release notes dans `Releases/MonApp.md`
2. Commit et push sur `main`

### Lancer la release

```bash
git tag v1.0.1
git push origin v1.0.1
```

Le workflow va automatiquement :

1. Lire la version depuis le tag (`1.0.1`)
2. Incrémenter le build number dans `Version.xcconfig`
3. Build + code sign avec Developer ID
4. Créer le DMG avec drag & drop vers /Applications
5. Notarize + staple le DMG
6. Mettre à jour l'appcast avec `generate_appcast`
7. Commit le xcconfig + DMG + appcast sur `main`
8. Créer une GitHub Release avec le DMG en téléchargement

### Vérifier

- GitHub → Actions → vérifier que le workflow est vert
- GitHub → Releases → le DMG est disponible
- `https://monorg.github.io/monrepo/Releases/appcast.xml` → le nouvel item apparaît
- Ouvrir l'app → Check for Updates → la mise à jour est proposée

---

## Checklist

```
[ ] Version.xcconfig créé et référencé dans Xcode
[ ] Build Settings : MARKETING_VERSION et CURRENT_PROJECT_VERSION supprimés du target
[ ] Dossier Releases/ avec MonApp.md et appcast.xml vide
[ ] GitHub Pages activé (branche main, dossier root)
[ ] 7 secrets GitHub configurés
[ ] sparkle-release.yml copié dans .github/workflows/
[ ] release.yml créé avec les valeurs de l'app
[ ] Premier test : git tag v1.0.0 && git push origin v1.0.0
```

---

## Troubleshooting

### Le build number ne s'incrémente pas

→ Vérifier que `MARKETING_VERSION` et `CURRENT_PROJECT_VERSION` sont **supprimés** des Build Settings du target (pas juste vides — supprimés avec la touche Delete). Les valeurs doivent venir du xcconfig.

### La notarization échoue

```
Error: Failed to notarize
```

→ Vérifier que le `APPLE_APP_PASSWORD` est un mot de passe d'app (pas le mot de passe du compte).
→ Vérifier que le `TEAM_ID` correspond bien au certificat Developer ID.
→ L'app doit avoir le Hardened Runtime activé.

### generate_appcast not found

```
::error::generate_appcast not found in Sparkle tools archive
```

→ La version de Sparkle dans `Package.resolved` n'a peut-être pas de binaire pré-compilé sur GitHub Releases (cas des betas). Vérifier que le tag existe sur https://github.com/sparkle-project/Sparkle/releases.

### Le push vers main est refusé

```
error: failed to push some refs
```

→ Si le repo a des branch protection rules, autoriser `github-actions[bot]` à push sans PR dans Settings → Branches → Branch protection rules.

### L'appcast n'est pas mis à jour sur GitHub Pages

→ GitHub Pages peut mettre quelques minutes à se déployer. Vérifier dans Settings → Pages → dernier déploiement.
→ Vider le cache du navigateur ou tester avec `curl -H "Cache-Control: no-cache"`.
