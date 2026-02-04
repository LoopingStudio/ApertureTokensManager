import SwiftUI

struct TokenDetailView: View {
  let node: TokenNode
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      VStack(alignment: .leading, spacing: 8) {
        Text(node.name)
          .font(.title2)
          .fontWeight(.semibold)
        
        HStack {
          Image(systemName: node.type == .group ? "folder.fill" : "paintbrush.fill")
            .foregroundStyle(node.type == .group ? .blue : .purple)
          Text(node.type == .group ? "Dossier" : "Token")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        
        if let path = node.path {
          Text("Chemin: \(path)")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      
      if node.type == .group {
        // Affichage des tokens enfants pour un groupe
        let childTokens = getAllChildTokens(from: node)
        if !childTokens.isEmpty {
          ScrollView {
            VStack(alignment: .leading, spacing: 12) {
              Text("Tokens (\(childTokens.count))")
                .font(.headline)
                .fontWeight(.medium)
              
              LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(childTokens) { token in
                  tokenRow(token: token)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                      RoundedRectangle(cornerRadius: 6)
                        .fill(Color(nsColor: .controlBackgroundColor))
                    )
                }
              }
            }
          }
        } else {
          Text("Aucun token dans ce groupe")
            .foregroundStyle(.secondary)
            .italic()
        }
      } else if let modes = node.modes {
        // Affichage des thèmes pour un token individuel
        VStack(alignment: .leading, spacing: 12) {
          Text("Themes")
            .font(.headline)
            .fontWeight(.medium)
          
          HStack(alignment: .top, spacing: 12) {
            if let legacy = modes.legacy {
              brandTheme(brandName: Brand.legacy, theme: legacy)
            }
            if let newBrand = modes.newBrand {
              brandTheme(brandName: Brand.newBrand, theme: newBrand)
            }
          }
        }
      }
      Spacer()
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
  
  // Fonction pour collecter récursivement tous les tokens enfants
  private func getAllChildTokens(from node: TokenNode) -> [TokenNode] {
    var tokens: [TokenNode] = []
    
    if let children = node.children {
      for child in children {
        if child.type == .token {
          tokens.append(child)
        } else if child.type == .group {
          tokens.append(contentsOf: getAllChildTokens(from: child))
        }
      }
    }
    return tokens
  }
  
  // Vue pour afficher un token dans la liste
  private func tokenRow(token: TokenNode) -> some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text(token.name)
          .font(.subheadline)
          .fontWeight(.medium)
        
        if let path = token.path {
          Text(path)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }
      
      Spacer()
      
      if let modes = token.modes {
        VStack(alignment: .trailing, spacing: 4) {
          if let lightValue = modes.legacy?.light {
            colorPreviewWithInfo(
              value: lightValue,
              brand: Brand.legacy
            )
          }
          if let lightValue = modes.newBrand?.light {
            colorPreviewWithInfo(
              value: lightValue,
              brand: Brand.newBrand
            )
          }
        }
      }
    }
  }

  private func colorPreview(color: Color, size: CGFloat) -> some View {
    RoundedRectangle(cornerRadius: 4)
      .fill(color)
      .frame(width: size, height: size)
      .overlay {
        RoundedRectangle(cornerRadius: 4)
          .stroke(Color.secondary.opacity(0.3), lineWidth: 0.5)
      }
  }

  private func brandTheme(brandName: String, theme: TokenThemes.Appearance) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(brandName)
        .font(.caption)
        .fontWeight(.medium)
        .foregroundStyle(.primary)

      HStack(alignment: .top, spacing: 4) {
        if let lightValue = theme.light {
          themeSquare(value: lightValue, label: ThemeType.light.capitalized)
        }
        if let darkValue = theme.dark {
          themeSquare(value: darkValue, label: ThemeType.dark.capitalized)
        }
      }
    }
  }

  private func themeSquare(value: TokenValue, label: String) -> some View {
    VStack(spacing: 4) {
      RoundedRectangle(cornerRadius: 8)
        .fill(Color(hex: value.hex))
        .frame(width: 64, height: 64)
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(Color.secondary.opacity(0.3), lineWidth: 1.0)
        )
        .shadow(radius: 1)

      VStack(spacing: 2) {
        Text(label)
          .font(.caption2)
          .fontWeight(.medium)
          .foregroundStyle(.primary)
        
        Text(value.hex)
          .font(.caption2)
          .fontWeight(.semibold)
          .foregroundStyle(.secondary)
        
        Text(value.primitiveName)
          .font(.caption2)
          .foregroundStyle(.tertiary)
          .lineLimit(2)
          .multilineTextAlignment(.center)
      }
      .frame(width: 100)
    }
  }
  
  private func colorPreviewWithInfo(value: TokenValue, brand: String) -> some View {
    HStack(alignment: .top, spacing: 8) {
      VStack(alignment: .trailing, spacing: 2) {
        Text(brand)
          .font(.caption2)
          .fontWeight(.medium)
          .foregroundStyle(.primary)
        Text(value.primitiveName)
          .font(.caption2)
          .foregroundStyle(.tertiary)
          .lineLimit(1)
      }

      RoundedRectangle(cornerRadius: 4)
        .fill(Color(hex: value.hex))
        .frame(width: 24, height: 24)
        .overlay(
          RoundedRectangle(cornerRadius: 4)
            .stroke(Color.secondary.opacity(0.3), lineWidth: 0.5)
        )
    }
  }
}
