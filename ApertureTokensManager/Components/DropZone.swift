import SwiftUI
import UniformTypeIdentifiers

struct DropZone: View {
  let title: String
  let subtitle: String
  let isLoaded: Bool
  let isLoading: Bool
  let hasError: Bool
  let errorMessage: String?
  let primaryColor: Color
  let onDrop: ([NSItemProvider]) -> Bool
  let onSelectFile: () -> Void
  let onRemove: (() -> Void)?
  let metadata: TokenMetadata?
  
  @State private var isHovering = false
  @State private var isDragHovering = false
  @State private var isPressed = false
  @State private var iconScale: CGFloat = 1.0
  @State private var showContent = false
  @State private var checkmarkRotation: Double = 0
  
  init(
    title: String,
    subtitle: String,
    isLoaded: Bool = false,
    isLoading: Bool = false,
    hasError: Bool = false,
    errorMessage: String? = nil,
    primaryColor: Color = .blue,
    onDrop: @escaping ([NSItemProvider]) -> Bool,
    onSelectFile: @escaping () -> Void,
    onRemove: (() -> Void)? = nil,
    metadata: TokenMetadata? = nil
  ) {
    self.title = title
    self.subtitle = subtitle
    self.isLoaded = isLoaded
    self.isLoading = isLoading
    self.hasError = hasError
    self.errorMessage = errorMessage
    self.primaryColor = primaryColor
    self.onDrop = onDrop
    self.onSelectFile = onSelectFile
    self.onRemove = onRemove
    self.metadata = metadata
  }
  
  var body: some View {
    VStack(spacing: 16) {
      VStack(spacing: 12) {
        iconView
        
        Text(title)
          .font(.headline)
          .fontWeight(.semibold)
        
        statusView
        
        if let metadata = metadata {
          metadataView(metadata)
            .transition(.asymmetric(
              insertion: .scale(scale: 0.8).combined(with: .opacity),
              removal: .opacity
            ))
        }
      }
      
      if !isLoaded && !isLoading {
        Button("Sélectionner fichier") {
          onSelectFile()
        }
        .controlSize(.small)
        .scaleEffect(showContent ? 1 : 0.8)
        .opacity(showContent ? 1 : 0)
      }
      
      if isLoaded, let onRemove = onRemove {
        Button("Supprimer") {
          onRemove()
        }
        .controlSize(.small)
        .buttonStyle(.bordered)
        .transition(.asymmetric(
          insertion: .scale(scale: 0.8).combined(with: .opacity),
          removal: .scale(scale: 0.8).combined(with: .opacity)
        ))
      }
    }
    .frame(maxWidth: .infinity, minHeight: 200)
    .padding()
    .background(backgroundView)
    .scaleEffect(isPressed ? 0.98 : (isDragHovering ? 1.02 : 1.0))
    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragHovering)
    .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
    .onHover { hovering in
      withAnimation(.easeInOut(duration: 0.2)) {
        isHovering = hovering
      }
      // Subtle icon bounce on hover
      if hovering && !isLoaded {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
          iconScale = 1.1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
          withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            iconScale = 1.0
          }
        }
        NSCursor.pointingHand.push()
      } else {
        NSCursor.pop()
      }
    }
    .onTapGesture {
      if !isLoaded {
        // Press feedback
        withAnimation(.spring(response: 0.1, dampingFraction: 0.6)) {
          isPressed = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            isPressed = false
          }
          onSelectFile()
        }
      }
    }
    .onDrop(of: [UTType.json], isTargeted: Binding(
      get: { isDragHovering },
      set: { newValue in
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
          isDragHovering = newValue
        }
      }
    )) { providers in
      return onDrop(providers)
    }
    .onAppear {
      withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
        showContent = true
      }
    }
    .onChange(of: isLoaded) { _, newValue in
      if newValue {
        // Celebrate with a checkmark rotation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
          checkmarkRotation = 360
        }
      } else {
        checkmarkRotation = 0
      }
    }
  }
  
  @ViewBuilder
  private var iconView: some View {
    Group {
      if isLoading {
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle())
          .scaleEffect(1.2)
      } else if hasError {
        Image(systemName: "exclamationmark.circle.fill")
          .font(.largeTitle)
          .foregroundStyle(.red)
          .symbolEffect(.pulse, options: .repeating)
      } else if isLoaded {
        Image(systemName: "checkmark.circle.fill")
          .font(.largeTitle)
          .foregroundStyle(.green)
          .rotationEffect(.degrees(checkmarkRotation))
          .scaleEffect(checkmarkRotation > 0 ? 1.0 : 0.5)
      } else {
        Image(systemName: "doc.text")
          .font(.largeTitle)
          .foregroundStyle(primaryColor)
          .scaleEffect(iconScale)
          .scaleEffect(isDragHovering ? 1.15 : 1.0)
          .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragHovering)
      }
    }
    .contentTransition(.symbolEffect(.replace))
  }
  
  @ViewBuilder
  private var statusView: some View {
    Group {
      if isLoading {
        Text("Chargement en cours...")
          .font(.caption)
          .foregroundStyle(.secondary)
      } else if hasError {
        VStack(spacing: 4) {
          Text("Erreur de chargement")
            .font(.caption)
            .foregroundStyle(.red)
          
          if let errorMessage = errorMessage {
            Text(errorMessage)
              .font(.caption2)
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.center)
          }
        }
      } else if isLoaded {
        Text("Fichier chargé")
          .font(.caption)
          .foregroundStyle(.green)
      } else {
        Text(isDragHovering ? "Déposez le fichier ici" : subtitle)
          .font(.caption)
          .foregroundStyle(isDragHovering ? primaryColor : .secondary)
          .multilineTextAlignment(.center)
          .animation(.easeInOut(duration: 0.2), value: isDragHovering)
      }
    }
    .contentTransition(.interpolate)
  }
  
  private func metadataView(_ metadata: TokenMetadata) -> some View {
    VStack(spacing: 2) {
      Text("Exporté le")
        .font(.caption2)
        .foregroundStyle(.tertiary)
      
      Text(metadata.exportedAt.formatFrenchDate)
        .font(.caption)
        .foregroundStyle(.secondary)
      
      Text("Version \(metadata.version)")
        .font(.caption2)
        .foregroundStyle(.tertiary)
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(
      Capsule()
        .fill(Color.secondary.opacity(0.1))
    )
  }
  
  @ViewBuilder
  private var backgroundView: some View {
    RoundedRectangle(cornerRadius: 12)
      .fill(backgroundColor)
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(
            borderColor,
            style: StrokeStyle(
              lineWidth: isDragHovering ? 3 : 2,
              dash: isLoaded ? [] : [8]
            )
          )
      )
      .shadow(
        color: isDragHovering ? primaryColor.opacity(0.3) : .clear,
        radius: isDragHovering ? 8 : 0
      )
      .animation(.easeInOut(duration: 0.2), value: isDragHovering)
      .animation(.easeInOut(duration: 0.3), value: isLoaded)
  }
  
  private var backgroundColor: Color {
    if hasError {
      return Color.red.opacity(0.1)
    } else if isLoaded {
      return Color.green.opacity(0.1)
    } else if isHovering {
      return primaryColor.opacity(0.15)
    } else {
      return primaryColor.opacity(0.1)
    }
  }
  
  private var borderColor: Color {
    if hasError {
      return .red
    } else if isLoaded {
      return .green
    } else if isHovering {
      return primaryColor
    } else {
      return primaryColor.opacity(0.6)
    }
  }
}

#Preview {
  VStack(spacing: 20) {
    // État normal
    DropZone(
      title: "Fichier de tokens",
      subtitle: "Glissez votre fichier JSON ici",
      primaryColor: .purple,
      onDrop: { _ in true },
      onSelectFile: { }
    )
    
    // État chargé avec métadonnées
    DropZone(
      title: "Ancienne Version",
      subtitle: "Fichier chargé",
      isLoaded: true,
      primaryColor: .blue,
      onDrop: { _ in true },
      onSelectFile: { },
      metadata: TokenMetadata(
        exportedAt: "2026-01-28 14:30:00",
        timestamp: 1738068600,
        version: "1.2.3",
        generator: "Figma"
      )
    )
    
    // État d'erreur
    DropZone(
      title: "Nouvelle Version",
      subtitle: "Glissez le fichier ici",
      hasError: true,
      errorMessage: "Format de fichier invalide",
      primaryColor: .blue,
      onDrop: { _ in true },
      onSelectFile: { }
    )
    
    // État de chargement
    DropZone(
      title: "Fichier en cours",
      subtitle: "Traitement...",
      isLoading: true,
      primaryColor: .green,
      onDrop: { _ in true },
      onSelectFile: { }
    )
  }
  .padding()
  .frame(width: 400)
}
