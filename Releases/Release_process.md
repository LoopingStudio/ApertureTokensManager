# Release ApertureTokensManager

## Checklist

- [ ] Changer la version dans le projet Xcode
- [ ] Archiver (Product → Archive)
- [ ] Exporter vers `1.X.X/`
- [ ] Ouvrir DMG Canvas, update le .app
- [ ] Exporter le DMG dans `Releases/`
- [ ] Créer le fichier `ApertureTokensManager.md` avec les release notes

## Générer l'appcast

1. Dans Xcode : clic droit sur le package Sparkle → **Show in Finder**
2. Remonter dans `../artifacts/sparkle/Sparkle`
3. Lancer :
   ```bash
   ./bin/generate_appcast ~/PATH_TO/ApertureTokensManager/Releases/
   ```

## Publier

- [ ] Push l'appcast.xml et le DMG sur GitHub
- [ ] Tester la mise à jour depuis une ancienne version
