import SwiftUI

struct UsedTokensListView: View {
  let tokens: [UsedToken]
  let selectedToken: UsedToken?
  var searchText: String = ""
  let onTokenTapped: (UsedToken?) -> Void
  
  var body: some View {
    HSplitView {
      // Token List
      ScrollView {
        LazyVStack(spacing: UIConstants.Spacing.small) {
          ForEach(tokens) { token in
            TokenRow(
              token: token,
              isSelected: selectedToken?.id == token.id,
              searchText: searchText,
              onTap: { onTokenTapped(token) }
            )
          }
        }
        .padding(UIConstants.Spacing.medium)
      }
      .frame(minWidth: 300)
      
      // Detail View
      if let selected = selectedToken {
        TokenDetailPanel(token: selected)
          .frame(minWidth: 400)
      } else {
        emptyDetail
          .frame(minWidth: 400)
      }
    }
  }
  
  @ViewBuilder
  private var emptyDetail: some View {
    VStack(spacing: UIConstants.Spacing.large) {
      Image(systemName: "doc.text.magnifyingglass")
        .font(.largeTitle)
        .foregroundStyle(.secondary)
      
      Text("Sélectionnez un token")
        .font(.headline)
        .foregroundStyle(.secondary)
      
      Text("pour voir ses occurrences")
        .font(.caption)
        .foregroundStyle(.tertiary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

// MARK: - Token Row

private struct TokenRow: View {
  let token: UsedToken
  let isSelected: Bool
  var searchText: String = ""
  let onTap: () -> Void
  
  var body: some View {
    Button(action: onTap) {
      HStack {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.small) {
          TokenTreeSearchHelper.highlightedText(token.enumCase, searchText: searchText, baseColor: .primary)
            .font(.system(.body, design: .monospaced))
            .fontWeight(.medium)
          
          if let path = token.originalPath {
            TokenTreeSearchHelper.highlightedText(path, searchText: searchText, baseColor: .secondary)
              .font(.caption)
          }
        }
        
        Spacer()
        
        Text("\(token.usageCount)")
          .font(.system(.caption, design: .rounded, weight: .bold))
          .foregroundStyle(.white)
          .padding(.horizontal, UIConstants.Spacing.medium)
          .padding(.vertical, UIConstants.Spacing.small)
          .background(usageCountColor)
          .clipShape(Capsule())
      }
      .padding(UIConstants.Spacing.extraLarge)
      .background(isSelected ? Color.accentColor.opacity(0.2) : Color(.controlBackgroundColor))
      .clipShape(RoundedRectangle(cornerRadius: UIConstants.CornerRadius.large))
      .overlay {
        if isSelected {
          RoundedRectangle(cornerRadius: UIConstants.CornerRadius.large)
            .stroke(Color.accentColor, lineWidth: 2)
        }
      }
    }
    .buttonStyle(.plain)
  }
  
  private var usageCountColor: Color {
    switch token.usageCount {
    case 0...2: return .orange
    case 3...10: return .green
    default: return .blue
    }
  }
}

// MARK: - Token Detail Panel

private struct TokenDetailPanel: View {
  let token: UsedToken
  
  var body: some View {
    VStack(alignment: .leading, spacing: UIConstants.Spacing.extraLarge) {
      // Header
      VStack(alignment: .leading, spacing: UIConstants.Spacing.medium) {
        Text(token.enumCase)
          .font(.title2)
          .fontWeight(.bold)
          .font(.system(.title2, design: .monospaced))
        
        if let path = token.originalPath {
          Text(path)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        
        HStack {
          Label("\(token.usageCount) occurrences", systemImage: "number")
            .font(.caption)
            .foregroundStyle(.secondary)
          
          Spacer()
        }
      }
      .padding()
      .background(Color(.controlBackgroundColor).opacity(0.5))
      .clipShape(RoundedRectangle(cornerRadius: UIConstants.CornerRadius.xxLarge))
      
      // Usages List
      Text("Occurrences")
        .font(.headline)
      
      ScrollView {
        LazyVStack(spacing: UIConstants.Spacing.medium) {
          ForEach(token.usages) { usage in
            UsageRow(usage: usage)
          }
        }
      }
    }
    .padding()
  }
}

// MARK: - Usage Row

private struct UsageRow: View {
  let usage: TokenUsage
  
  var body: some View {
    VStack(alignment: .leading, spacing: UIConstants.Spacing.medium) {
      HStack {
        Image(systemName: "doc.text")
          .foregroundStyle(.blue)
        
        Text(fileName)
          .font(.subheadline)
          .fontWeight(.medium)
        
        Text(":\(usage.lineNumber)")
          .font(.caption)
          .foregroundStyle(.secondary)
        
        Spacer()
        
        Text(usage.matchType)
          .font(.caption2)
          .foregroundStyle(.secondary)
          .padding(.horizontal, UIConstants.Spacing.medium)
          .padding(.vertical, UIConstants.Spacing.extraSmall)
          .background(Color(.controlBackgroundColor))
          .clipShape(Capsule())
      }
      
      Text(usage.lineContent)
        .font(.system(.caption, design: .monospaced))
        .foregroundStyle(.secondary)
        .lineLimit(2)
        .truncationMode(.tail)
      
      Text(usage.filePath)
        .font(.caption2)
        .foregroundStyle(.tertiary)
        .lineLimit(1)
        .truncationMode(.middle)
    }
    .padding(UIConstants.Spacing.extraLarge)
    .background(Color(.controlBackgroundColor))
    .clipShape(RoundedRectangle(cornerRadius: UIConstants.CornerRadius.large))
  }
  
  private var fileName: String {
    URL(fileURLWithPath: usage.filePath).lastPathComponent
  }
}

// MARK: - Preview

#if DEBUG
#Preview {
  UsedTokensListView(
    tokens: [
      UsedToken(
        enumCase: "bgBrandSolid",
        originalPath: "Background/Brand/solid",
        usages: [
          TokenUsage(filePath: "/Users/dev/App/ContentView.swift", lineNumber: 42, lineContent: ".foregroundColor(.bgBrandSolid)", matchType: "."),
          TokenUsage(filePath: "/Users/dev/App/SettingsView.swift", lineNumber: 18, lineContent: "theme.color(.bgBrandSolid)", matchType: "theme.color")
        ]
      ),
      UsedToken(
        enumCase: "fgPrimary",
        originalPath: "Foreground/Primary",
        usages: [
          TokenUsage(filePath: "/Users/dev/App/Components/Button.swift", lineNumber: 10, lineContent: ".fgPrimary", matchType: ".")
        ]
      )
    ],
    selectedToken: nil,
    onTokenTapped: { _ in }
  )
  .frame(width: 800, height: 500)
}
#endif
