import SwiftUI

struct TokenDetailView: View {
  let node: TokenNode
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Text(node.name)
            .font(.title2)
            .fontWeight(.semibold)
          
          if !node.isEnabled {
            Text("Exclu")
              .font(.caption2)
              .fontWeight(.medium)
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(Color.orange.opacity(0.2))
              .foregroundStyle(.orange)
              .clipShape(Capsule())
          }
        }
        
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
        HStack(spacing: 6) {
          Text(token.name)
            .font(.subheadline)
            .fontWeight(.medium)
          
          if !token.isEnabled {
            Text("Exclu")
              .font(.caption2)
              .fontWeight(.medium)
              .padding(.horizontal, 4)
              .padding(.vertical, 1)
              .background(Color.orange.opacity(0.2))
              .foregroundStyle(.orange)
              .clipShape(Capsule())
          }
        }
        
        if let path = token.path {
          Text(path)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }
      
      Spacer()
      
      if let modes = token.modes {
        CompactColorPreview(modes: modes)
      }
    }
    .opacity(token.isEnabled ? 1.0 : 0.5)
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
    VStack(spacing: UIConstants.Spacing.small) {
      RoundedRectangle(cornerRadius: UIConstants.CornerRadius.large)
        .fill(Color(hex: value.hex))
        .frame(width: UIConstants.Size.colorSquare, height: UIConstants.Size.colorSquare)
        .overlay(
          RoundedRectangle(cornerRadius: UIConstants.CornerRadius.large)
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
      .frame(width: UIConstants.Size.colorLabelWidth)
    }
  }
}
// MARK: - Previews

#if DEBUG
#Preview("Token Detail") {
  TokenDetailView(node: PreviewData.singleToken)
    .frame(width: 400, height: 300)
}

#Preview("Group Detail") {
  TokenDetailView(node: PreviewData.brandGroup)
    .frame(width: 400, height: 400)
}

#Preview("Disabled Token") {
  TokenDetailView(node: PreviewData.disabledToken)
    .frame(width: 400, height: 300)
}
#endif

