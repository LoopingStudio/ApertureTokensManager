import SwiftUI

struct RemovedTokensView: View {
  let tokens: [TokenSummary]
  let changes: ComparisonChanges?
  let newVersionTokens: [TokenNode]?
  let onSuggestReplacement: (String, String?) -> Void
  let onAcceptAutoSuggestion: (String) -> Void
  let onRejectAutoSuggestion: (String) -> Void
  
  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 8) {
        ForEach(tokens) { token in
          RemovedTokenListItem(
            token: token,
            changes: changes,
            newVersionTokens: newVersionTokens,
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
    HStack(alignment: .top, spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        TokenInfoHeader(name: token.name, path: token.path)

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

      VStack(alignment: .trailing, spacing: 8) {
        if let modes = token.modes {
          VStack(alignment: .trailing, spacing: 4) {
            Text("Couleurs supprimées")
              .font(.caption2)
              .foregroundStyle(.secondary)
            CompactColorPreview(modes: modes)
          }
        }

        if let suggestedPath = suggestedTokenPath,
           let suggestedToken = TokenHelpers.findTokenByPath(suggestedPath, in: newVersionTokens),
           let modes = suggestedToken.modes {

          VStack(alignment: .trailing, spacing: 4) {
            Text("Nouvelles couleurs")
              .font(.caption2)
              .foregroundStyle(.green)
              .fontWeight(.medium)

            CompactColorPreview(modes: modes, shouldShowLabels: false)
          }
          .padding(.top, 6)
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
    HStack(spacing: 6) {
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
    HStack(spacing: 4) {
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
    .padding(.horizontal, 6)
    .padding(.vertical, 2)
    .background(.green.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: 4))
  }
  
  // MARK: - Auto Suggestion (Pending)
  
  private func autoSuggestionView(suggestion: AutoSuggestion) -> some View {
    HStack(spacing: 6) {
      // Indicateur de confiance
      ConfidenceIndicator(confidence: suggestion.confidence)
      
      Text(suggestion.suggestedTokenPath)
        .font(.caption)
        .foregroundStyle(.primary)
        .lineLimit(1)
      
      // Boutons accepter/rejeter
      HStack(spacing: 2) {
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
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(confidenceBackgroundColor(suggestion.confidence))
    .clipShape(RoundedRectangle(cornerRadius: 6))
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
        HStack(spacing: 4) {
          Image(systemName: "plus")
          Text("Suggérer")
        }
        .font(.caption)
        .foregroundStyle(.blue)
      }
      .buttonStyle(.plain)
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .background(.blue.opacity(0.1))
      .clipShape(RoundedRectangle(cornerRadius: 4))
    }
  }
}

// MARK: - Confidence Indicator

struct ConfidenceIndicator: View {
  let confidence: Double
  
  var body: some View {
    HStack(spacing: 3) {
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
