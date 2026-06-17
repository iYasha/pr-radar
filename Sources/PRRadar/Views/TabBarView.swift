import SwiftUI

struct TabBarView: View {
  let store: AppStore
  @Environment(\.theme) private var theme

  var body: some View {
    MaybeScroll(axes: .horizontal) {
      HStack(spacing: 4) {
        ForEach(store.queries) { query in
          tab(query)
        }
        addButton
      }
      .padding(.horizontal, 9)
      .padding(.vertical, 8)
    }
    .background(theme.bg3)
    .overlay(alignment: .bottom) {
      Rectangle().fill(theme.line).frame(height: 1)
    }
  }

  private func tab(_ query: SavedQuery) -> some View {
    let active = query.id == store.activeId
    return HStack(spacing: 6) {
      Text(query.name)
        .font(.sans(12, .medium))
        .foregroundStyle(active ? theme.fg : theme.fg2)
      Text("\(store.count(for: query.id))")
        .font(.mono(9))
        .foregroundStyle(active ? theme.fg2 : theme.fg3)
        .padding(.horizontal, 5)
        .frame(height: 14)
        .background(active ? theme.chipBg : .clear)
        .overlay(
          RoundedRectangle(cornerRadius: 999)
            .stroke(active ? theme.line2 : .clear, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 999))
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 5)
    .background(active ? theme.bg : .clear)
    .overlay(
      RoundedRectangle(cornerRadius: 6)
        .stroke(active ? theme.line2 : .clear, lineWidth: 1)
    )
    .clipShape(RoundedRectangle(cornerRadius: 6))
    .shadow(color: active ? .black.opacity(0.05) : .clear, radius: 1, y: 1)
    .contentShape(Rectangle())
    .onTapGesture { store.tabTapped(query.id) }
    .draggable(query.id)
    .dropDestination(for: String.self) { items, _ in
      handleDrop(items, onto: query.id)
    }
  }

  private func handleDrop(_ items: [String], onto targetID: String) -> Bool {
    guard
      let dragged = items.first,
      let from = store.queries.firstIndex(where: { $0.id == dragged }),
      let to = store.queries.firstIndex(where: { $0.id == targetID })
    else { return false }
    store.reorder(from: from, to: to)
    return true
  }

  private var addButton: some View {
    Button { store.addQueryButtonTapped() } label: {
      Icon(kind: .plus, size: 14)
        .foregroundStyle(theme.fg3)
        .frame(width: 28, height: 28)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}
