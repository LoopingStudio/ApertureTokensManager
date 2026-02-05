import AppKit
import Dependencies
import Foundation
import UniformTypeIdentifiers

actor ExportService {
  @Dependency(\.fileClient) var fileClient

  // MARK: - Constants
  private enum ExportFiles {
    static let colorsXCAssets = "Colors.xcassets"
    static let apertureColors = "Aperture+Colors.swift"
  }

  @MainActor
  func exportDesignSystem(nodes: [TokenNode]) async throws {
    let filtered = await filterEnabledNodes(nodes)

    guard let destinationURL = try await fileClient.pickDirectory("Choisissez où créer le design system") else { return }

    // Demander l'accès sécurisé au dossier
    let canAccess = destinationURL.startAccessingSecurityScopedResource()
    defer {
      if canAccess {
        destinationURL.stopAccessingSecurityScopedResource()
      }
    }
    
    do {
      // Créer le nom du dossier d'export avec la date
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-dd"
      let dateString = formatter.string(from: Date())
      let exportFolderName = "ApertureExport-\(dateString)"
      
      // Créer dans un dossier temporaire d'abord
      let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
      let exportTempURL = tempURL.appendingPathComponent(exportFolderName)
      try FileManager.default.createDirectory(at: exportTempURL, withIntermediateDirectories: true)
      
      // Créer la structure dans le temp
      try await createColorsXCAssets(from: filtered, at: exportTempURL)
      try await createApertureColorsSwift(from: filtered, at: exportTempURL)
      
      // Copier vers la destination finale
      let exportDestURL = destinationURL.appendingPathComponent(exportFolderName)
      
      // Supprimer le dossier existant s'il existe
      try? FileManager.default.removeItem(at: exportDestURL)
      
      // Copier le dossier d'export complet
      try FileManager.default.copyItem(at: exportTempURL, to: exportDestURL)
      
      // Nettoyer le temporaire
      try? FileManager.default.removeItem(at: tempURL)
      
      // Afficher une notification de succès
      let alert = NSAlert()
      alert.messageText = "Export réussi"
      alert.informativeText = "Le design system a été créé dans:\n\(exportDestURL.path)"
      alert.alertStyle = .informational
      alert.runModal()
      
    } catch {
      let alert = NSAlert()
      alert.messageText = "Erreur d'export"
      alert.informativeText = "Impossible de créer le design system:\n\(error.localizedDescription)"
      alert.alertStyle = .critical
      alert.runModal()
      throw error
    }
  }

  // Helper pur (hors de la struct pour être invisible)
  private func filterEnabledNodes(_ nodes: [TokenNode]) -> [TokenNode] {
    var result: [TokenNode] = []
    for node in nodes {
      if node.isEnabled {
        var newNode = node
        if let children = node.children {
          let filteredChildren = filterEnabledNodes(children)
          // On garde si c'est un groupe (même vide) ou s'il a des enfants valides
          if !filteredChildren.isEmpty || node.type == .group {
            newNode.children = filteredChildren
            result.append(newNode)
          }
        } else {
          result.append(newNode) // C'est une feuille activée
        }
      }
    }
    return result
  }
  
  // MARK: - Design System Export
  
  private func createColorsXCAssets(from nodes: [TokenNode], at baseURL: URL) async throws {
    let colorsURL = baseURL.appendingPathComponent(ExportFiles.colorsXCAssets)
    try FileManager.default.createDirectory(at: colorsURL, withIntermediateDirectories: true)
    
    // Contents.json racine
    let rootContents = """
    {
      "info" : {
        "author" : "xcode",
        "version" : 1
      }
    }
    """
    try rootContents.write(to: colorsURL.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
    
    // Collecter tous les tokens
    let allTokens = collectAllTokens(from: nodes)
    
    // Créer la structure pour chaque brand
    try await createBrandStructure(brand: Brand.legacy, tokens: allTokens, at: colorsURL)
    try await createBrandStructure(brand: Brand.newBrand, tokens: allTokens, at: colorsURL)
  }
  
  private func createBrandStructure(brand: String, tokens: [TokenNode], at parentURL: URL) async throws {
    let brandURL = parentURL.appendingPathComponent(brand)
    try FileManager.default.createDirectory(at: brandURL, withIntermediateDirectories: true)
    
    // Créer Contents.json pour chaque dossier
    let folderContents = """
    {
      "info" : {
        "author" : "xcode",
        "version" : 1
      },
      "properties" : {
        "provides-namespace" : true
      }
    }
    """
    try folderContents.write(to: brandURL.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)

    for token in tokens {
      guard let path = token.path, let modes = token.modes else { continue }

      // Vérifier si ce token a le thème pour cette brand
      let hasTheme = (brand == Brand.legacy && modes.legacy != nil) ||
                     (brand == Brand.newBrand && modes.newBrand != nil)
      guard hasTheme else { continue }
      
      // Créer la hiérarchie de dossiers basée sur le path
      let pathComponents = path.split(separator: "/")
      var currentURL = brandURL
      
      // Créer chaque niveau de dossier (sauf le dernier qui est le token)
      for component in pathComponents.dropLast() {
        currentURL = currentURL.appendingPathComponent(String(component))
        try FileManager.default.createDirectory(at: currentURL, withIntermediateDirectories: true)
        try folderContents.write(to: currentURL.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
      }
      
      // Créer le colorset dans le dernier dossier (currentURL contient maintenant le bon parent)
      try await createBrandColorSet(for: token, brand: brand, at: currentURL)
    }
  }
  
  private func createBrandColorSet(for token: TokenNode, brand: String, at parentURL: URL) async throws {
    guard let modes = token.modes else { return }
    
    let theme: TokenThemes.Appearance?
    switch brand {
    case Brand.legacy: theme = modes.legacy
    case Brand.newBrand: theme = modes.newBrand
    default: return
    }
    
    guard let theme else { return }
    
    let colorsetName = token.name.replacingOccurrences(of: " ", with: "-").lowercased()
    let colorsetURL = parentURL.appendingPathComponent("\(colorsetName).colorset")
    try FileManager.default.createDirectory(at: colorsetURL, withIntermediateDirectories: true)
    
    var colors: [[String: Any]] = []
    
    // Add light appearance if available
    if let lightValue = theme.light {
      colors.append([
        "color": [
          "color-space": "srgb",
          "components": hexToComponents(lightValue.hex)
        ],
        "idiom": "universal"
      ])
    }
    
    // Add dark appearance if available  
    if let darkValue = theme.dark {
      colors.append([
        "color": [
          "color-space": "srgb", 
          "components": hexToComponents(darkValue.hex)
        ],
        "idiom": "universal",
        "appearances": [[
          "appearance": "luminosity",
          "value": "dark"
        ]]
      ])
    }
    
    let contentsJSON: [String: Any] = [
      "colors": colors,
      "info": [
        "author": "xcode",
        "version": 1
      ]
    ]
    
    let jsonData = try JSONSerialization.data(withJSONObject: contentsJSON, options: [.prettyPrinted])
    try jsonData.write(to: colorsetURL.appendingPathComponent("Contents.json"))
  }
  
  private func createApertureColorsSwift(from nodes: [TokenNode], at baseURL: URL) async throws {
    let allTokens = collectAllTokens(from: nodes)
    
    // Grouper par catégorie
    let groupedTokens = Dictionary(grouping: allTokens) { token in
      guard let path = token.path else { return "Miscellaneous" }
      return String(path.split(separator: "/").first ?? "Miscellaneous")
    }
    
    var swiftContent = """
    import SwiftUI

    extension Aperture.Theme {
      public func color(_ token: Aperture.Foundations.Color) -> Color {
        // Dynamically prefixes the path with the active theme
        Color("\\(self.rawValue)/\\(token.rawValue)", bundle: .module)
      }
    }

    extension Aperture.Foundations {
      public enum Color: String, CaseIterable {
    
    """
    
    // Ajouter les couleurs par catégorie
    for (category, tokens) in groupedTokens.sorted(by: { $0.key < $1.key }) {
      swiftContent += "    // MARK: - \(category)\n"
      
      // Grouper par sous-catégorie (2ème niveau)
      let groupedBySubCategory = Dictionary(grouping: tokens) { token in
        guard let path = token.path else { return "Other" }
        let components = path.split(separator: "/")
        return components.count >= 2 ? String(components[1]) : "Other"
      }
      
      for (subCategory, subTokens) in groupedBySubCategory.sorted(by: { $0.key < $1.key }) {
        swiftContent += "    // \(subCategory)\n"
        
        for token in subTokens.sorted(by: { $0.name < $1.name }) {
          let enumCase = generateEnumCase(from: token)
          let pathValue = token.path ?? "\(category)/\(token.name)"
          swiftContent += "    case \(enumCase) = \"\(pathValue)\"\n"
        }
      }
      swiftContent += "\n"
    }
    
    swiftContent += """
      }
    }
    """
    
    let swiftURL = baseURL.appendingPathComponent(ExportFiles.apertureColors)
    try swiftContent.write(to: swiftURL, atomically: true, encoding: .utf8)
  }
  
  private func collectAllTokens(from nodes: [TokenNode]) -> [TokenNode] {
    var result: [TokenNode] = []
    
    func collect(_ nodes: [TokenNode]) {
      for node in nodes {
        if node.type == .token && node.modes != nil {
          result.append(node)
        }
        if let children = node.children {
          collect(children)
        }
      }
    }
    
    collect(nodes)
    return result
  }
  
  private func generateEnumCase(from token: TokenNode) -> String {
    let cleanName = token.name
      .replacingOccurrences(of: "-", with: " ")
      .replacingOccurrences(of: "_", with: " ")
    
    let components = cleanName.split(separator: " ")
    guard !components.isEmpty else { return "unknown" }
    
    let firstComponent = String(components[0]).lowercased()
    let otherComponents = components.dropFirst().map { String($0).capitalized }
    
    return firstComponent + otherComponents.joined()
  }
  
  private func hexToComponents(_ hex: String) -> [String: String] {
    let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    
    // Normaliser et extraire les composants
    let fullHex: String
    let alpha: String
    
    if cleanHex.count == 3 {
      fullHex = cleanHex.map { "\($0)\($0)" }.joined()
      alpha = "FF"
    } else if cleanHex.count == 6 {
      fullHex = cleanHex
      alpha = "FF"
    } else if cleanHex.count == 8 {
      fullHex = String(cleanHex.prefix(6))
      alpha = String(cleanHex.suffix(2))
    } else {
      fullHex = "000000"
      alpha = "FF"
    }
    
    let red = String(fullHex.prefix(2))
    let green = String(fullHex.dropFirst(2).prefix(2))
    let blue = String(fullHex.suffix(2))
    
    return [
      "red": "0x\(red)",
      "green": "0x\(green)", 
      "blue": "0x\(blue)",
      "alpha": "0x\(alpha)"
    ]
  }
}
