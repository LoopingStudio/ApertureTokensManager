import SwiftUI

// MARK: - Log Entry Row

struct LogEntryRow: View {
  let entry: LogEntry
  
  var body: some View {
    HStack(alignment: .top, spacing: UIConstants.Spacing.medium) {
      Text(entry.level.emoji)
        .font(.system(size: UIConstants.Spacing.large))
      
      Text(formattedTime)
        .font(.caption.monospaced())
        .foregroundStyle(.secondary)
        .frame(width: UIConstants.Size.logTimestampWidth, alignment: .leading)
      
      Text(entry.feature)
        .font(.caption2)
        .padding(.horizontal, UIConstants.Spacing.medium)
        .padding(.vertical, UIConstants.Spacing.extraSmall)
        .background(featureColor.opacity(0.2))
        .foregroundStyle(featureColor)
        .clipShape(Capsule())
      
      Text(entry.message)
        .font(.caption.monospaced())
        .foregroundStyle(messageColor)
        .lineLimit(2)
      
      Spacer()
    }
    .padding(.vertical, UIConstants.Spacing.extraSmall)
  }
  
  private var formattedTime: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.SSS"
    return formatter.string(from: entry.timestamp)
  }
  
  private var featureColor: Color {
    switch entry.feature.lowercased() {
    case "import": return .blue
    case "compare": return .purple
    case "analysis": return .orange
    case "export": return .green
    case "file": return .cyan
    case "home": return .indigo
    case "tutorial": return .pink
    default: return .gray
    }
  }
  
  private var messageColor: Color {
    switch entry.level {
    case .error: return .red
    case .warning: return .orange
    case .success: return .green
    case .debug: return .secondary
    case .info: return .primary
    }
  }
}
