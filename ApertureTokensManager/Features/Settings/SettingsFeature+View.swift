import ComposableArchitecture
import SwiftUI

// MARK: - Settings View

@ViewAction(for: SettingsFeature.self)
struct SettingsView: View {
  @Bindable var store: StoreOf<SettingsFeature>
  
  var body: some View {
    NavigationSplitView {
      sidebarContent
    } detail: {
      detailContent
    }
    .frame(minWidth: 600, minHeight: 400)
    .onAppear { send(.onAppear) }
  }
  
  // MARK: - Sidebar
  
  @ViewBuilder
  private var sidebarContent: some View {
    List(selection: $store.selectedSection.sending(\.view.sectionSelected)) {
      ForEach(SettingsFeature.SettingsSection.allCases, id: \.self) { section in
        Label {
          Text(section.rawValue)
        } icon: {
          sectionIcon(for: section)
        }
        .tag(section)
      }
    }
    .listStyle(.sidebar)
    .navigationTitle("Paramètres")
  }
  
  @ViewBuilder
  private func sectionIcon(for section: SettingsFeature.SettingsSection) -> some View {
    switch section {
    case .logs:
      Image(systemName: "doc.text.magnifyingglass")
    case .about:
      Image(systemName: "info.circle")
    }
  }
  
  // MARK: - Detail
  
  @ViewBuilder
  private var detailContent: some View {
    switch store.selectedSection {
    case .logs:
      logsSection
    case .about:
      aboutSection
    }
  }
  
  // MARK: - Logs Section
  
  @ViewBuilder
  private var logsSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Header
      HStack {
        Text("Journal d'activité")
          .font(.title2)
          .fontWeight(.semibold)
        
        Spacer()
        
        Text("\(store.logCount) entrées")
          .font(.caption)
          .foregroundStyle(.secondary)
        
        Button {
          send(.refreshLogsButtonTapped)
        } label: {
          Image(systemName: "arrow.clockwise")
        }
        .buttonStyle(.glass(.regular))
        .disabled(store.isLoadingLogs)
        
        Button {
          send(.clearLogsButtonTapped)
        } label: {
          Image(systemName: "trash")
        }
        .buttonStyle(.glass(.regular.tint(.red)))
        .disabled(store.logEntries.isEmpty)
        
        Button {
          send(.exportLogsButtonTapped)
        } label: {
          Label("Exporter", systemImage: "square.and.arrow.up")
        }
        .buttonStyle(.glass(.regular.tint(.blue)))
        .disabled(store.logEntries.isEmpty || store.isExportingLogs)
      }
      
      // Log List
      if store.isLoadingLogs {
        ProgressView("Chargement des logs...")
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if store.logEntries.isEmpty {
        ContentUnavailableView {
          Label("Aucun log", systemImage: "doc.text")
        } description: {
          Text("Les logs apparaîtront ici au fur et à mesure de l'utilisation de l'application.")
        }
      } else {
        ScrollViewReader { proxy in
          List(store.logEntries) { entry in
            LogEntryRow(entry: entry)
              .id(entry.id)
          }
          .listStyle(.plain)
          .onAppear {
            if let lastEntry = store.logEntries.last {
              proxy.scrollTo(lastEntry.id, anchor: .bottom)
            }
          }
        }
      }
    }
    .padding()
  }
  
  // MARK: - About Section
  
  @ViewBuilder
  private var aboutSection: some View {
    VStack(spacing: 24) {
      Spacer()
      
      Image(systemName: "paintpalette.fill")
        .font(.system(size: 64))
        .foregroundStyle(.tint)
      
      Text("Aperture Tokens Manager")
        .font(.title)
        .fontWeight(.bold)
      
      Text("Version 1.0.0")
        .font(.subheadline)
        .foregroundStyle(.secondary)
      
      Divider()
        .frame(width: 200)
      
      VStack(spacing: 8) {
        Text("Gérez vos design tokens Figma")
        Text("Importez, comparez, analysez et exportez")
      }
      .font(.body)
      .foregroundStyle(.secondary)
      
      Spacer()
      
      Text("© 2026 Picta")
        .font(.caption)
        .foregroundStyle(.tertiary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
  }
}

// MARK: - Log Entry Row

struct LogEntryRow: View {
  let entry: LogEntry
  
  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      // Level indicator
      Text(entry.level.emoji)
        .font(.system(size: 12))
      
      // Timestamp
      Text(formattedTime)
        .font(.caption.monospaced())
        .foregroundStyle(.secondary)
        .frame(width: 80, alignment: .leading)
      
      // Feature badge
      Text(entry.feature)
        .font(.caption2)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(featureColor.opacity(0.2))
        .foregroundStyle(featureColor)
        .clipShape(Capsule())
      
      // Message
      Text(entry.message)
        .font(.caption.monospaced())
        .foregroundStyle(messageColor)
        .lineLimit(2)
      
      Spacer()
    }
    .padding(.vertical, 2)
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

// MARK: - Preview

#Preview {
  SettingsView(
    store: Store(initialState: SettingsFeature.State.initial) {
      SettingsFeature()
    }
  )
}
