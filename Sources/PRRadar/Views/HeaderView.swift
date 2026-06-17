import AppKit
import SwiftUI

struct HeaderView: View {
  let store: AppStore
  @Environment(\.theme) private var theme

  var body: some View {
    HStack(spacing: 9) {
      ZStack {
        RoundedRectangle(cornerRadius: 7).fill(theme.chipBg)
        Icon(kind: .gitPullRequest, size: 14).foregroundStyle(theme.fg)
      }
      .frame(width: 25, height: 25)

      Text("PR Radar")
        .font(.sans(13, .semibold))
        .foregroundStyle(theme.fg)
        .frame(maxWidth: .infinity, alignment: .leading)

      Button { Task { await store.refreshButtonTapped() } } label: {
        Image(systemName: "arrow.clockwise")
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(theme.fg2)
          .frame(width: 27, height: 27)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .rotationEffect(.degrees(store.isRefreshing ? 360 : 0))
      .animation(store.isRefreshing ? .linear(duration: 0.9).repeatForever(autoreverses: false) : .default, value: store.isRefreshing)

      Button { store.settingsButtonTapped() } label: {
        Image(systemName: "gearshape")
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(theme.fg2)
          .frame(width: 27, height: 27)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .help("Settings")
    }
    .padding(.horizontal, 13)
    .padding(.vertical, 11)
    .background(theme.bg3)
    .overlay(alignment: .bottom) {
      Rectangle().fill(theme.line).frame(height: 1)
    }
  }
}
