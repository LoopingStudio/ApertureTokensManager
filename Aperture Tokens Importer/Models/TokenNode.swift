import Foundation

public enum NodeType: String, Codable, Equatable, Sendable {
  case group
  case token
  
  public init?(rawValue: String) {
    switch rawValue {
    case "group": self = .group
    case "token": self = .token
    default: return nil
    }
  }
}

// MARK: - Theme Structures

public struct TokenThemes: Codable, Equatable, Sendable {
  let legacy: Appearance?
  let newBrand: Appearance?

  enum CodingKeys: String, CodingKey {
    case legacy = "Legacy"
    case newBrand = "New Brand"
  }

  public struct Appearance: Codable, Equatable, Sendable {
    let light: TokenValue?
    let dark: TokenValue?
  }
}

public struct TokenValue: Codable, Equatable, Sendable {
  let hex: String
  let primitiveName: String
}

public struct TokenNode: Identifiable, Codable, Equatable, Sendable {
  public let id: UUID
  let name: String
  let type: NodeType
  let path: String?
  let modes: TokenThemes?

  var children: [TokenNode]?
  var isEnabled: Bool = true

  init(
    id: UUID = UUID(),
    name: String,
    type: NodeType,
    path: String? = nil,
    modes: TokenThemes? = nil,
    children: [TokenNode]? = nil,
    isEnabled: Bool = true
  ) {
    self.id = id
    self.name = name
    self.type = type
    self.path = path
    self.modes = modes
    self.children = children
    self.isEnabled = isEnabled
  }

  enum CodingKeys: String, CodingKey {
    case name, type, path, modes, children
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = UUID()
    self.name = try container.decode(String.self, forKey: .name)
    self.type = .init(rawValue: try container.decode(String.self, forKey: .type)) ?? .group
    self.path = try? container.decode(String.self, forKey: .path)
    self.modes = try? container.decode(TokenThemes.self, forKey: .modes)
    self.children = try? container.decode([TokenNode].self, forKey: .children)
    self.isEnabled = true
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(name, forKey: .name)
    try container.encode(type.rawValue, forKey: .type)
    try container.encodeIfPresent(path, forKey: .path)
    try container.encodeIfPresent(modes, forKey: .modes)
    try container.encodeIfPresent(children, forKey: .children)
  }
}

// Logique métier : Activer/Désactiver récursivement
extension TokenNode {
  mutating func toggleRecursively(_ state: Bool) {
    self.isEnabled = state
    if children != nil {
      for i in 0..<children!.count {
        children![i].toggleRecursively(state)
      }
    }
  }
}
