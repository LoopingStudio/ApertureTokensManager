import SwiftUI

/// Champ de recherche réutilisable avec compteur de résultats et support focus
struct SearchField: View {
  @Binding var text: String
  let placeholder: String
  let resultCount: Int?
  let totalCount: Int?
  @FocusState.Binding var isFocused: Bool
  
  init(
    text: Binding<String>,
    placeholder: String = "Rechercher...",
    resultCount: Int? = nil,
    totalCount: Int? = nil,
    isFocused: FocusState<Bool>.Binding
  ) {
    self._text = text
    self.placeholder = placeholder
    self.resultCount = resultCount
    self.totalCount = totalCount
    self._isFocused = isFocused
  }
  
  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: UIConstants.Spacing.medium) {
        Image(systemName: "magnifyingglass")
          .foregroundStyle(isFocused ? .purple : .secondary)
        
        TextField(placeholder, text: $text)
          .textFieldStyle(.plain)
          .focused($isFocused)
        
        if !text.isEmpty {
          if let resultCount, let totalCount {
            Text("\(resultCount)/\(totalCount)")
              .font(.caption)
              .foregroundStyle(resultCount == 0 ? .orange : .secondary)
              .monospacedDigit()
          }
          
          Button {
            text = ""
          } label: {
            Image(systemName: "xmark.circle.fill")
              .foregroundStyle(.secondary)
          }
          .buttonStyle(.plain)
        }
      }
      .padding(UIConstants.Spacing.medium)
      .background(Color(nsColor: .controlBackgroundColor))
      
      // Message si aucun résultat
      if !text.isEmpty, let resultCount, resultCount == 0 {
        HStack {
          Image(systemName: "exclamationmark.circle")
            .foregroundStyle(.orange)
          Text("Aucun token trouvé pour \"\(text)\"")
            .font(.caption)
            .foregroundStyle(.secondary)
          Spacer()
        }
        .padding(.horizontal, UIConstants.Spacing.medium)
        .padding(.vertical, UIConstants.Spacing.small)
        .background(Color.orange.opacity(0.1))
      }
    }
  }
}

// MARK: - View Modifier pour raccourci Cmd+F

struct SearchFocusModifier: ViewModifier {
  @FocusState.Binding var isSearchFocused: Bool
  
  func body(content: Content) -> some View {
    content
      .onKeyPress(keys: [.init("f")], phases: .down) { keyPress in
        if keyPress.modifiers.contains(.command) {
          isSearchFocused = true
          return .handled
        }
        return .ignored
      }
  }
}

extension View {
  func searchFocusShortcut(_ isSearchFocused: FocusState<Bool>.Binding) -> some View {
    modifier(SearchFocusModifier(isSearchFocused: isSearchFocused))
  }
}

// MARK: - Preview

#if DEBUG
struct SearchFieldPreview: View {
  @State private var text = ""
  @FocusState private var isFocused: Bool
  
  var body: some View {
    VStack {
      SearchField(
        text: $text,
        resultCount: text.isEmpty ? nil : 5,
        totalCount: text.isEmpty ? nil : 120,
        isFocused: $isFocused
      )
      
      Spacer()
      
      Text("Appuyez sur Cmd+F pour focus")
        .foregroundStyle(.secondary)
    }
    .padding()
    .frame(width: UIConstants.Size.searchFieldWidth, height: 200)
    .searchFocusShortcut($isFocused)
  }
}

#Preview("Search Field") {
  SearchFieldPreview()
}

#Preview("Search Field - No Results") {
  @Previewable @State var text = "introuvable"
  @Previewable @FocusState var isFocused: Bool
  
  SearchField(
    text: $text,
    resultCount: 0,
    totalCount: 120,
    isFocused: $isFocused
  )
  .frame(width: UIConstants.Size.searchFieldWidth)
}
#endif
