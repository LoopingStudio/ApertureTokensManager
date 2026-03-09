import Foundation

actor GraphService {

  func buildGraph(
    tokens: [TokenNode],
    brand: String,
    appearance: String,
    hideUtility: Bool
  ) -> TokenGraph {
    let allLeafTokens = TokenHelpers.flattenTokens(tokens)
    let leafTokens = hideUtility
      ? allLeafTokens.filter { !isInUtilityGroup($0, tokens: tokens) }
      : allLeafTokens

    // Build lookups: full path, all suffixes, and short name
    var lookupByPath: [String: TokenNode] = [:]
    var lookupByName: [String: TokenNode] = [:]
    for token in leafTokens {
      let path = token.path ?? token.name
      lookupByPath[path] = token
      lookupByName[token.name] = token
      // Also index by all path suffixes so "Base/white" matches "UI Colors/Base/white"
      let components = path.split(separator: "/")
      for i in 1..<components.count {
        let suffix = components[i...].joined(separator: "/")
        if lookupByPath[suffix] == nil {
          lookupByPath[suffix] = token
        }
      }
    }

    // Resolve token values and collect primitiveName references
    struct TokenInfo {
      let token: TokenNode
      let path: String
      let hex: String?
      let primitiveName: String?
      let parentGroupName: String
    }

    // Find parent group name for each token by walking the tree
    var parentGroupNames: [UUID: String] = [:]
    collectParentGroups(tokens, parentName: nil, result: &parentGroupNames)

    var tokenInfos: [TokenInfo] = []
    for token in leafTokens {
      let path = token.path ?? token.name
      let value = resolveTokenValue(token: token, brand: brand, appearance: appearance)
      tokenInfos.append(TokenInfo(
        token: token,
        path: path,
        hex: value?.hex,
        primitiveName: value?.primitiveName,
        parentGroupName: parentGroupNames[token.id] ?? token.name
      ))
    }

    // Build edges and create primitive nodes for unresolved references
    var edges: [GraphEdge] = []
    var primitiveNodeIds: [String: UUID] = [:]
    var primitiveNodes: [GraphNode] = []
    // Track which real tokens are sources (referenced by others via primitiveName)
    var realTokenIds = Set(leafTokens.map(\.id))

    for info in tokenInfos {
      guard let rawPrimitiveName = info.primitiveName, !rawPrimitiveName.isEmpty else { continue }

      // Split reference chains: "A → B" means token references A, which references B (the primitive)
      let chainSegments = rawPrimitiveName
        .components(separatedBy: "→")
        .map { cleanPrimitiveName($0.trimmingCharacters(in: .whitespaces)) }
        .filter { !$0.isEmpty }

      if chainSegments.isEmpty { continue }

      if chainSegments.count == 1 {
        // Simple reference: token → source
        let ref = chainSegments[0]
        let sourceId = resolveOrCreatePrimitive(
          ref: ref, hex: info.hex,
          lookupByPath: lookupByPath, lookupByName: lookupByName,
          primitiveNodeIds: &primitiveNodeIds, primitiveNodes: &primitiveNodes
        )
        edges.append(GraphEdge(sourceId: sourceId, targetId: info.token.id))
      } else {
        // Chain: "level1Ref → primitiveRef"
        // Last segment is the primitive, first is the intermediate level1 token
        // Build edges: primitive → level1 → current token
        let primitiveRef = chainSegments[chainSegments.count - 1]
        let level1Ref = chainSegments[0]

        let primitiveSourceId = resolveOrCreatePrimitive(
          ref: primitiveRef, hex: info.hex,
          lookupByPath: lookupByPath, lookupByName: lookupByName,
          primitiveNodeIds: &primitiveNodeIds, primitiveNodes: &primitiveNodes
        )

        // Resolve level1 token (may be a real token or needs a virtual node)
        let level1Id: UUID
        if let realToken = lookupByPath[level1Ref] ?? lookupByName[level1Ref] {
          level1Id = realToken.id
        } else {
          level1Id = resolveOrCreatePrimitive(
            ref: level1Ref, hex: info.hex,
            lookupByPath: lookupByPath, lookupByName: lookupByName,
            primitiveNodeIds: &primitiveNodeIds, primitiveNodes: &primitiveNodes
          )
        }

        // primitive → level1 → current token
        edges.append(GraphEdge(sourceId: primitiveSourceId, targetId: level1Id))
        edges.append(GraphEdge(sourceId: level1Id, targetId: info.token.id))
      }
    }

    // Assign layers based on dependency depth:
    // - Primitive nodes (virtual) → .primitive
    // - Tokens whose source is a primitive → .level1
    // - Tokens whose source is a level1 token → .level2
    // - Tokens with no edges → .level1 (standalone)
    let primitiveIdSet = Set(primitiveNodes.map(\.id))
    var sourceOf: [UUID: UUID] = [:] // targetId → sourceId
    for edge in edges {
      sourceOf[edge.targetId] = edge.sourceId
    }

    func layerForToken(_ tokenId: UUID) -> TokenLayer {
      guard let sourceId = sourceOf[tokenId] else { return .level1 }
      if primitiveIdSet.contains(sourceId) { return .level1 }
      // Source is a real token — check if THAT token's source is a primitive
      if let grandSourceId = sourceOf[sourceId], primitiveIdSet.contains(grandSourceId) {
        return .level2
      }
      // Default: if the source is a real token, this is level2
      if realTokenIds.contains(sourceId) { return .level2 }
      return .level1
    }

    // Build final graph nodes for real tokens
    var nodes: [GraphNode] = primitiveNodes
    for info in tokenInfos {
      let layer = layerForToken(info.token.id)
      nodes.append(GraphNode(
        id: info.token.id,
        name: info.token.name,
        path: info.path,
        layer: layer,
        groupName: info.parentGroupName,
        hex: info.hex,
        primitiveName: info.primitiveName
      ))
    }

    // Build layer groups
    var layerGroups: [TokenLayer: [String: [GraphNode]]] = [:]
    for node in nodes {
      layerGroups[node.layer, default: [:]][node.groupName, default: []].append(node)
    }

    return TokenGraph(
      nodes: nodes,
      edges: edges,
      layerGroups: layerGroups,
      unresolvedCount: 0
    )
  }

  // MARK: - Private

  /// Check if a token is under a group named "utility" (case-insensitive) anywhere in the tree.
  private func isInUtilityGroup(_ token: TokenNode, tokens: [TokenNode]) -> Bool {
    func search(_ nodes: [TokenNode], insideUtility: Bool) -> Bool {
      for node in nodes {
        let isUtility = insideUtility || (node.type == .group && node.name.lowercased() == GroupNames.utility)
        if node.id == token.id { return isUtility }
        if let children = node.children, search(children, insideUtility: isUtility) {
          return true
        }
      }
      return false
    }
    return search(tokens, insideUtility: false)
  }

  /// Walk the token tree and record the direct parent group name for each leaf token.
  private func collectParentGroups(
    _ nodes: [TokenNode],
    parentName: String?,
    result: inout [UUID: String]
  ) {
    for node in nodes {
      if node.type == .token {
        result[node.id] = parentName ?? node.name
      }
      if let children = node.children {
        collectParentGroups(children, parentName: node.name, result: &result)
      }
    }
  }

  /// Resolve a reference to an existing token or create a virtual primitive node.
  /// Returns the UUID of the resolved/created node.
  private func resolveOrCreatePrimitive(
    ref: String,
    hex: String?,
    lookupByPath: [String: TokenNode],
    lookupByName: [String: TokenNode],
    primitiveNodeIds: inout [String: UUID],
    primitiveNodes: inout [GraphNode]
  ) -> UUID {
    // Try to find an existing token
    if let source = lookupByPath[ref] ?? lookupByName[ref] {
      return source.id
    }
    // Deduplicated virtual primitive
    if let existingId = primitiveNodeIds[ref] {
      return existingId
    }
    let id = UUID()
    primitiveNodeIds[ref] = id
    let components = ref.split(separator: "/")
    let groupName = components.count >= 2 ? String(components[0]) : "Primitives"
    let shortName: String
    if components.count >= 2 {
      shortName = components.suffix(2).joined(separator: "/")
    } else {
      shortName = components.last.map(String.init) ?? ref
    }
    primitiveNodes.append(GraphNode(
      id: id,
      name: shortName,
      path: ref,
      layer: .primitive,
      groupName: groupName,
      hex: hex,
      primitiveName: nil
    ))
    return id
  }

  /// Strip annotations like " (fallback)", " (default)" from primitiveName references.
  private func cleanPrimitiveName(_ raw: String) -> String {
    // Remove parenthesized suffixes: " (fallback)", " (default)", etc.
    if let parenRange = raw.range(of: #"\s*\(.*\)\s*$"#, options: .regularExpression) {
      return String(raw[raw.startIndex..<parenRange.lowerBound])
    }
    return raw
  }

  private func resolveTokenValue(
    token: TokenNode,
    brand: String,
    appearance: String
  ) -> TokenValue? {
    guard let modes = token.modes else { return nil }

    let brandAppearance: TokenThemes.Appearance?
    switch brand {
    case Brand.legacy: brandAppearance = modes.legacy
    case Brand.newBrand: brandAppearance = modes.newBrand
    default: brandAppearance = modes.legacy
    }

    guard let brandAppearance else { return nil }

    switch appearance {
    case ThemeType.light: return brandAppearance.light
    case ThemeType.dark: return brandAppearance.dark
    default: return brandAppearance.light
    }
  }
}
