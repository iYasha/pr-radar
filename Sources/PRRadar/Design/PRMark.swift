import AppKit
import SwiftUI

enum PRMark {
  // Feather git-pull-request, stroked as a menu-bar template image (24-unit viewBox).
  static let prImage: NSImage = {
    let size = NSSize(width: 15, height: 15)
    let image = NSImage(size: size, flipped: false) { rect in
      let s = min(rect.width, rect.height) / 24
      func p(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
        NSPoint(x: x * s, y: rect.height - y * s)
      }
      func circle(_ path: NSBezierPath, _ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) {
        let c = p(cx, cy)
        path.appendOval(in: NSRect(x: c.x - r * s, y: c.y - r * s, width: r * 2 * s, height: r * 2 * s))
      }
      let path = NSBezierPath()
      path.lineWidth = 2 * s
      path.lineCapStyle = .round
      path.lineJoinStyle = .round
      circle(path, 18, 18, 3)
      circle(path, 6, 6, 3)
      path.move(to: p(6, 9)); path.line(to: p(6, 21))
      path.move(to: p(13, 6))
      path.line(to: p(16, 6))
      path.curve(to: p(18, 8), controlPoint1: p(17.333, 6), controlPoint2: p(18, 6.667))
      path.line(to: p(18, 15))
      NSColor.black.setStroke()
      path.stroke()
      return true
    }
    image.isTemplate = true
    return image
  }()
}
