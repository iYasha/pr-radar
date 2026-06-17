import SwiftUI

enum Feather {
  case gitPullRequest, plus, sliders, chevronLeft, x, trash, search, check, sun, helpCircle
}

struct FeatherShape: Shape {
  let kind: Feather

  func path(in rect: CGRect) -> Path {
    var path = Path()
    build(&path)
    let scale = CGAffineTransform(scaleX: rect.width / 24, y: rect.height / 24)
    return path.applying(scale)
  }

  private func build(_ p: inout Path) {
    switch kind {
    case .gitPullRequest:
      p.addEllipse(in: circle(18, 18, 3))
      p.addEllipse(in: circle(6, 6, 3))
      line(&p, 6, 9, 6, 21)
      p.move(to: pt(13, 6))
      p.addLine(to: pt(16, 6))
      p.addQuadCurve(to: pt(18, 8), control: pt(18, 6))
      p.addLine(to: pt(18, 15))
    case .plus:
      line(&p, 12, 5, 12, 19)
      line(&p, 5, 12, 19, 12)
    case .sliders:
      line(&p, 4, 21, 4, 14)
      line(&p, 4, 10, 4, 3)
      line(&p, 12, 21, 12, 12)
      line(&p, 12, 8, 12, 3)
      line(&p, 20, 21, 20, 16)
      line(&p, 20, 12, 20, 3)
      line(&p, 1, 14, 7, 14)
      line(&p, 9, 8, 15, 8)
      line(&p, 17, 16, 23, 16)
    case .chevronLeft:
      polyline(&p, [(15, 18), (9, 12), (15, 6)])
    case .x:
      line(&p, 18, 6, 6, 18)
      line(&p, 6, 6, 18, 18)
    case .trash:
      line(&p, 3, 6, 21, 6)
      polyline(&p, [(19, 6), (19, 21), (5, 21), (5, 6)])
      polyline(&p, [(9, 6), (9, 4), (15, 4), (15, 6)])
    case .search:
      p.addEllipse(in: circle(11, 11, 8))
      line(&p, 21, 21, 16.65, 16.65)
    case .check:
      polyline(&p, [(20, 6), (9, 17), (4, 12)])
    case .sun:
      p.addEllipse(in: circle(12, 12, 5))
      line(&p, 12, 1, 12, 3)
      line(&p, 12, 21, 12, 23)
      line(&p, 4.22, 4.22, 5.64, 5.64)
      line(&p, 18.36, 18.36, 19.78, 19.78)
      line(&p, 1, 12, 3, 12)
      line(&p, 21, 12, 23, 12)
      line(&p, 4.22, 19.78, 5.64, 18.36)
      line(&p, 18.36, 5.64, 19.78, 4.22)
    case .helpCircle:
      p.addEllipse(in: circle(12, 12, 10))
      p.move(to: pt(9.09, 9))
      p.addQuadCurve(to: pt(14.92, 10), control: pt(12, 6))
      p.addQuadCurve(to: pt(11.92, 13), control: pt(15.2, 12))
      line(&p, 12, 17, 12.01, 17)
    }
  }

  private func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

  private func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> CGRect {
    CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
  }

  private func line(_ p: inout Path, _ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat) {
    p.move(to: pt(x1, y1))
    p.addLine(to: pt(x2, y2))
  }

  private func polyline(_ p: inout Path, _ points: [(CGFloat, CGFloat)]) {
    guard let first = points.first else { return }
    p.move(to: pt(first.0, first.1))
    for point in points.dropFirst() {
      p.addLine(to: pt(point.0, point.1))
    }
  }
}

struct Icon: View {
  let kind: Feather
  var size: CGFloat = 16
  var weight: CGFloat = 2

  var body: some View {
    FeatherShape(kind: kind)
      .stroke(style: StrokeStyle(lineWidth: weight * size / 24, lineCap: .round, lineJoin: .round))
      .frame(width: size, height: size)
      .contentShape(Rectangle())
  }
}

struct MoonIcon: View {
  var size: CGFloat = 15
  let color: Color
  let background: Color

  var body: some View {
    ZStack {
      Circle().fill(color)
      Circle()
        .fill(background)
        .frame(width: size * 0.92, height: size * 0.92)
        .offset(x: size * 0.28, y: -size * 0.12)
    }
    .frame(width: size, height: size)
  }
}
