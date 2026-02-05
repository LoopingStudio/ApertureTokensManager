import SwiftUI

// MARK: - Import History View

struct ImportHistoryView: View {
  let history: [ImportHistoryEntry]
  let onEntryTapped: (ImportHistoryEntry) -> Void
  let onRemove: (UUID) -> Void
  let onClear: () -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Label("Imports récents", systemImage: "clock.arrow.circlepath")
          .font(.headline)
          .foregroundStyle(.secondary)
        
        Spacer()
        
        if !history.isEmpty {
          Button("Effacer") {
            withAnimation(.easeOut(duration: 0.2)) {
              onClear()
            }
          }
          .font(.caption)
          .foregroundStyle(.secondary)
          .buttonStyle(.plain)
        }
      }
      
      if history.isEmpty {
        Text("Aucun import récent")
          .font(.caption)
          .foregroundStyle(.tertiary)
          .frame(maxWidth: .infinity, alignment: .center)
          .padding(.vertical, 8)
          .transition(.opacity.combined(with: .scale(scale: 0.95)))
      } else {
        ScrollView {
          VStack(spacing: 6) {
            ForEach(Array(history.enumerated()), id: \.element.id) { index, entry in
              ImportHistoryRow(
                entry: entry,
                onTap: { onEntryTapped(entry) },
                onRemove: {
                  withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    onRemove(entry.id)
                  }
                }
              )
              .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.95)),
                removal: .opacity.combined(with: .move(edge: .trailing)).combined(with: .scale(scale: 0.9))
              ))
              .animation(.spring(response: 0.4, dampingFraction: 0.75).delay(Double(index) * 0.05), value: history.count)
            }
          }
        }
        .frame(maxHeight: 180)
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color(nsColor: .controlBackgroundColor))
    )
    .animation(.easeInOut(duration: 0.25), value: history.isEmpty)
  }
}

// MARK: - Import History Row

struct ImportHistoryRow: View {
  let entry: ImportHistoryEntry
  let onTap: () -> Void
  let onRemove: () -> Void
  @State private var isHovering = false
  @State private var isPressed = false
  
  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: "doc.fill")
        .font(.title3)
        .foregroundStyle(.purple)
        .scaleEffect(isHovering ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovering)
      
      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 4) {
          Text(entry.fileName)
            .font(.subheadline)
            .fontWeight(.medium)
            .lineLimit(1)
          
          if let exportDate = entry.metadata?.exportedAt {
            Text("(\(exportDate.toShortDate()))")
              .font(.caption2)
              .foregroundStyle(.purple.opacity(0.8))
          }
        }
        
        HStack(spacing: 8) {
          Label(entry.date.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
            .font(.caption2)
            .foregroundStyle(.secondary)
          
          if entry.tokenCount > 0 {
            Text("\(entry.tokenCount) tokens")
              .font(.caption2)
              .foregroundStyle(.tertiary)
          }
        }
      }
      
      Spacer()
      
      Button {
        onRemove()
      } label: {
        Image(systemName: "xmark.circle.fill")
          .foregroundStyle(.secondary)
          .opacity(isHovering ? 1 : 0)
          .scaleEffect(isHovering ? 1 : 0.5)
      }
      .buttonStyle(.plain)
      .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovering)
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(isHovering ? Color.accentColor.opacity(0.1) : Color.clear)
    )
    .scaleEffect(isPressed ? 0.98 : 1.0)
    .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
    .animation(.easeOut(duration: 0.15), value: isHovering)
    .contentShape(Rectangle())
    .onTapGesture {
      withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
        isPressed = true
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
          isPressed = false
        }
        onTap()
      }
    }
    .onHover { hovering in
      withAnimation(.easeOut(duration: 0.15)) {
        isHovering = hovering
      }
    }
  }
}

// MARK: - Comparison History View

struct ComparisonHistoryView: View {
  let history: [ComparisonHistoryEntry]
  let onEntryTapped: (ComparisonHistoryEntry) -> Void
  let onRemove: (UUID) -> Void
  let onClear: () -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Label("Comparaisons récentes", systemImage: "clock.arrow.circlepath")
          .font(.headline)
          .foregroundStyle(.secondary)
        
        Spacer()
        
        if !history.isEmpty {
          Button("Effacer") {
            withAnimation(.easeOut(duration: 0.2)) {
              onClear()
            }
          }
          .font(.caption)
          .foregroundStyle(.secondary)
          .buttonStyle(.plain)
        }
      }
      
      if history.isEmpty {
        Text("Aucune comparaison récente")
          .font(.caption)
          .foregroundStyle(.tertiary)
          .frame(maxWidth: .infinity, alignment: .center)
          .padding(.vertical, 8)
          .transition(.opacity.combined(with: .scale(scale: 0.95)))
      } else {
        ScrollView {
          VStack(spacing: 6) {
            ForEach(Array(history.enumerated()), id: \.element.id) { index, entry in
              ComparisonHistoryRow(
                entry: entry,
                onTap: { onEntryTapped(entry) },
                onRemove: {
                  withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    onRemove(entry.id)
                  }
                }
              )
              .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.95)),
                removal: .opacity.combined(with: .move(edge: .trailing)).combined(with: .scale(scale: 0.9))
              ))
              .animation(.spring(response: 0.4, dampingFraction: 0.75).delay(Double(index) * 0.05), value: history.count)
            }
          }
        }
        .frame(maxHeight: 200)
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color(nsColor: .controlBackgroundColor))
    )
    .animation(.easeInOut(duration: 0.25), value: history.isEmpty)
  }
}

// MARK: - Comparison History Row

struct ComparisonHistoryRow: View {
  let entry: ComparisonHistoryEntry
  let onTap: () -> Void
  let onRemove: () -> Void
  @State private var isHovering = false
  @State private var isPressed = false
  
  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: "doc.text.magnifyingglass")
        .font(.title3)
        .foregroundStyle(.blue)
        .scaleEffect(isHovering ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovering)
      
      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 4) {
          fileVersionLabel(entry.oldFile, color: .blue)
          Image(systemName: "arrow.right")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .scaleEffect(isHovering ? 1.2 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.05), value: isHovering)
          fileVersionLabel(entry.newFile, color: .green)
        }
        .font(.subheadline)
        .fontWeight(.medium)
        
        HStack(spacing: 8) {
          Label(entry.date.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
            .font(.caption2)
            .foregroundStyle(.secondary)
          
          summaryBadges
        }
      }
      
      Spacer()
      
      Button {
        onRemove()
      } label: {
        Image(systemName: "xmark.circle.fill")
          .foregroundStyle(.secondary)
          .opacity(isHovering ? 1 : 0)
          .scaleEffect(isHovering ? 1 : 0.5)
      }
      .buttonStyle(.plain)
      .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovering)
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(isHovering ? Color.accentColor.opacity(0.1) : Color.clear)
    )
    .scaleEffect(isPressed ? 0.98 : 1.0)
    .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
    .animation(.easeOut(duration: 0.15), value: isHovering)
    .contentShape(Rectangle())
    .onTapGesture {
      withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
        isPressed = true
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
          isPressed = false
        }
        onTap()
      }
    }
    .onHover { hovering in
      withAnimation(.easeOut(duration: 0.15)) {
        isHovering = hovering
      }
    }
  }
  
  private var summaryBadges: some View {
    HStack(spacing: 4) {
      if entry.summary.addedCount > 0 {
        summaryBadge(count: entry.summary.addedCount, color: .green)
      }
      if entry.summary.removedCount > 0 {
        summaryBadge(count: entry.summary.removedCount, color: .red)
      }
      if entry.summary.modifiedCount > 0 {
        summaryBadge(count: entry.summary.modifiedCount, color: .orange)
      }
    }
  }
  
  private func summaryBadge(count: Int, color: Color) -> some View {
    Text("+\(count)")
      .font(.caption2)
      .fontWeight(.medium)
      .foregroundStyle(color)
      .padding(.horizontal, 4)
      .padding(.vertical, 1)
      .background(color.opacity(0.15))
      .clipShape(RoundedRectangle(cornerRadius: 3))
  }
  
  private func fileVersionLabel(_ file: FileSnapshot, color: Color) -> some View {
    HStack(spacing: 4) {
      Text(file.fileName)
        .lineLimit(1)
      if let exportDate = file.metadata?.exportedAt {
        Text("(\(exportDate.toShortDate()))")
          .font(.caption2)
          .foregroundStyle(color.opacity(0.8))
      }
    }
  }
}

// MARK: - Previews

#if DEBUG
#Preview("Import History") {
  ImportHistoryView(
    history: PreviewData.importHistoryEntries,
    onEntryTapped: { _ in },
    onRemove: { _ in },
    onClear: { }
  )
  .frame(width: 400)
  .padding()
}

#Preview("Import History - Empty") {
  ImportHistoryView(
    history: [],
    onEntryTapped: { _ in },
    onRemove: { _ in },
    onClear: { }
  )
  .frame(width: 400)
  .padding()
}

#Preview("Comparison History") {
  ComparisonHistoryView(
    history: PreviewData.comparisonHistoryEntries,
    onEntryTapped: { _ in },
    onRemove: { _ in },
    onClear: { }
  )
  .frame(width: 500)
  .padding()
}

#Preview("Comparison History - Empty") {
  ComparisonHistoryView(
    history: [],
    onEntryTapped: { _ in },
    onRemove: { _ in },
    onClear: { }
  )
  .frame(width: 500)
  .padding()
}
#endif
