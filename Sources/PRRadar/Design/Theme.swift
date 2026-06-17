import SwiftUI

enum AppTheme: String, Codable, CaseIterable {
  case dark, light
}

extension Color {
  init(r: Double, g: Double, b: Double, a: Double = 1) {
    self.init(.sRGB, red: r / 255, green: g / 255, blue: b / 255, opacity: a)
  }

  static let sage = Color(r: 122, g: 138, b: 110)
  static let pink = Color(r: 204, g: 51, b: 102)
  static let clay = Color(r: 166, g: 138, b: 92)
  static let blue = Color(r: 47, g: 128, b: 237)
  static let cyan = Color(r: 58, g: 163, b: 181)
  static let periwinkle = Color(r: 130, g: 140, b: 173)
}

struct ThemeColors {
  let bg, bg2, bg3, fg, fg2, fg3, line, line2, hover, chipBg: Color

  static let dark = ThemeColors(
    bg: Color(r: 22, g: 25, b: 24),
    bg2: Color(r: 30, g: 33, b: 32),
    bg3: Color(r: 27, g: 30, b: 29),
    fg: Color(r: 237, g: 237, b: 238),
    fg2: Color(r: 168, g: 170, b: 171),
    fg3: Color(r: 120, g: 123, b: 124),
    line: Color(r: 255, g: 255, b: 255, a: 0.08),
    line2: Color(r: 255, g: 255, b: 255, a: 0.13),
    hover: Color(r: 255, g: 255, b: 255, a: 0.05),
    chipBg: Color(r: 255, g: 255, b: 255, a: 0.06)
  )

  static let light = ThemeColors(
    bg: Color(r: 255, g: 255, b: 255),
    bg2: Color(r: 248, g: 248, b: 250),
    bg3: Color(r: 245, g: 245, b: 250),
    fg: Color(r: 19, g: 22, b: 21),
    fg2: Color(r: 104, g: 106, b: 108),
    fg3: Color(r: 150, g: 152, b: 156),
    line: Color(r: 234, g: 234, b: 242),
    line2: Color(r: 223, g: 223, b: 230),
    hover: Color(r: 245, g: 245, b: 249),
    chipBg: Color(r: 245, g: 245, b: 249)
  )

  static func of(_ theme: AppTheme) -> ThemeColors {
    theme == .dark ? .dark : .light
  }
}

private struct ThemeKey: EnvironmentKey {
  static let defaultValue = ThemeColors.dark
}

extension EnvironmentValues {
  var theme: ThemeColors {
    get { self[ThemeKey.self] }
    set { self[ThemeKey.self] = newValue }
  }
}

enum Palette {
  static let accents: [Color] = [.sage, .pink, .clay, .blue, .cyan, .periwinkle]

  static func color(for key: String) -> Color {
    var hash: UInt64 = 5381
    for byte in key.utf8 {
      hash = (hash &* 33) &+ UInt64(byte)
    }
    return accents[Int(hash % UInt64(accents.count))]
  }
}

extension Font {
  static func sans(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
    .custom("Hanken Grotesk", size: size).weight(weight)
  }

  static func mono(_ size: CGFloat) -> Font {
    .custom("Fragment Mono", size: size)
  }

  static func serif(_ size: CGFloat) -> Font {
    .custom("Instrument Serif", size: size)
  }
}
