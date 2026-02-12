import SwiftUI

struct OrphanedTokensListView: View {
  let tokens: [OrphanedToken]
  let expandedCategories: Set<String>
  var searchText: String = ""
  let onToggleCategory: (String) -> Void
  
  private var groupedTokens: [(String, [OrphanedToken])] {
    let grouped = Dictionary(grouping: tokens, by: \.category)
    return grouped.sorted { $0.key < $1.key }
  }
  
  var body: some View {
    ScrollView {
      LazyVStack(spacing: UIConstants.Spacing.medium) {
        if tokens.isEmpty {
          emptyState
        } else {
          // Summary
          HStack {
            Image(systemName: "exclamationmark.triangle.fill")
              .foregroundStyle(.orange)
            
            Text("\(tokens.count) tokens non utilisés détectés")
              .font(.subheadline)
            
            Spacer()
            
            Text("Ces tokens peuvent être supprimés du design system")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .padding()
          .background(Color.orange.opacity(0.1))
          .clipShape(RoundedRectangle(cornerRadius: UIConstants.CornerRadius.xxLarge))
          
          // Grouped by category
          ForEach(groupedTokens, id: \.0) { category, categoryTokens in
            CategorySection(
              category: category,
              tokens: categoryTokens,
              isExpanded: expandedCategories.contains(category) || !searchText.isEmpty,
              searchText: searchText,
              onToggle: { onToggleCategory(category) }
            )
          }
        }
      }
      .padding()
    }
  }
  
  @ViewBuilder
  private var emptyState: some View {
    VStack(spacing: UIConstants.Spacing.large) {
      Image(systemName: "checkmark.circle.fill")
        .font(.largeTitle)
        .foregroundStyle(.green)
      
      Text("Aucun token orphelin")
        .font(.headline)
      
      Text("Tous les tokens exportés sont utilisés dans vos projets")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 48)
  }
}

// MARK: - Category Section

private struct CategorySection: View {
  let category: String
  let tokens: [OrphanedToken]
  let isExpanded: Bool
  var searchText: String = ""
  let onToggle: () -> Void
  
  var body: some View {
    VStack(spacing: 0) {
      // Header
      Button(action: onToggle) {
        HStack {
          Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(width: UIConstants.Spacing.extraLarge)
          
          Text(category)
            .font(.headline)
          
          Spacer()
          
          Text("\(tokens.count) tokens")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, UIConstants.Spacing.medium)
            .padding(.vertical, UIConstants.Spacing.small)
            .background(Color.orange.opacity(0.2))
            .clipShape(Capsule())
        }
        .padding(UIConstants.Spacing.large)
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: UIConstants.CornerRadius.large))
      }
      .buttonStyle(.plain)
      
      // Tokens
      if isExpanded {
        VStack(spacing: UIConstants.Spacing.small) {
          ForEach(tokens) { token in
            OrphanedTokenRow(token: token, searchText: searchText)
          }
        }
        .padding(.leading, UIConstants.Spacing.section)
        .padding(.top, UIConstants.Spacing.medium)
      }
    }
  }
}

// MARK: - Orphaned Token Row

private struct OrphanedTokenRow: View {
  let token: OrphanedToken
  var searchText: String = ""
  @State private var isCopied = false
  
  var body: some View {
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
      
      Button {
        copyToClipboard()
      } label: {
        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
          .foregroundStyle(isCopied ? .green : .secondary)
      }
      .buttonStyle(.plain)
      .help("Copier le nom")
    }
    .padding(UIConstants.Spacing.extraLarge)
    .background(Color(.controlBackgroundColor).opacity(0.5))
    .clipShape(RoundedRectangle(cornerRadius: UIConstants.CornerRadius.large))
  }
  
  private func copyToClipboard() {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(token.enumCase, forType: .string)
    
    isCopied = true
    Task {
      try? await Task.sleep(for: .milliseconds(1500))
      isCopied = false
    }
  }
}

// MARK: - Preview

#if DEBUG
#Preview {
  OrphanedTokensListView(
    tokens: [
      OrphanedToken(enumCase: "bgLegacyMuted", originalPath: "Background/Legacy/muted"),
      OrphanedToken(enumCase: "bgLegacySubtle", originalPath: "Background/Legacy/subtle"),
      OrphanedToken(enumCase: "fgOldPrimary", originalPath: "Foreground/Old/primary"),
      OrphanedToken(enumCase: "borderDeprecated", originalPath: "Border/deprecated")
    ],
    expandedCategories: ["Background"],
    onToggleCategory: { _ in }
  )
  .frame(width: 600, height: 500)
}
#endif
