import SwiftUI

// MARK: - Scan Progress View

struct ScanProgressView: View {
  let progress: ScanProgress
  let onCancel: () -> Void
  
  var body: some View {
    VStack(spacing: UIConstants.Spacing.large) {
      HStack {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.small) {
          Text(progress.phase.rawValue)
            .font(.headline)
          
          if !progress.currentDirectory.isEmpty {
            Text(progress.currentDirectory)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        
        Spacer()
        
        Button("Annuler") {
          onCancel()
        }
        .buttonStyle(.adaptiveGlass(.regular.tint(.red)))
        .controlSize(.small)
      }
      
      VStack(spacing: UIConstants.Spacing.small) {
        ProgressView(value: progress.progress)
          .progressViewStyle(.linear)
        
        HStack {
          Text("\(progress.filesScanned) / \(progress.totalFiles) fichiers")
            .font(.caption)
            .foregroundStyle(.secondary)
          
          Spacer()
          
          Text(progress.percentFormatted)
            .font(.caption)
            .fontWeight(.medium)
            .monospacedDigit()
        }
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: UIConstants.CornerRadius.xxLarge)
        .fill(Color(nsColor: .controlBackgroundColor))
    )
  }
}
