import SwiftUI
import ComposableArchitecture

struct AppView: View {
  @Bindable var store: StoreOf<AppFeature>
  
  var body: some View {
    TabView(selection: $store.selectedTab.sending(\.tabSelected)) {
      HomeView(store: store.scope(state: \.home, action: \.home))
        .tabItem {
          Label("Accueil", systemImage: "house.fill")
        }
        .tag(AppFeature.Tab.home)
      AnalysisView(store: store.scope(state: \.analysis, action: \.analysis))
        .tabItem {
          Label("Analyser", systemImage: "chart.bar.doc.horizontal")
        }
        .tag(AppFeature.Tab.analysis)
      CompareView(store: store.scope(state: \.compare, action: \.compare))
        .tabItem {
          Label("Comparer", systemImage: "doc.text.magnifyingglass")
        }
        .tag(AppFeature.Tab.compare)
      ImportView(store: store.scope(state: \.importer, action: \.importer))
        .tabItem {
          Label("Importer", systemImage: "square.and.arrow.down")
        }
        .tag(AppFeature.Tab.importer)
    }
    .frame(minWidth: 800, minHeight: 600)
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          store.send(.settingsButtonTapped)
        } label: {
          Image(systemName: "gear")
        }
        .help("Paramètres")
      }
    }
    .sheet(item: $store.scope(state: \.settings, action: \.settings)) { settingsStore in
      SettingsView(store: settingsStore)
    }
  }
}

#Preview {
  AppView(
    store: Store(initialState: AppFeature.State()) {
      AppFeature()
    }
  )
}
