import Foundation

/// Helpers for token operations used across the app
enum TokenHelpers {
  /// Flattens a hierarchy of tokens into a flat array (tokens only)
  static func flattenTokens(_ tokens: [TokenNode]) -> [TokenNode] {
    var result: [TokenNode] = []

    func flatten(_ nodes: [TokenNode]) {
      for node in nodes {
        if node.type == .token {
          result.append(node)
        }
        if let children = node.children {
          flatten(children)
        }
      }
    }
    flatten(tokens)
    return result
  }
  
  /// Flattens a hierarchy of nodes into a flat array (all nodes: groups + tokens)
  static func flattenAllNodes(_ nodes: [TokenNode]) -> [TokenNode] {
    var result: [TokenNode] = []
    
    func addNodesRecursively(_ nodes: [TokenNode]) {
      for node in nodes {
        result.append(node)
        if let children = node.children {
          addNodesRecursively(children)
        }
      }
    }
    addNodesRecursively(nodes)
    return result
  }
  
  /// Counts leaf tokens (nodes with values) in a hierarchy
  static func countLeafTokens(_ nodes: [TokenNode]) -> Int {
    var count = 0
    for node in nodes {
      if node.type == .token {
        count += 1
      }
      if let children = node.children {
        count += countLeafTokens(children)
      }
    }
    return count
  }

  /// Finds a token by its path in a token hierarchy
  static func findTokenByPath(_ path: String, in tokens: [TokenNode]?) -> TokenNode? {
    guard let tokens = tokens else { return nil }

    func search(_ nodes: [TokenNode]) -> TokenNode? {
      for node in nodes {
        if (node.path ?? node.name) == path {
          return node
        }
        if let children = node.children,
           let found = search(children) {
          return found
        }
      }
      return nil
    }

    return search(tokens)
  }
  
  /// Applies filters to a copy of tokens and returns the filtered copy
  static func applyFilters(_ filters: TokenFilters, to tokens: [TokenNode]) -> [TokenNode] {
    var copy = tokens
    applyFiltersRecursively(nodes: &copy, filters: filters)
    return copy
  }
  
  private static func applyFiltersRecursively(
    nodes: inout [TokenNode],
    filters: TokenFilters,
    forceDisabled: Bool = false
  ) {
    for i in 0..<nodes.count {
      var shouldDisableChildren = forceDisabled
      
      // Filtrer le groupe Utility
      if nodes[i].type == .group && nodes[i].name.lowercased() == GroupNames.utility {
        if filters.excludeUtilityGroup {
          nodes[i].isEnabled = false
          shouldDisableChildren = true
        } else if !forceDisabled {
          nodes[i].isEnabled = true
        }
      } else if nodes[i].type == .group && !forceDisabled {
        // Les autres groupes sont activés par défaut (sauf si parent désactivé)
        nodes[i].isEnabled = true
      }
      
      // Si forcé par un parent désactivé
      if forceDisabled {
        nodes[i].isEnabled = false
      }
      
      // Appliquer les filtres au nœud courant s'il s'agit d'un token
      if nodes[i].type == .token {
        if shouldDisableChildren {
          nodes[i].isEnabled = false
        } else {
          var newIsEnabled = true
          
          if filters.excludeTokensStartingWithHash && nodes[i].name.hasPrefix("#") {
            newIsEnabled = false
          }
          if filters.excludeTokensEndingWithHover && nodes[i].name.hasSuffix("_hover") {
            newIsEnabled = false
          }
          
          nodes[i].isEnabled = newIsEnabled
        }
      }
      
      // Appliquer les filtres aux enfants
      if var children = nodes[i].children {
        applyFiltersRecursively(
          nodes: &children,
          filters: filters,
          forceDisabled: shouldDisableChildren
        )
        nodes[i].children = children
      }
    }
  }
}
