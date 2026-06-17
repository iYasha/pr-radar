import SwiftUI

struct PanelView: View {
  let store: AppStore
  @Environment(\.colorScheme) private var colorScheme

  private var themeColors: ThemeColors {
    colorScheme == .dark ? .dark : .light
  }

  var body: some View {
    let theme = themeColors
    ZStack {
      VStack(spacing: 0) {
        HeaderView(store: store)
        TabBarView(store: store)
        summaryRow
        content
      }
      if let query = store.editingQuery {
        QueryEditorView(store: store, query: query)
          .transition(.move(edge: .trailing))
      }
      if store.showingSettings {
        SettingsView(store: store)
          .transition(.move(edge: .trailing))
      }
    }
    .frame(width: 400, height: 560)
    .background(theme.bg)
    .environment(\.theme, theme)
    .task { await store.appeared() }
    .animation(.easeInOut(duration: 0.18), value: store.editingId)
    .animation(.easeInOut(duration: 0.18), value: store.showingSettings)
  }

  @ViewBuilder
  private var summaryRow: some View {
    let theme = themeColors
    HStack(spacing: 7) {
      Text(store.activeQuery?.search ?? "")
        .font(.mono(10))
        .foregroundStyle(theme.fg3)
        .lineLimit(1)
        .truncationMode(.tail)
        .frame(maxWidth: .infinity, alignment: .leading)
      if let active = store.activeQuery {
        Button { store.editButtonTapped(active.id) } label: {
          Icon(kind: .sliders, size: 13)
            .foregroundStyle(theme.fg3)
            .frame(width: 24, height: 24)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, 13)
    .padding(.vertical, 7)
    .overlay(alignment: .bottom) { Rectangle().fill(theme.line).frame(height: 1) }
  }

  @ViewBuilder
  private var content: some View {
    switch store.ghStatus {
    case .missing:
      GHGuidanceView(kind: .missing)
    case .loggedOut:
      GHGuidanceView(kind: .loggedOut)
    case .ok, .error:
      list
    }
  }

  @ViewBuilder
  private var list: some View {
    if let error = store.activeError, store.activeList.isEmpty {
      GHGuidanceView(kind: .failure(error))
    } else if store.activeList.isEmpty {
      EmptyStateView()
    } else {
      MaybeScroll(axes: .vertical) {
        LazyVStack(spacing: 0) {
          ForEach(store.activeList) { pr in
            PRRowView(pr: pr)
          }
        }
      }
    }
  }
}

struct EmptyStateView: View {
  @Environment(\.theme) private var theme

  var body: some View {
    VStack(spacing: 8) {
      Icon(kind: .search, size: 22, weight: 1.6).foregroundStyle(theme.fg3)
      Text("No open PRs match this query")
        .font(.sans(13))
        .foregroundStyle(theme.fg2)
      Text("Edit the tokens to widen it")
        .font(.mono(10))
        .foregroundStyle(theme.fg3)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.horizontal, 24)
    .padding(.vertical, 48)
  }
}

struct GHGuidanceView: View {
  enum Kind {
    case missing, loggedOut
    case failure(String)
  }

  let kind: Kind
  @Environment(\.theme) private var theme

  var body: some View {
    VStack(spacing: 10) {
      Icon(kind: .gitPullRequest, size: 24, weight: 1.6).foregroundStyle(theme.fg3)
      Text(title).font(.sans(13, .medium)).foregroundStyle(theme.fg2)
      Text(detail)
        .font(.mono(10))
        .foregroundStyle(theme.fg3)
        .multilineTextAlignment(.center)
        .textSelection(.enabled)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.horizontal, 28)
    .padding(.vertical, 40)
  }

  private var title: String {
    switch kind {
    case .missing: return "GitHub CLI not found"
    case .loggedOut: return "Not signed in to GitHub"
    case .failure: return "Couldn't reach GitHub"
    }
  }

  private var detail: String {
    switch kind {
    case .missing:
      return "Install it with\nbrew install gh\nthen reopen PR Radar."
    case .loggedOut:
      return "Run\ngh auth login\nin Terminal, then refresh."
    case let .failure(message):
      return message
    }
  }
}
