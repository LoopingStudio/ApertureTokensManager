import SwiftUI

// MARK: - Unified History View

struct UnifiedHistoryView: View {
  let items: [UnifiedHistoryItem]
  let filter: HomeFeature.HistoryFilter
  let onFilterChange: (HomeFeature.HistoryFilter) -> Void
  let onItemTapped: (UnifiedHistoryItem) -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: UIConstants.Spacing.medium) {
      headerWithFilter
      
      if items.isEmpty {
        emptyState
      } else {
        historyList
      }
    }
  }
  
  // MARK: - Header with Filter
  
  @ViewBuilder
  private var headerWithFilter: some View {
    HStack {
      Text("Activité récente")
        .font(.headline)
        .foregroundStyle(.secondary)
      
      Spacer()
      
      Picker("Filtre", selection: Binding(
        get: { filter },
        set: { onFilterChange($0) }
      )) {
        ForEach(HomeFeature.HistoryFilter.allCases, id: \.self) { filter in
          Text(filter.rawValue).tag(filter)
        }
      }
      .pickerStyle(.segmented)
      .labelsHidden()
      .fixedSize()
    }
  }
  
  // MARK: - Empty State
  
  @ViewBuilder
  private var emptyState: some View {
    VStack(spacing: UIConstants.Spacing.small) {
      Image(systemName: "clock.arrow.circlepath")
        .font(.title)
        .foregroundStyle(.tertiary)
      
      Text("Aucune activité")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, UIConstants.Spacing.large)
  }
  
  // MARK: - History List
  
  @ViewBuilder
  private var historyList: some View {
    VStack(spacing: UIConstants.Spacing.small) {
      ForEach(Array(items.prefix(10).enumerated()), id: \.element.id) { index, item in
        Button {
          onItemTapped(item)
        } label: {
          UnifiedHistoryRow(item: item)
        }
        .buttonStyle(.plain)
        .staggeredAppear(index: index, baseDelay: 0.05, duration: 0.25)
      }
    }
  }
}

// MARK: - Unified History Row

struct UnifiedHistoryRow: View {
  let item: UnifiedHistoryItem
  
  var body: some View {
    HStack(spacing: UIConstants.Spacing.medium) {
      // Icon
      iconView
      
      // Content
      VStack(alignment: .leading, spacing: UIConstants.Spacing.extraSmall) {
        titleView
        subtitleView
      }
      
      Spacer()
      
      // Details + Date
      VStack(alignment: .trailing, spacing: UIConstants.Spacing.small) {
        detailsView
        
        Text(item.date.formatted(.relative(presentation: .named)))
          .font(.caption2)
          .foregroundStyle(.tertiary)
      }
    }
    .padding(.horizontal, UIConstants.Spacing.medium)
    .padding(.vertical, UIConstants.Spacing.small)
    .background(
      RoundedRectangle(cornerRadius: UIConstants.CornerRadius.medium)
        .fill(Color.primary.opacity(0.03))
    )
  }
  
  // MARK: - Icon
  
  @ViewBuilder
  private var iconView: some View {
    switch item {
    case .imported:
      ZStack {
        Circle()
          .fill(Color.purple.opacity(0.15))
          .frame(width: UIConstants.Size.iconMedium, height: UIConstants.Size.iconMedium)
        
        Image(systemName: "square.and.arrow.down.fill")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.purple)
      }
    case .comparison:
      ZStack {
        Circle()
          .fill(Color.blue.opacity(0.15))
          .frame(width: UIConstants.Size.iconMedium, height: UIConstants.Size.iconMedium)
        
        Image(systemName: "doc.text.magnifyingglass")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.blue)
      }
    }
  }
  
  // MARK: - Title
  
  @ViewBuilder
  private var titleView: some View {
    switch item {
    case .imported(let entry):
      HStack(spacing: UIConstants.Spacing.small) {
        Text(entry.fileName)
          .font(.callout)
          .fontWeight(.medium)
          .lineLimit(1)
        
        if let exportDate = entry.metadata?.exportedAt {
          Text("(\(exportDate.toShortDate()))")
            .font(.caption2)
            .foregroundStyle(.purple.opacity(0.8))
        }
      }
      
    case .comparison(let entry):
      HStack(spacing: UIConstants.Spacing.small) {
        Text(entry.oldFile.fileName)
          .font(.callout)
          .fontWeight(.medium)
          .lineLimit(1)
          .foregroundStyle(.blue)
        
        Image(systemName: "arrow.right")
          .font(.caption2)
          .foregroundStyle(.secondary)
        
        Text(entry.newFile.fileName)
          .font(.callout)
          .fontWeight(.medium)
          .lineLimit(1)
          .foregroundStyle(.green)
      }
    }
  }
  
  // MARK: - Subtitle
  
  @ViewBuilder
  private var subtitleView: some View {
    switch item {
    case .imported(let entry):
      if entry.tokenCount > 0 {
        Text("\(entry.tokenCount) tokens")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      
    case .comparison(let entry):
      if let oldDate = entry.oldFile.metadata?.exportedAt,
         let newDate = entry.newFile.metadata?.exportedAt {
        Text("\(oldDate.toShortDate()) → \(newDate.toShortDate())")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }
  
  // MARK: - Details (badges)
  
  @ViewBuilder
  private var detailsView: some View {
    switch item {
    case .imported(let entry):
      if let version = entry.metadata?.version, !version.isEmpty {
        Text("v\(version)")
          .font(.caption2)
          .fontWeight(.medium)
          .foregroundStyle(.purple)
          .padding(.horizontal, UIConstants.Spacing.medium)
          .padding(.vertical, UIConstants.Spacing.extraSmall)
          .background(Color.purple.opacity(0.12))
          .clipShape(RoundedRectangle(cornerRadius: UIConstants.CornerRadius.small))
      }
      
    case .comparison(let entry):
      HStack(spacing: UIConstants.Spacing.small) {
        if entry.summary.addedCount > 0 {
          diffBadge(prefix: "+", count: entry.summary.addedCount, color: .green)
        }
        if entry.summary.removedCount > 0 {
          diffBadge(prefix: "-", count: entry.summary.removedCount, color: .red)
        }
        if entry.summary.modifiedCount > 0 {
          diffBadge(prefix: "~", count: entry.summary.modifiedCount, color: .orange)
        }
      }
    }
  }
  
  @ViewBuilder
  private func diffBadge(prefix: String, count: Int, color: Color) -> some View {
    Text("\(prefix)\(count)")
      .font(.caption2)
      .fontWeight(.semibold)
      .foregroundStyle(color)
      .padding(.horizontal, 5)
      .padding(.vertical, UIConstants.Spacing.extraSmall)
      .background(color.opacity(0.15))
      .clipShape(RoundedRectangle(cornerRadius: UIConstants.CornerRadius.small))
  }
}

// MARK: - Preview

#if DEBUG
#Preview {
  UnifiedHistoryView(
    items: [
      .imported(ImportHistoryEntry(
        fileName: "aperture-tokens-v2.1.json",
        bookmarkData: nil,
        metadata: TokenMetadata(
          exportedAt: "2026-02-06",
          timestamp: 0,
          version: "2.1.0",
          generator: "Figma"
        ),
        tokenCount: 245
      )),
      .comparison(ComparisonHistoryEntry(
        oldFile: FileSnapshot(fileName: "v2.0.json", bookmarkData: nil, metadata: nil),
        newFile: FileSnapshot(fileName: "v2.1.json", bookmarkData: nil, metadata: nil),
        summary: ComparisonSummary(addedCount: 12, removedCount: 3, modifiedCount: 8)
      )),
      .imported(ImportHistoryEntry(
        fileName: "tokens-legacy.json",
        bookmarkData: nil,
        metadata: nil,
        tokenCount: 180
      ))
    ],
    filter: .all,
    onFilterChange: { _ in },
    onItemTapped: { _ in }
  )
  .padding()
  .frame(width: UIConstants.Size.historyMaxWidth)
}
#endif
