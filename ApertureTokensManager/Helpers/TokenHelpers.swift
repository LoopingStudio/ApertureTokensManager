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
}
