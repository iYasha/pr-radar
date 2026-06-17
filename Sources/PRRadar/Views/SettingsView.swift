import AppKit
import SwiftUI

struct SettingsView: View {
  let store: AppStore
  @Environment(\.theme) private var theme

  var body: some View {
    VStack(spacing: 0) {
      header
      VStack(alignment: .leading, spacing: 0) {
        eyebrow("Update frequency")
        frequencyPicker
        caption.padding(.top, 8)
        Divider().overlay(theme.line).padding(.vertical, 18)
        HStack(spacing: 8) {
          if AppUpdater.shared.isAvailable {
            checkUpdatesButton
          }
          quitButton
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 14)
      .frame(maxWidth: .infinity, alignment: .leading)
      Spacer(minLength: 0)
      versionLine.padding(.bottom, 14)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(theme.bg)
  }

  private var header: some View {
    HStack(spacing: 8) {
      Button { store.closeSettingsButtonTapped() } label: {
        Icon(kind: .chevronLeft, size: 16)
          .foregroundStyle(theme.fg2)
          .frame(width: 27, height: 27)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      Text("Settings").font(.sans(13, .semibold)).foregroundStyle(theme.fg)
      Spacer()
      Button { store.closeSettingsButtonTapped() } label: {
        Icon(kind: .x, size: 15)
          .foregroundStyle(theme.fg2)
          .frame(width: 27, height: 27)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 13)
    .padding(.vertical, 11)
    .background(theme.bg3)
    .overlay(alignment: .bottom) { Rectangle().fill(theme.line).frame(height: 1) }
  }

  private func eyebrow(_ text: String) -> some View {
    Text(text.uppercased())
      .font(.mono(9.5))
      .tracking(0.8)
      .foregroundStyle(theme.fg3)
      .padding(.bottom, 8)
  }

  private var frequencyPicker: some View {
    HStack(spacing: 6) {
      ForEach(AppStore.refreshOptions, id: \.seconds) { option in
        let selected = store.refreshInterval == option.seconds
        Button { store.setRefreshInterval(option.seconds) } label: {
          Text(option.label)
            .font(.mono(11))
            .foregroundStyle(selected ? .white : theme.fg2)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(selected ? Color.blue : theme.chipBg)
            .overlay(
              RoundedRectangle(cornerRadius: 5)
                .stroke(selected ? Color.clear : theme.line2, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
      }
    }
  }

  private var caption: some View {
    Text("How often PR Radar refreshes in the background. It also refreshes when you open the panel.")
      .font(.mono(10))
      .foregroundStyle(theme.fg3)
      .fixedSize(horizontal: false, vertical: true)
  }

  private var checkUpdatesButton: some View {
    Button { AppUpdater.shared.checkForUpdates() } label: {
      HStack(spacing: 6) {
        Image(systemName: "arrow.down.circle").font(.system(size: 12, weight: .medium))
        Text("Check for Updates").font(.mono(10))
      }
      .foregroundStyle(theme.fg2)
      .padding(.horizontal, 11)
      .padding(.vertical, 8)
      .overlay(RoundedRectangle(cornerRadius: 6).stroke(theme.line2, lineWidth: 1))
    }
    .buttonStyle(.plain)
  }

  private var quitButton: some View {
    Button { NSApp.terminate(nil) } label: {
      HStack(spacing: 6) {
        Image(systemName: "power").font(.system(size: 12, weight: .medium))
        Text("Quit PR Radar").font(.mono(10))
      }
      .foregroundStyle(theme.fg2)
      .padding(.horizontal, 11)
      .padding(.vertical, 8)
      .overlay(RoundedRectangle(cornerRadius: 6).stroke(theme.line2, lineWidth: 1))
    }
    .buttonStyle(.plain)
    .keyboardShortcut("q")
  }

  private var versionLine: some View {
    Text("PR Radar \(appVersion)")
      .font(.mono(9.5))
      .foregroundStyle(theme.fg3)
      .frame(maxWidth: .infinity, alignment: .center)
  }

  private var appVersion: String {
    let info = Bundle.main.infoDictionary
    let short = info?["CFBundleShortVersionString"] as? String ?? "dev"
    return short
  }
}
