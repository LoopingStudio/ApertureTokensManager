import Foundation
import AppKit
import UniformTypeIdentifiers
import Dependencies

actor ComparisonService {
  @Dependency(\.fileClient) var fileClient
  
  func compareTokens(oldTokens: [TokenNode], newTokens: [TokenNode]) async -> ComparisonChanges {
    let oldFlat = flattenTokens(oldTokens)
    let newFlat = flattenTokens(newTokens)
    
    // Créer des dictionnaires pour la comparaison rapide par chemin
    let oldDict = Dictionary(uniqueKeysWithValues: oldFlat.map { ($0.path ?? $0.name, $0) })
    let newDict = Dictionary(uniqueKeysWithValues: newFlat.map { ($0.path ?? $0.name, $0) })
    
    // Trouver les tokens ajoutés, supprimés et modifiés
    let added = findAddedTokens(oldDict: oldDict, newDict: newDict)
    let removed = findRemovedTokens(oldDict: oldDict, newDict: newDict)
    let modified = findModifiedTokens(oldDict: oldDict, newDict: newDict)
    
    let changes = ComparisonChanges(
      added: added,
      removed: removed,
      modified: modified
    )
    
    return changes
  }
  
  // MARK: - Private Methods
  
  private func flattenTokens(_ nodes: [TokenNode]) -> [TokenNode] {
    var result: [TokenNode] = []
    
    func addTokensRecursively(_ nodes: [TokenNode]) {
      for node in nodes {
        if node.type == .token {
          result.append(node)
        }
        if let children = node.children {
          addTokensRecursively(children)
        }
      }
    }
    
    addTokensRecursively(nodes)
    return result
  }
  
  private func findAddedTokens(oldDict: [String: TokenNode], newDict: [String: TokenNode]) -> [TokenSummary] {
    return newDict.values.compactMap { newToken in
      guard !oldDict.keys.contains(newToken.path ?? newToken.name) else { return nil }
      return TokenSummary(from: newToken)
    }
  }
  
  private func findRemovedTokens(oldDict: [String: TokenNode], newDict: [String: TokenNode]) -> [TokenSummary] {
    return oldDict.values.compactMap { oldToken in
      guard !newDict.keys.contains(oldToken.path ?? oldToken.name) else { return nil }
      return TokenSummary(from: oldToken)
    }
  }
  
  private func findModifiedTokens(oldDict: [String: TokenNode], newDict: [String: TokenNode]) -> [TokenModification] {
    var modifications: [TokenModification] = []
    
    for (path, oldToken) in oldDict {
      guard let newToken = newDict[path],
            let oldModes = oldToken.modes,
            let newModes = newToken.modes else { continue }
      
      let colorChanges = findColorChanges(oldModes: oldModes, newModes: newModes)
      
      if !colorChanges.isEmpty {
        let modification = TokenModification(
          tokenPath: path,
          tokenName: oldToken.name,
          colorChanges: colorChanges
        )
        modifications.append(modification)
      }
    }
    
    return modifications
  }
  
  private func findColorChanges(oldModes: TokenThemes, newModes: TokenThemes) -> [ColorChange] {
    var changes: [ColorChange] = []
    
    // Comparer Legacy
    changes.append(contentsOf: compareThemes(
      oldTheme: oldModes.legacy,
      newTheme: newModes.legacy,
      brandName: Brand.legacy
    ))
    
    // Comparer New Brand
    changes.append(contentsOf: compareThemes(
      oldTheme: oldModes.newBrand,
      newTheme: newModes.newBrand,
      brandName: Brand.newBrand
    ))
    
    return changes
  }
  
  private func compareThemes(
    oldTheme: TokenThemes.Appearance?,
    newTheme: TokenThemes.Appearance?,
    brandName: String
  ) -> [ColorChange] {
    guard let oldTheme = oldTheme, let newTheme = newTheme else { return [] }
    
    var changes: [ColorChange] = []
    
    // Compare light theme
    let oldLight = oldTheme.light?.hex
    let newLight = newTheme.light?.hex
    if oldLight != newLight && oldLight != nil && newLight != nil {
      changes.append(ColorChange(
        brandName: brandName,
        theme: ThemeType.light,
        oldColor: oldLight!,
        newColor: newLight!
      ))
    }
    
    // Compare dark theme  
    let oldDark = oldTheme.dark?.hex
    let newDark = newTheme.dark?.hex
    if oldDark != newDark && oldDark != nil && newDark != nil {
      changes.append(ColorChange(
        brandName: brandName,
        theme: ThemeType.dark,
        oldColor: oldDark!,
        newColor: newDark!
      ))
    }
    
    return changes
  }
  
  @MainActor
  func exportToNotion(
    _ changes: ComparisonChanges,
    oldMetadata: TokenMetadata,
    newMetadata: TokenMetadata
  ) async throws {
    let markdownContent = await createNotionMarkdown(
      changes: changes,
      oldMetadata: oldMetadata,
      newMetadata: newMetadata
    )

    let data = markdownContent.data(using: .utf8)!
    _ = try await fileClient.saveToFile(
      data,
      "comparison-export-notion.md", 
      .plainText,
      "Exporter la comparaison pour Notion"
    )
  }
  
  private func createNotionMarkdown(
    changes: ComparisonChanges,
    oldMetadata: TokenMetadata,
    newMetadata: TokenMetadata
  ) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "fr_FR")
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .short
    let exportDate = dateFormatter.string(from: Date())
    
    var markdown = ""
    
    // En-tête
    markdown += "# Rapport de Comparaison des Tokens\n\n"
    markdown += "**Date d'export:** \(exportDate)\n\n"
    
    // Informations des fichiers
    markdown += "## Informations des Fichiers\n\n"
    markdown += "| Version | Date d'export | Version | Générateur |\n"
    markdown += "|---------|---------------|---------|-------------|\n"
    markdown += "| Ancienne | \(oldMetadata.exportedAt.formatFrenchDate) | \(oldMetadata.version) |\n"
    markdown += "| Nouvelle | \(newMetadata.exportedAt.formatFrenchDate) | \(newMetadata.version) |\n\n"

    // Résumé
    markdown += "## Résumé des Changements\n\n"
    markdown += "- **\(changes.added.count)** tokens ajoutés\n"
    markdown += "- **\(changes.removed.count)** tokens supprimés\n"
    markdown += "- **\(changes.modified.count)** tokens modifiés\n\n"
    
    // Tokens ajoutés
    if !changes.added.isEmpty {
      markdown += "## ✅ Tokens Ajoutés (\(changes.added.count))\n\n"
      for token in changes.added {
        markdown += "### \(token.name)\n"
        markdown += "**Chemin:** `\(token.path)`\n\n"
        if let modes = token.modes {
          markdown += addColorInfo(modes: modes)
        }
        markdown += "\n---\n\n"
      }
    }
    
    // Tokens supprimés
    if !changes.removed.isEmpty {
      markdown += "## ❌ Tokens Supprimés (\(changes.removed.count))\n\n"
      for token in changes.removed {
        markdown += "### \(token.name)\n"
        markdown += "**Chemin:** `\(token.path)`\n\n"
        if let modes = token.modes {
          markdown += addColorInfo(modes: modes)
        }
        markdown += "\n---\n\n"
      }
    }
    
    // Tokens modifiés
    if !changes.modified.isEmpty {
      markdown += "## ✏️ Tokens Modifiés (\(changes.modified.count))\n\n"
      for modification in changes.modified {
        markdown += "### \(modification.tokenName)\n"
        markdown += "**Chemin:** `\(modification.tokenPath)`\n\n"
        
        for change in modification.colorChanges {
          markdown += "**\(change.brandName) - \(change.theme):**\n"
          markdown += "- ❌ Avant: `\(change.oldColor)`\n"
          markdown += "- ✅ Après: `\(change.newColor)`\n\n"
        }
        markdown += "\n---\n\n"
      }
    }
    
    return markdown
  }
  
  private func addColorInfo(modes: TokenThemes) -> String {
    var colorInfo = ""
    
    if let legacy = modes.legacy {
      colorInfo += "**Legacy:**\n"
      if let light = legacy.light {
        colorInfo += "- Light: `\(light.hex)` (primitive: `\(light.primitiveName)`)\n"
      }
      if let dark = legacy.dark {
        colorInfo += "- Dark: `\(dark.hex)` (primitive: `\(dark.primitiveName)`)\n\n"
      }
    }
    
    if let newBrand = modes.newBrand {
      colorInfo += "**New Brand:**\n"
      if let light = newBrand.light {
        colorInfo += "- Light: `\(light.hex)` (primitive: `\(light.primitiveName)`)\n"
      }
      if let dark = newBrand.dark {
        colorInfo += "- Dark: `\(dark.hex)` (primitive: `\(dark.primitiveName)`)\n\n"
      }
    }
    
    return colorInfo
  }
}
