import SwiftUI

struct OverviewView: View {
  let changes: ComparisonChanges
  let oldFileMetadata: TokenMetadata?
  let newFileMetadata: TokenMetadata?
  let onTabTapped: (CompareFeature.ComparisonTab) -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      Text("Résumé des changements")
        .font(.title2)
        .fontWeight(.semibold)
      fileInfoSection
      summaryCardsGrid
      Spacer()
    }
  }
  
  // MARK: - File Info Section
  
  private var fileInfoSection: some View {
    HStack(spacing: 20) {
      fileInfoCard(title: "Ancienne Version", metadata: oldFileMetadata, color: .blue)
      
      Image(systemName: "arrow.right")
        .font(.title2)
        .foregroundStyle(.secondary)
      
      fileInfoCard(title: "Nouvelle Version", metadata: newFileMetadata, color: .green)
    }
    .padding(.bottom, 8)
  }
  
  private func fileInfoCard(title: String, metadata: TokenMetadata?, color: Color) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.headline)
        .foregroundStyle(color)
      
      if let metadata = metadata {
        VStack(alignment: .leading, spacing: 4) {
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
      RoundedRectangle(cornerRadius: 8)
        .fill(color.opacity(0.1))
        .overlay(
          RoundedRectangle(cornerRadius: 8)
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
    
    let formats = [
      "yyyy-MM-dd HH:mm:ss",
      "yyyy-MM-dd'T'HH:mm:ss",
      "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
      "yyyy-MM-dd"
    ]
    
    for format in formats {
      inputFormatter.dateFormat = format
      if let date = inputFormatter.date(from: dateString) {
        return outputFormatter.string(from: date)
      }
    }
    
    return dateString
  }
  
  // MARK: - Summary Cards
  
  private var summaryCardsGrid: some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
      summaryCard(title: "Tokens Ajoutés", count: changes.added.count, color: .green, icon: "plus.circle.fill") {
        onTabTapped(.added)
      }
      summaryCard(title: "Tokens Supprimés", count: changes.removed.count, color: .red, icon: "minus.circle.fill") {
        onTabTapped(.removed)
      }
      summaryCard(title: "Tokens Modifiés", count: changes.modified.count, color: .orange, icon: "pencil.circle.fill") {
        onTabTapped(.modified)
      }
    }
  }
  
  private func summaryCard(
    title: String,
    count: Int,
    color: Color,
    icon: String,
    onTap: @escaping () -> Void
  ) -> some View {
    VStack(spacing: 8) {
      Image(systemName: icon)
        .font(.largeTitle)
        .foregroundStyle(color)
      
      Text("\(count)")
        .font(.title)
        .fontWeight(.bold)
        .foregroundStyle(color)
      
      Text(title)
        .font(.headline)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, minHeight: 120)
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(color.opacity(0.1))
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(color.opacity(0.3), lineWidth: 1)
        )
    )
    .onTapGesture { onTap() }
  }
}
