import SwiftUI
import ComposableArchitecture

/// Carte d'action pour l'export avec popover de filtres
struct ExportActionCard: View {
  @Bindable var store: StoreOf<HomeFeature>
  
  var body: some View {
    ActionCard(
      title: "Exporter vers Xcode",
      subtitle: "Générer XCAssets + Swift",
      icon: "square.and.arrow.up.fill",
      color: .blue
    ) {
      store.send(.view(.exportButtonTapped))
    }
    .popover(isPresented: $store.isExportPopoverPresented) {
      popoverContent
    }
  }
  
  @ViewBuilder
  private var popoverContent: some View {
    VStack(alignment: .leading, spacing: UIConstants.Spacing.medium) {
      popoverHeader
      Divider()
      filterToggles
      Divider()
      popoverActions
    }
    .padding()
    .frame(width: UIConstants.Size.popoverWidth)
  }
  
  private var popoverHeader: some View {
    HStack {
      Image(systemName: "gearshape.fill")
        .foregroundStyle(.blue)
      Text("Filtres d'export")
        .font(.headline)
    }
  }
  
  private var filterToggles: some View {
    VStack(alignment: .leading, spacing: UIConstants.Spacing.small) {
      Toggle(isOn: $store.filters.excludeTokensStartingWithHash) {
        HStack {
          Image(systemName: "number")
            .foregroundStyle(.orange)
            .frame(width: UIConstants.Spacing.xxLarge)
          Text("Exclure tokens commençant par #")
        }
      }
      .toggleStyle(.checkbox)
      
      Toggle(isOn: $store.filters.excludeTokensEndingWithHover) {
        HStack {
          Image(systemName: "cursorarrow.click")
            .foregroundStyle(.purple)
            .frame(width: UIConstants.Spacing.xxLarge)
          Text("Exclure tokens finissant par _hover")
        }
      }
      .toggleStyle(.checkbox)
      
      Toggle(isOn: $store.filters.excludeUtilityGroup) {
        HStack {
          Image(systemName: "wrench.fill")
            .foregroundStyle(.gray)
            .frame(width: UIConstants.Spacing.xxLarge)
          Text("Exclure groupe Utility")
        }
      }
      .toggleStyle(.checkbox)
    }
    .font(.callout)
  }
  
  private var popoverActions: some View {
    HStack {
      Button("Annuler") {
        store.send(.view(.dismissExportPopover))
      }
      .buttonStyle(.bordered)
      
      Spacer()
      
      Button {
        store.send(.view(.confirmExportButtonTapped))
      } label: {
        Label("Exporter", systemImage: "square.and.arrow.up")
      }
      .buttonStyle(.borderedProminent)
    }
  }
}
