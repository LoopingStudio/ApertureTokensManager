import Foundation

// MARK: - Token Layer

enum TokenLayer: Int, CaseIterable, Comparable, Sendable {
  case primitive = 0
  case level1 = 1
  case level2 = 2

  static func < (lhs: TokenLayer, rhs: TokenLayer) -> Bool {
    lhs.rawValue < rhs.rawValue
  }

  var displayName: String {
    switch self {
    case .primitive: "Primitives"
    case .level1: "Niveau 1"
    case .level2: "Niveau 2"
    }
  }
}

// MARK: - Graph Node

struct GraphNode: Identifiable, Equatable, Sendable {
  let id: UUID
  let name: String
  let path: String
  let layer: TokenLayer
  let groupName: String
  let hex: String?
  let primitiveName: String?
}

// MARK: - Graph Edge

struct GraphEdge: Identifiable, Equatable, Sendable {
  let id: UUID
  let sourceId: UUID
  let targetId: UUID

  init(id: UUID = UUID(), sourceId: UUID, targetId: UUID) {
    self.id = id
    self.sourceId = sourceId
    self.targetId = targetId
  }
}

// MARK: - Token Graph

struct TokenGraph: Equatable, Sendable {
  let nodes: [GraphNode]
  let edges: [GraphEdge]
  let layerGroups: [TokenLayer: [String: [GraphNode]]]
  let unresolvedCount: Int
}
