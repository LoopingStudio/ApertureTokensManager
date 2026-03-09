import ComposableArchitecture
import Foundation

extension GraphFeature {
  func handleViewAction(_ action: Action.View, state: inout State) -> EffectOf<Self> {
    switch action {
    case .onAppear:
      guard state.graph == nil, state.designSystemBase != nil else { return .none }
      state.isBuilding = true
      return buildGraphEffect(state: state)

    case .brandSelected(let brand):
      state.selectedBrand = brand
      state.isBuilding = true
      return .merge(
        .send(.analytics(.brandChanged(brand: brand))),
        buildGraphEffect(state: state)
      )

    case .appearanceSelected(let appearance):
      state.selectedAppearance = appearance
      state.isBuilding = true
      return .merge(
        .send(.analytics(.appearanceChanged(appearance: appearance))),
        buildGraphEffect(state: state)
      )

    case .searchTextChanged(let text):
      state.searchText = text
      if !text.isEmpty {
        return .send(.analytics(.searchPerformed(query: text)))
      }
      return .none

    case .zoomChanged(let scale):
      state.zoomScale = max(0.25, min(3.0, scale))
      return .send(.analytics(.zoomChanged(scale: Double(state.zoomScale))))

    case .nodeHovered(let id):
      state.hoveredNodeId = id
      return .none

    case .nodeSelected(let id):
      if state.selectedNodeId != id {
        state.isIsolating = false
      }
      state.selectedNodeId = id
      if let id, let node = state.graph?.nodes.first(where: { $0.id == id }) {
        return .send(.analytics(.nodeSelected(path: node.path)))
      }
      return .none

    case .hideUtilityToggled:
      state.hideUtility.toggle()
      state.isBuilding = true
      return buildGraphEffect(state: state)

    case .isolateToggled:
      state.isIsolating.toggle()
      return .none

    case .rebuildGraphTapped:
      state.isBuilding = true
      return buildGraphEffect(state: state)
    }
  }
}
