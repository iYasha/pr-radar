import SwiftUI

private struct SnapshotKey: EnvironmentKey {
  static let defaultValue = false
}

extension EnvironmentValues {
  var renderingSnapshot: Bool {
    get { self[SnapshotKey.self] }
    set { self[SnapshotKey.self] = newValue }
  }
}

struct MaybeScroll<Content: View>: View {
  @Environment(\.renderingSnapshot) private var snapshot
  let axes: Axis.Set
  @ViewBuilder var content: Content

  var body: some View {
    if snapshot {
      content
    } else {
      ScrollView(axes, showsIndicators: false) { content }
    }
  }
}
