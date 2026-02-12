import SwiftUI

struct RemovedTokensView: View {
  let tokens: [TokenSummary]
  let changes: ComparisonChanges?
  let newVersionTokens: [TokenNode]?
  var searchText: String = ""
  let onSuggestReplacement: (String, String?) -> Void
  let onAcceptAutoSuggestion: (String) -> Void
  let onRejectAutoSuggestion: (String) -> Void
  
  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: UIConstants.Spacing.medium) {
        ForEach(tokens) { token in
          RemovedTokenListItem(
            token: token,
            changes: changes,
            newVersionTokens: newVersionTokens,
            searchText: searchText,
            onSuggestReplacement: onSuggestReplacement,
            onAcceptAutoSuggestion: onAcceptAutoSuggestion,
            onRejectAutoSuggestion: onRejectAutoSuggestion
          )
        }
      }
    }
  }
}

// MARK: - Removed Token List Item

struct RemovedTokenListItem: View {
  let token: TokenSummary
  let changes: ComparisonChanges?
  let newVersionTokens: [TokenNode]?
  var searchText: String = ""
  let onSuggestReplacement: (String, String?) -> Void
  let onAcceptAutoSuggestion: (String) -> Void
  let onRejectAutoSuggestion: (String) -> Void
  
  /// Suggestion manuelle (déjà acceptée)
  private var manualSuggestion: ReplacementSuggestion? {
    changes?.getSuggestion(for: token.path)
  }
  
  /// Suggestion automatique (en attente)
  private var autoSuggestion: AutoSuggestion? {
    // Ne pas afficher l'auto-suggestion si une suggestion manuelle existe déjà
    guard manualSuggestion == nil else { return nil }
    return changes?.getAutoSuggestion(for: token.path)
  }
  
  /// Path du token suggéré (manuel ou auto)
  private var suggestedTokenPath: String? {
    manualSuggestion?.suggestedTokenPath ?? autoSuggestion?.suggestedTokenPath
  }

  var body: some View {
    HStack(alignment: .top, spacing: UIConstants.Spacing.large) {
      VStack(alignment: .leading, spacing: UIConstants.Spacing.small) {
        TokenInfoHeader(name: token.name, path: token.path, searchText: searchText)

        ReplacementSection(
          removedToken: token,
          changes: changes,
          autoSuggestion: autoSuggestion,
          newVersionTokens: newVersionTokens,
          onSuggestReplacement: onSuggestReplacement,
          onAcceptAutoSuggestion: onAcceptAutoSuggestion,
          onRejectAutoSuggestion: onRejectAutoSuggestion
        )
      }

      Spacer()

      VStack(alignment: .trailing, spacing: UIConstants.Spacing.medium) {
        if let modes = token.modes {
          VStack(alignment: .trailing, spacing: UIConstants.Spacing.small) {
            Text("Couleurs supprimées")
              .font(.caption2)
              .foregroundStyle(.secondary)
            CompactColorPreview(modes: modes)
          }
        }

        if let suggestedPath = suggestedTokenPath,
           let suggestedToken = TokenHelpers.findTokenByPath(suggestedPath, in: newVersionTokens),
           let modes = suggestedToken.modes {

          VStack(alignment: .trailing, spacing: UIConstants.Spacing.small) {
            Text("Nouvelles couleurs")
              .font(.caption2)
              .foregroundStyle(.green)
              .fontWeight(.medium)

            CompactColorPreview(modes: modes, shouldShowLabels: false)
          }
          .padding(.top, UIConstants.Spacing.medium)
        }
      }

      TokenBadge(text: "SUPPRIMÉ", color: .red)
    }
    .controlRoundedBackground()
  }
}

// MARK: - Replacement Section

struct ReplacementSection: View {
  let removedToken: TokenSummary
  let changes: ComparisonChanges?
  let autoSuggestion: AutoSuggestion?
  let newVersionTokens: [TokenNode]?
  let onSuggestReplacement: (String, String?) -> Void
  let onAcceptAutoSuggestion: (String) -> Void
  let onRejectAutoSuggestion: (String) -> Void
  
  var body: some View {
    HStack(spacing: UIConstants.Spacing.medium) {
      if let suggestion = changes?.getSuggestion(for: removedToken.path) {
        // Suggestion manuelle acceptée
        acceptedSuggestionView(suggestion: suggestion)
      } else if let auto = autoSuggestion {
        // Suggestion automatique en attente
        autoSuggestionView(suggestion: auto)
      } else {
        // Pas de suggestion - afficher le menu manuel
        suggestionMenuView
      }
    }
  }
  
  // MARK: - Accepted Suggestion (Manual)
  
  private func acceptedSuggestionView(suggestion: ReplacementSuggestion) -> some View {
    HStack(spacing: UIConstants.Spacing.small) {
      Image(systemName: "checkmark.circle.fill")
        .font(.caption2)
        .foregroundStyle(.green)
      
      Text(suggestion.suggestedTokenPath)
        .font(.caption)
        .foregroundStyle(.green)
        .lineLimit(1)
      
      Button {
        onSuggestReplacement(removedToken.path, nil)
      } label: {
        Image(systemName: "xmark.circle.fill")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, UIConstants.Spacing.medium)
    .padding(.vertical, UIConstants.Spacing.extraSmall)
    .background(.green.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: UIConstants.CornerRadius.small))
  }
  
  // MARK: - Auto Suggestion (Pending)
  
  private func autoSuggestionView(suggestion: AutoSuggestion) -> some View {
    HStack(spacing: UIConstants.Spacing.medium) {
      // Indicateur de confiance
      ConfidenceIndicator(confidence: suggestion.confidence)
      
      Text(suggestion.suggestedTokenPath)
        .font(.caption)
        .foregroundStyle(.primary)
        .lineLimit(1)
      
      // Boutons accepter/rejeter
      HStack(spacing: UIConstants.Spacing.extraSmall) {
        Button {
          onAcceptAutoSuggestion(removedToken.path)
        } label: {
          Image(systemName: "checkmark.circle.fill")
            .font(.caption)
            .foregroundStyle(.green)
        }
        .buttonStyle(.plain)
        .help("Accepter cette suggestion")
        
        Button {
          onRejectAutoSuggestion(removedToken.path)
        } label: {
          Image(systemName: "xmark.circle.fill")
            .font(.caption)
            .foregroundStyle(.red.opacity(0.7))
        }
        .buttonStyle(.plain)
        .help("Rejeter cette suggestion")
      }
    }
    .padding(.horizontal, UIConstants.Spacing.medium)
    .padding(.vertical, UIConstants.Spacing.small)
    .background(confidenceBackgroundColor(suggestion.confidence))
    .clipShape(RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium))
  }
  
  private func confidenceBackgroundColor(_ confidence: Double) -> Color {
    switch confidence {
    case 0.7...: return .green.opacity(0.12)
    case 0.5..<0.7: return .orange.opacity(0.12)
    default: return .gray.opacity(0.12)
    }
  }
  
  // MARK: - Manual Suggestion Menu
  
  @ViewBuilder
  private var suggestionMenuView: some View {
    if let newTokens = newVersionTokens {
      let allNewTokens = TokenHelpers.flattenTokens(newTokens)
      
      Menu {
        ForEach(allNewTokens, id: \.path) { newToken in
          Button(newToken.name) {
            onSuggestReplacement(
              removedToken.path,
              newToken.path ?? newToken.name
            )
          }
        }
      } label: {
        HStack(spacing: UIConstants.Spacing.small) {
          Image(systemName: "plus")
          Text("Suggérer")
        }
        .font(.caption)
        .foregroundStyle(.blue)
      }
      .buttonStyle(.plain)
      .padding(.horizontal, UIConstants.Spacing.medium)
      .padding(.vertical, UIConstants.Spacing.extraSmall)
      .background(.blue.opacity(0.1))
      .clipShape(RoundedRectangle(cornerRadius: UIConstants.CornerRadius.small))
    }
  }
}

// MARK: - Confidence Indicator

struct ConfidenceIndicator: View {
  let confidence: Double
  
  var body: some View {
    HStack(spacing: UIConstants.Spacing.extraSmall) {
      Image(systemName: confidenceIcon)
        .font(.caption2)
      Text("\(Int(confidence * 100))%")
        .font(.caption2)
        .fontWeight(.medium)
    }
    .foregroundStyle(confidenceColor)
  }
  
  private var confidenceIcon: String {
    switch confidence {
    case 0.7...: return "sparkles"
    case 0.5..<0.7: return "questionmark.circle"
    default: return "exclamationmark.circle"
    }
  }
  
  private var confidenceColor: Color {
    switch confidence {
    case 0.7...: return .green
    case 0.5..<0.7: return .orange
    default: return .gray
    }
  }
}
