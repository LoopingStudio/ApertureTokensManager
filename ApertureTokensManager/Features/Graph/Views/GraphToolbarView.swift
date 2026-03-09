import SwiftUI

struct GraphToolbarView: View {
  let selectedBrand: String
  let selectedAppearance: String
  let searchText: String
  let zoomScale: CGFloat
  let nodeCount: Int
  let edgeCount: Int
  let onBrandSelected: (String) -> Void
  let onAppearanceSelected: (String) -> Void
  let hideUtility: Bool
  let onSearchTextChanged: (String) -> Void
  let onZoomChanged: (CGFloat) -> Void
  let onHideUtilityToggled: () -> Void

  var body: some View {
    HStack(spacing: UIConstants.Spacing.extraLarge) {
      // Brand picker
      Picker("Brand", selection: Binding(
        get: { selectedBrand },
        set: { onBrandSelected($0) }
      )) {
        Text(Brand.legacy).tag(Brand.legacy)
        Text(Brand.newBrand).tag(Brand.newBrand)
      }
      .pickerStyle(.segmented)
      .labelsHidden()
      .frame(width: 200)

      // Appearance picker
      Picker("Theme", selection: Binding(
        get: { selectedAppearance },
        set: { onAppearanceSelected($0) }
      )) {
        Text("Light").tag(ThemeType.light)
        Text("Dark").tag(ThemeType.dark)
      }
      .pickerStyle(.segmented)
      .labelsHidden()
      .frame(width: 150)

      Toggle("Masquer Utility", isOn: Binding(
        get: { hideUtility },
        set: { _ in onHideUtilityToggled() }
      ))
      .toggleStyle(.checkbox)
      .font(.caption)

      Spacer()

      // Stats
      Text("\(nodeCount) tokens  \(edgeCount) liens")
        .font(.caption)
        .foregroundStyle(.secondary)

      // Zoom controls
      HStack(spacing: UIConstants.Spacing.small) {
        Button {
          onZoomChanged(zoomScale - 0.25)
        } label: {
          Image(systemName: "minus.magnifyingglass")
        }
        .buttonStyle(.borderless)

        Text("\(Int(zoomScale * 100))%")
          .font(.caption)
          .monospacedDigit()
          .frame(width: 40)

        Button {
          onZoomChanged(zoomScale + 0.25)
        } label: {
          Image(systemName: "plus.magnifyingglass")
        }
        .buttonStyle(.borderless)

        Button {
          onZoomChanged(1.0)
        } label: {
          Image(systemName: "1.magnifyingglass")
        }
        .buttonStyle(.borderless)
        .help("Reset zoom")
      }

      // Search
      TextField("Rechercher...", text: Binding(
        get: { searchText },
        set: { onSearchTextChanged($0) }
      ))
      .textFieldStyle(.roundedBorder)
      .frame(width: 180)
    }
    .padding(.horizontal, UIConstants.Spacing.extraLarge)
    .padding(.vertical, UIConstants.Spacing.medium)
    .background(.bar)
  }
}
