import SwiftUI

struct FlowLayout: Layout {
  var spacing: CGFloat = 6
  var lineSpacing: CGFloat = 6

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
    let maxWidth = proposal.width ?? .infinity
    let rows = arrange(subviews, maxWidth: maxWidth)
    let height = rows.reduce(0) { $0 + $1.height } + CGFloat(max(0, rows.count - 1)) * lineSpacing
    return CGSize(width: maxWidth.isFinite ? maxWidth : rows.map(\.width).max() ?? 0, height: height)
  }

  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
    let rows = arrange(subviews, maxWidth: bounds.width)
    var y = bounds.minY
    for row in rows {
      var x = bounds.minX
      for index in row.indices {
        let size = subviews[index].sizeThatFits(.unspecified)
        let offsetY = (row.height - size.height) / 2
        subviews[index].place(
          at: CGPoint(x: x, y: y + offsetY),
          anchor: .topLeading,
          proposal: ProposedViewSize(size)
        )
        x += size.width + spacing
      }
      y += row.height + lineSpacing
    }
  }

  private struct Row {
    var indices: [Int] = []
    var width: CGFloat = 0
    var height: CGFloat = 0
  }

  private func arrange(_ subviews: Subviews, maxWidth: CGFloat) -> [Row] {
    var rows: [Row] = []
    var current = Row()
    for index in subviews.indices {
      let size = subviews[index].sizeThatFits(.unspecified)
      let needed = current.indices.isEmpty ? size.width : current.width + spacing + size.width
      if needed > maxWidth, !current.indices.isEmpty {
        rows.append(current)
        current = Row()
        current.indices = [index]
        current.width = size.width
        current.height = size.height
      } else {
        if !current.indices.isEmpty { current.width += spacing }
        current.indices.append(index)
        current.width += size.width
        current.height = max(current.height, size.height)
      }
    }
    if !current.indices.isEmpty { rows.append(current) }
    return rows
  }
}
