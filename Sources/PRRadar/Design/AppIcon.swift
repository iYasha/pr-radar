import SwiftUI

/// The macOS app-bundle icon: the git-pull-request mark in blue on a dark
/// squircle. Rendered to a 1024px master via `PRRADAR_ICON=1` (see AppDelegate),
/// then sliced into AppIcon.icns by Scripts/build-app.sh.
struct AppIconView: View {
  var body: some View {
    let canvas: CGFloat = 1024
    let inset: CGFloat = 92                 // transparent margin around the squircle
    let plate = canvas - inset * 2
    let radius = plate * 0.2237             // Apple's continuous-corner ratio
    let glyph = plate * 0.46

    return ZStack {
      RoundedRectangle(cornerRadius: radius, style: .continuous)
        .fill(
          LinearGradient(
            colors: [Color(r: 32, g: 35, b: 34), Color(r: 17, g: 19, b: 18)],
            startPoint: .top,
            endPoint: .bottom
          )
        )
        .overlay(
          RoundedRectangle(cornerRadius: radius, style: .continuous)
            .strokeBorder(Color.white.opacity(0.07), lineWidth: plate * 0.004)
        )
        .frame(width: plate, height: plate)
        .shadow(color: .black.opacity(0.35), radius: inset * 0.28, y: inset * 0.18)

      Icon(kind: .gitPullRequest, size: glyph, weight: 1.85)
        .foregroundStyle(Color.blue)
    }
    .frame(width: canvas, height: canvas)
  }
}
