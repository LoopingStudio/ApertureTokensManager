import SwiftUI

struct OverviewView: View {
  let changes: ComparisonChanges
  let oldFileMetadata: TokenMetadata?
  let newFileMetadata: TokenMetadata?
  let onTabTapped: (CompareFeature.ComparisonTab) -> Void
  
  @State private var showTitle = false
  @State private var showFileInfo = false
  @State private var showCards = false
  
  var body: some View {
    VStack(alignment: .leading, spacing: UIConstants.Spacing.xxLarge) {
      Text("Résumé des changements")
        .font(.title2)
        .fontWeight(.semibold)
        .opacity(showTitle ? 1 : 0)
        .offset(y: showTitle ? 0 : -10)
      
      fileInfoSection
        .opacity(showFileInfo ? 1 : 0)
        .offset(y: showFileInfo ? 0 : 15)
      
      summaryCardsGrid
        .opacity(showCards ? 1 : 0)
        .offset(y: showCards ? 0 : 20)
      
      Spacer()
    }
    .onAppear {
      withAnimation(.easeOut(duration: AnimationDuration.slow)) {
        showTitle = true
      }
      withAnimation(.easeOut(duration: 0.35).delay(0.1)) {
        showFileInfo = true
      }
      withAnimation(.easeOut(duration: AnimationDuration.verySlow).delay(0.2)) {
        showCards = true
      }
    }
  }
  
  // MARK: - File Info Section
  
  private var fileInfoSection: some View {
    HStack(spacing: UIConstants.Spacing.xxLarge) {
      fileInfoCard(title: "Ancienne Version", metadata: oldFileMetadata, color: .blue)
      
      Image(systemName: "arrow.right")
        .font(.title2)
        .foregroundStyle(.secondary)
      
      fileInfoCard(title: "Nouvelle Version", metadata: newFileMetadata, color: .green)
    }
    .padding(.bottom, UIConstants.Spacing.medium)
  }
  
  private func fileInfoCard(title: String, metadata: TokenMetadata?, color: Color) -> some View {
    VStack(alignment: .leading, spacing: UIConstants.Spacing.medium) {
      Text(title)
        .font(.headline)
        .foregroundStyle(color)
      
      if let metadata = metadata {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.small) {
          Text("Exporté le: \(formatFrenchDate(metadata.exportedAt))")
            .font(.caption)
            .foregroundStyle(.primary)
          
          Text("Version: \(metadata.version)")
            .font(.caption)
            .foregroundStyle(.secondary)
          
          Text("Générateur: \(metadata.generator)")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      } else {
        Text("Pas de métadonnées")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(
      RoundedRectangle(cornerRadius: UIConstants.CornerRadius.large)
        .fill(color.opacity(0.1))
        .overlay(
          RoundedRectangle(cornerRadius: UIConstants.CornerRadius.large)
            .stroke(color.opacity(0.3), lineWidth: 1)
        )
    )
  }
  
  private func formatFrenchDate(_ dateString: String) -> String {
    let inputFormatter = DateFormatter()
    let outputFormatter = DateFormatter()
    outputFormatter.locale = Locale(identifier: "fr_FR")
    outputFormatter.dateStyle = .medium
    outputFormatter.timeStyle = .short
    
    for format in DateFormatPatterns.all {
      inputFormatter.dateFormat = format
      if let date = inputFormatter.date(from: dateString) {
        return outputFormatter.string(from: date)
      }
    }
    
    return dateString
  }
  
  // MARK: - Summary Cards
  
  private var summaryCardsGrid: some View {
    HStack(spacing: UIConstants.Spacing.extraLarge) {
      StatCard(
        title: "Tokens Ajoutés",
        value: "\(changes.added.count)",
        subtitle: "nouveaux tokens",
        color: .green,
        icon: "plus.circle.fill",
        action: { onTabTapped(.added) }
      )
      .staggeredAppear(index: 0)
      
      StatCard(
        title: "Tokens Supprimés",
        value: "\(changes.removed.count)",
        subtitle: "tokens retirés",
        color: .red,
        icon: "minus.circle.fill",
        action: { onTabTapped(.removed) }
      )
      .staggeredAppear(index: 1)
      
      StatCard(
        title: "Tokens Modifiés",
        value: "\(changes.modified.count)",
        subtitle: "couleurs changées",
        color: .orange,
        icon: "pencil.circle.fill",
        action: { onTabTapped(.modified) }
      )
      .staggeredAppear(index: 2)
    }
  }
}
