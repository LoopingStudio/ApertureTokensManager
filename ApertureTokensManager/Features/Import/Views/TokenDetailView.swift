import SwiftUI

struct TokenDetailView: View {
  let node: TokenNode
  
  var body: some View {
    VStack(alignment: .leading, spacing: UIConstants.Spacing.extraLarge) {
      VStack(alignment: .leading, spacing: UIConstants.Spacing.medium) {
        header
        nodeType
        nodePath
      }
      if node.type == .group {
        groupDetail
      } else if let modes = node.modes {
        // Affichage des thèmes pour un token individuel - layout vertical compact
        singleTokenThemes(modes: modes)
        Spacer()
      }
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  private var header: some View {
    HStack {
      Text(node.name)
        .font(.title2)
        .fontWeight(.semibold)

      if !node.isEnabled {
        Text("Exclu")
          .font(.caption2)
          .fontWeight(.medium)
          .padding(.horizontal, UIConstants.Spacing.medium)
          .padding(.vertical, UIConstants.Spacing.extraSmall)
          .background(Color.orange.opacity(0.2))
          .foregroundStyle(.orange)
          .clipShape(Capsule())
      }
    }
  }

  @ViewBuilder
  private var nodePath: some View {
    if let path = node.path {
      Text("Chemin: \(path)")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }

  private var nodeType: some View {
    HStack {
      Image(systemName: node.type == .group ? "folder.fill" : "paintbrush.fill")
        .foregroundStyle(node.type == .group ? .blue : .purple)
      Text(node.type == .group ? "Dossier" : "Token")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }

  @ViewBuilder
  private var groupDetail: some View {
    // Affichage des tokens enfants pour un groupe
    let childTokens = getAllChildTokens(from: node)
    if !childTokens.isEmpty {
      VStack(alignment: .leading, spacing: UIConstants.Spacing.large) {
        Text("Tokens (\(childTokens.count))")
          .font(.headline)
          .fontWeight(.medium)
        ScrollView {
          LazyVStack(alignment: .leading, spacing: UIConstants.Spacing.medium) {
            ForEach(childTokens) { token in
              tokenRow(token: token)
                .padding(.horizontal, UIConstants.Spacing.medium)
                .padding(.vertical, UIConstants.Spacing.medium)
                .background(
                  RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium)
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
  }

  // MARK: - Single Token Themes (redesigned)
  
  @ViewBuilder
  private func singleTokenThemes(modes: TokenThemes) -> some View {
    VStack(alignment: .leading, spacing: UIConstants.Spacing.extraLarge) {
      // Legacy Brand
      if let legacy = modes.legacy {
        brandSection(name: Brand.legacy, theme: legacy, accentColor: .blue)
      }
      
      // New Brand
      if let newBrand = modes.newBrand {
        brandSection(name: Brand.newBrand, theme: newBrand, accentColor: .purple)
      }
    }
  }
  
  @ViewBuilder
  private func brandSection(name: String, theme: TokenThemes.Appearance, accentColor: Color) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      // Brand header
      HStack(spacing: UIConstants.Spacing.medium) {
        Circle()
          .fill(accentColor)
          .frame(width: UIConstants.Spacing.medium, height: UIConstants.Spacing.medium)
        Text(name)
          .font(.subheadline)
          .fontWeight(.semibold)
      }
      
      // Theme colors in horizontal layout
      HStack(spacing: UIConstants.Spacing.extraLarge) {
        if let lightValue = theme.light {
          themeColorCard(value: lightValue, label: "Light", icon: "sun.max.fill")
        }
        if let darkValue = theme.dark {
          themeColorCard(value: darkValue, label: "Dark", icon: "moon.fill")
        }
      }
    }
    .padding()
    .background(Color(.controlBackgroundColor).opacity(0.5))
    .clipShape(RoundedRectangle(cornerRadius: UIConstants.CornerRadius.extraLarge))
  }
  
  @ViewBuilder
  private func themeColorCard(value: TokenValue, label: String, icon: String) -> some View {
    ThemeColorCardView(value: value, label: label, icon: icon)
  }
  
  // MARK: - Group Content
  
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
    HStack(spacing: UIConstants.Spacing.small) {
      VStack(alignment: .leading, spacing: UIConstants.Spacing.small) {
        HStack(spacing: UIConstants.Spacing.medium) {
          Text(token.name)
            .font(.subheadline)
            .fontWeight(.medium)
          
          if !token.isEnabled {
            Text("Exclu")
              .font(.caption2)
              .fontWeight(.medium)
              .padding(.horizontal, UIConstants.Spacing.small)
              .padding(.vertical, UIConstants.Spacing.extraSmall)
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

}

// MARK: - Theme Color Card with Popover

private struct ThemeColorCardView: View {
  let value: TokenValue
  let label: String
  let icon: String
  
  @State private var showPopover = false
  @State private var isHovering = false
  
  var body: some View {
    HStack(spacing: UIConstants.Spacing.large) {
      // Color preview - clickable
      RoundedRectangle(cornerRadius: UIConstants.CornerRadius.large)
        .fill(Color(hex: value.hex))
        .frame(width: UIConstants.Size.colorSquareMedium, height: UIConstants.Size.colorSquareMedium)
        .overlay(
          RoundedRectangle(cornerRadius: UIConstants.CornerRadius.large)
            .stroke(Color.primary.opacity(isHovering ? 0.3 : 0.15), lineWidth: isHovering ? 2 : 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
        .scaleEffect(isHovering ? 1.05 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isHovering)
        .onHover { isHovering = $0 }
        .onTapGesture { showPopover.toggle() }
        .popover(isPresented: $showPopover, arrowEdge: .top) {
          colorPopover
        }
      
      // Info
      VStack(alignment: .leading, spacing: UIConstants.Spacing.small) {
        HStack(spacing: UIConstants.Spacing.small) {
          Image(systemName: icon)
            .font(.caption2)
            .foregroundStyle(.secondary)
          Text(label)
            .font(.caption)
            .fontWeight(.medium)
        }
        
        Text(value.hex)
          .font(.system(.caption, design: .monospaced))
          .fontWeight(.medium)
          .foregroundStyle(.primary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
  
  private var colorPopover: some View {
    VStack(alignment: .leading, spacing: UIConstants.Spacing.large) {
      Text("Détails de la couleur")
        .font(.headline)
        .fontWeight(.semibold)
      
      HStack(spacing: UIConstants.Spacing.large) {
        RoundedRectangle(cornerRadius: UIConstants.CornerRadius.large)
          .fill(Color(hex: value.hex))
          .frame(width: UIConstants.Size.colorSquare, height: UIConstants.Size.colorSquare)
          .overlay(
            RoundedRectangle(cornerRadius: UIConstants.CornerRadius.large)
              .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
          )
        
        VStack(alignment: .leading, spacing: UIConstants.Spacing.medium) {
          VStack(alignment: .leading, spacing: UIConstants.Spacing.extraSmall) {
            Text("Hex")
              .font(.caption)
              .fontWeight(.medium)
              .foregroundStyle(.secondary)
            
            Text(value.hex)
              .font(.system(.body, design: .monospaced))
              .fontWeight(.medium)
              .textSelection(.enabled)
          }
          
          VStack(alignment: .leading, spacing: UIConstants.Spacing.extraSmall) {
            Text("Primitive")
              .font(.caption)
              .fontWeight(.medium)
              .foregroundStyle(.secondary)
            
            Text(value.primitiveName)
              .font(.callout)
              .textSelection(.enabled)
          }
        }
        
        Spacer()
      }
    }
    .padding()
    .frame(width: UIConstants.Size.popoverWidth)
  }
}

// MARK: - Previews

#if DEBUG
#Preview("Token Detail") {
  TokenDetailView(node: PreviewData.singleToken)
    .frame(width: UIConstants.Size.previewWidth, height: UIConstants.Size.previewHeight)
}

#Preview("Group Detail") {
  TokenDetailView(node: PreviewData.brandGroup)
    .frame(width: UIConstants.Size.previewWidth, height: UIConstants.Size.previewWidth)
}

#Preview("Disabled Token") {
  TokenDetailView(node: PreviewData.disabledToken)
    .frame(width: UIConstants.Size.previewWidth, height: UIConstants.Size.previewHeight)
}
#endif

