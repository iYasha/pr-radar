import AppKit
import CoreText
import ServiceManagement
import SwiftUI

@main
struct PRRadarApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
  @State private var store = AppStore.shared

  var body: some Scene {
    MenuBarExtra {
      PanelView(store: store)
    } label: {
      MenuBarLabel(store: store)
    }
    .menuBarExtraStyle(.window)
  }
}

struct MenuBarLabel: View {
  let store: AppStore

  var body: some View {
    let count = store.badgeCount
    HStack(spacing: 3) {
      Image(nsImage: PRMark.prImage)
      if count > 0 {
        Text("\(count)").font(.system(size: 11, weight: .medium))
      }
    }
  }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)
    registerBundledFonts()
    if ProcessInfo.processInfo.environment["PRRADAR_SHOT"] != nil {
      renderShots()
      return
    }
    if let iconOut = ProcessInfo.processInfo.environment["PRRADAR_ICON"] {
      renderIcon(to: iconOut)
      return
    }
    registerLoginItem()
    Task { @MainActor in await AppStore.shared.appeared() }
  }

  @MainActor
  private func renderShots() {
    let store = AppStore.shared
    store.loadSampleData()
    save(PanelView(store: store).environment(\.colorScheme, .dark), to: "/tmp/panel_list.png")
    save(PanelView(store: store).environment(\.colorScheme, .light), to: "/tmp/panel_light.png")
    if let editing = store.queries.first(where: { $0.id == "review" }) {
      store.editingId = editing.id
      store.editorMatchCount = 5
      save(PanelView(store: store).environment(\.colorScheme, .dark), to: "/tmp/panel_editor.png")
    }
    store.editingId = nil
    store.showingSettings = true
    save(
      SettingsView(store: store)
        .frame(width: 400, height: 560)
        .environment(\.theme, .dark)
        .environment(\.colorScheme, .dark),
      to: "/tmp/panel_settings.png"
    )
    NSApp.terminate(nil)
  }

  @MainActor
  private func renderIcon(to path: String) {
    let renderer = ImageRenderer(content: AppIconView())
    renderer.scale = 1
    guard
      let image = renderer.nsImage,
      let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:])
    else { NSApp.terminate(nil); return }
    try? png.write(to: URL(fileURLWithPath: path))
    NSApp.terminate(nil)
  }

  @MainActor
  private func save(_ view: some View, to path: String) {
    let renderer = ImageRenderer(content: view.environment(\.renderingSnapshot, true))
    renderer.scale = 2
    guard
      let image = renderer.nsImage,
      let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:])
    else { return }
    try? png.write(to: URL(fileURLWithPath: path))
  }

  private func registerBundledFonts() {
    let urls = bundledFontURLs()
    guard !urls.isEmpty else { return }
    CTFontManagerRegisterFontURLs(urls as CFArray, .process, true, nil)
  }

  // Resolve bundled fonts without `Bundle.module` (whose generated accessor
  // fatalErrors if the SPM resource bundle is absent, and expects a non-standard
  // path inside a real .app). Two layouts:
  //   .app       → Contents/Resources/Fonts/*.ttf  (also auto-registered via
  //                ATSApplicationFontsPath; we register again, harmlessly)
  //   swift run  → PRRadar_PRRadar.bundle/Fonts/*.ttf next to the executable
  private func bundledFontURLs() -> [URL] {
    if let urls = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts"),
       !urls.isEmpty {
      return urls
    }
    let devFonts = Bundle.main.bundleURL
      .appendingPathComponent("PRRadar_PRRadar.bundle")
      .appendingPathComponent("Fonts")
    let contents = try? FileManager.default.contentsOfDirectory(
      at: devFonts, includingPropertiesForKeys: nil
    )
    return (contents ?? []).filter { $0.pathExtension == "ttf" }
  }

  private func registerLoginItem() {
    guard SMAppService.mainApp.status != .enabled else { return }
    try? SMAppService.mainApp.register()
  }
}
