import Foundation

/// Helpers pour les algorithmes de fuzzy matching entre tokens
enum FuzzyMatchingHelpers {
  
  // MARK: - Path Similarity
  
  /// Compare deux paths de tokens (ex: "Background/Surface/Default" vs "Background/Surface/Primary")
  /// Retourne un score entre 0.0 et 1.0
  static func computePathSimilarity(_ path1: String, _ path2: String) -> Double {
    let components1 = path1.split(separator: "/").map(String.init)
    let components2 = path2.split(separator: "/").map(String.init)
    
    guard !components1.isEmpty, !components2.isEmpty else { return 0.0 }
    
    // Pénaliser les différences de profondeur
    let depthScore = min(Double(components1.count), Double(components2.count)) /
                     max(Double(components1.count), Double(components2.count))
    
    // Comparer chaque composant
    var componentScore = 0.0
    let maxComponents = max(components1.count, components2.count)
    
    for i in 0..<maxComponents {
      let comp1 = i < components1.count ? components1[i] : ""
      let comp2 = i < components2.count ? components2[i] : ""
      
      if comp1 == comp2 {
        componentScore += 1.0
      } else {
        componentScore += levenshteinSimilarity(comp1, comp2)
      }
    }
    componentScore /= Double(maxComponents)
    
    // Les premiers composants (catégories) sont plus importants
    return (depthScore * 0.3) + (componentScore * 0.7)
  }
  
  // MARK: - Usage Context Similarity
  
  /// Marqueurs sémantiques pour identifier le contexte d'usage d'un token
  /// Groupés par catégorie pour matcher des usages similaires
  private static let usageContextGroups: [[String]] = [
    // Fond/Background
    ["bg", "background", "surface", "fill", "canvas"],
    // Premier plan/Foreground
    ["fg", "foreground", "text", "label", "title", "content"],
    // Bordures/Contours
    ["border", "stroke", "outline", "divider", "separator"],
    // États interactifs
    ["hover", "hovered", "active", "pressed", "focus", "focused"],
    // États désactivés
    ["disabled", "inactive", "muted"],
    // Variantes de style
    ["solid", "filled", "ghost", "subtle", "tinted"],
    // Hiérarchie
    ["primary", "secondary", "tertiary"],
    // Feedback
    ["error", "warning", "success", "info", "danger"],
    // Éléments d'interface
    ["button", "input", "card", "modal", "overlay", "badge", "icon"]
  ]
  
  /// Compare le contexte d'usage entre deux tokens basé sur les marqueurs sémantiques
  /// Retourne un score entre 0.0 et 1.0
  static func computeUsageContextSimilarity(
    _ path1: String,
    _ name1: String,
    _ path2: String,
    _ name2: String
  ) -> Double {
    let text1 = "\(path1)/\(name1)".lowercased()
    let text2 = "\(path2)/\(name2)".lowercased()
    
    let contexts1 = extractUsageContexts(from: text1)
    let contexts2 = extractUsageContexts(from: text2)
    
    // Si aucun contexte détecté, retourner une similarité basique
    guard !contexts1.isEmpty || !contexts2.isEmpty else {
      return computeNameSimilarity(name1, name2) * 0.5
    }
    
    // Calculer l'intersection des contextes
    let intersection = contexts1.intersection(contexts2)
    let union = contexts1.union(contexts2)
    
    guard !union.isEmpty else { return 0.0 }
    
    // Jaccard similarity + bonus pour match exact de catégorie
    let jaccardScore = Double(intersection.count) / Double(union.count)
    
    // Bonus si les tokens partagent le même groupe de contexte
    let groupBonus = computeGroupMatchBonus(contexts1, contexts2)
    
    return min(1.0, jaccardScore + groupBonus)
  }
  
  /// Extrait les contextes d'usage d'un texte (path + nom)
  private static func extractUsageContexts(from text: String) -> Set<String> {
    var contexts = Set<String>()
    
    for group in usageContextGroups {
      for marker in group {
        if text.contains(marker) {
          contexts.insert(marker)
        }
      }
    }
    
    return contexts
  }
  
  /// Calcule un bonus si deux ensembles de contextes partagent le même groupe sémantique
  private static func computeGroupMatchBonus(_ contexts1: Set<String>, _ contexts2: Set<String>) -> Double {
    var bonus = 0.0
    
    for group in usageContextGroups {
      let groupSet = Set(group)
      let has1 = !contexts1.intersection(groupSet).isEmpty
      let has2 = !contexts2.intersection(groupSet).isEmpty
      
      if has1 && has2 {
        // Les deux tokens appartiennent au même groupe sémantique
        bonus += 0.15
      }
    }
    
    return min(0.3, bonus) // Plafonner le bonus
  }
  
  // MARK: - Structure Similarity
  
  /// Compare la structure des paths (profondeur, catégories parentes)
  /// Moins prioritaire que la couleur et le contexte
  static func computeStructureSimilarity(_ path1: String, _ path2: String) -> Double {
    let components1 = path1.split(separator: "/").map(String.init)
    let components2 = path2.split(separator: "/").map(String.init)
    
    guard !components1.isEmpty, !components2.isEmpty else { return 0.0 }
    
    // Comparer les catégories parentes (sans le dernier élément qui est le nom)
    let parents1 = components1.dropLast()
    let parents2 = components2.dropLast()
    
    if parents1.isEmpty && parents2.isEmpty {
      return 1.0 // Même niveau racine
    }
    
    // Calculer le nombre de parents communs
    var commonParents = 0
    let minParents = min(parents1.count, parents2.count)
    
    for i in 0..<minParents {
      if parents1[i].lowercased() == parents2[i].lowercased() {
        commonParents += 1
      } else {
        break // Arrêter dès qu'on trouve une différence
      }
    }
    
    let maxParents = max(parents1.count, parents2.count)
    guard maxParents > 0 else { return 1.0 }
    
    return Double(commonParents) / Double(maxParents)
  }
  
  // MARK: - Name Similarity (Legacy - utilisé en fallback)
  
  /// Compare deux noms de tokens avec normalisation
  static func computeNameSimilarity(_ name1: String, _ name2: String) -> Double {
    // Match exact
    if name1.lowercased() == name2.lowercased() {
      return 1.0
    }
    
    // Normaliser les noms (retirer préfixes communs)
    let normalized1 = normalizeTokenName(name1)
    let normalized2 = normalizeTokenName(name2)
    
    if normalized1 == normalized2 {
      return 0.9
    }
    
    return levenshteinSimilarity(normalized1, normalized2)
  }
  
  /// Normalise un nom de token en retirant les préfixes/suffixes communs
  private static func normalizeTokenName(_ name: String) -> String {
    var normalized = name.lowercased()
    
    // Retirer les préfixes courants
    let prefixes = ["old-", "new-", "legacy-", "deprecated-", "v1-", "v2-"]
    for prefix in prefixes {
      if normalized.hasPrefix(prefix) {
        normalized = String(normalized.dropFirst(prefix.count))
      }
    }
    
    // Retirer les suffixes courants
    let suffixes = ["-old", "-new", "-legacy", "-deprecated", "-v1", "-v2"]
    for suffix in suffixes {
      if normalized.hasSuffix(suffix) {
        normalized = String(normalized.dropLast(suffix.count))
      }
    }
    
    return normalized
  }
  
  // MARK: - Color Similarity
  
  /// Compare les couleurs de deux TokenThemes
  static func computeColorSimilarity(_ modes1: TokenThemes?, _ modes2: TokenThemes?) -> Double {
    guard let modes1, let modes2 else { return 0.0 }
    
    var scores: [Double] = []
    
    // Comparer Legacy
    if let legacy1 = modes1.legacy, let legacy2 = modes2.legacy {
      if let light1 = legacy1.light?.hex, let light2 = legacy2.light?.hex {
        scores.append(hexColorSimilarity(light1, light2))
      }
      if let dark1 = legacy1.dark?.hex, let dark2 = legacy2.dark?.hex {
        scores.append(hexColorSimilarity(dark1, dark2))
      }
    }
    
    // Comparer New Brand
    if let newBrand1 = modes1.newBrand, let newBrand2 = modes2.newBrand {
      if let light1 = newBrand1.light?.hex, let light2 = newBrand2.light?.hex {
        scores.append(hexColorSimilarity(light1, light2))
      }
      if let dark1 = newBrand1.dark?.hex, let dark2 = newBrand2.dark?.hex {
        scores.append(hexColorSimilarity(dark1, dark2))
      }
    }
    
    guard !scores.isEmpty else { return 0.0 }
    return scores.reduce(0, +) / Double(scores.count)
  }
  
  /// Compare deux couleurs hex en utilisant la distance euclidienne RGB
  static func hexColorSimilarity(_ hex1: String, _ hex2: String) -> Double {
    let rgb1 = hexToRGB(hex1)
    let rgb2 = hexToRGB(hex2)
    
    // Distance euclidienne en espace RGB
    let distance = sqrt(
      pow(Double(rgb1.r) - Double(rgb2.r), 2) +
      pow(Double(rgb1.g) - Double(rgb2.g), 2) +
      pow(Double(rgb1.b) - Double(rgb2.b), 2)
    )
    
    // Distance max = sqrt(3 * 255^2) ≈ 441.67
    let maxDistance = 441.67
    return 1.0 - (distance / maxDistance)
  }
  
  private static func hexToRGB(_ hex: String) -> (r: Int, g: Int, b: Int) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    
    return (
      r: Int((int >> 16) & 0xFF),
      g: Int((int >> 8) & 0xFF),
      b: Int(int & 0xFF)
    )
  }
  
  // MARK: - Levenshtein Distance
  
  /// Calcule la similarité Levenshtein (0.0 à 1.0)
  static func levenshteinSimilarity(_ s1: String, _ s2: String) -> Double {
    let distance = levenshteinDistance(s1, s2)
    let maxLength = max(s1.count, s2.count)
    guard maxLength > 0 else { return 1.0 }
    return 1.0 - (Double(distance) / Double(maxLength))
  }
  
  /// Calcule la distance d'édition Levenshtein entre deux chaînes
  static func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
    let s1Array = Array(s1.lowercased())
    let s2Array = Array(s2.lowercased())
    
    let m = s1Array.count
    let n = s2Array.count
    
    if m == 0 { return n }
    if n == 0 { return m }
    
    var matrix = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: m + 1)
    
    for i in 0...m { matrix[i][0] = i }
    for j in 0...n { matrix[0][j] = j }
    
    for i in 1...m {
      for j in 1...n {
        let cost = s1Array[i - 1] == s2Array[j - 1] ? 0 : 1
        matrix[i][j] = min(
          matrix[i - 1][j] + 1,      // suppression
          matrix[i][j - 1] + 1,      // insertion
          matrix[i - 1][j - 1] + cost // substitution
        )
      }
    }
    
    return matrix[m][n]
  }
}
