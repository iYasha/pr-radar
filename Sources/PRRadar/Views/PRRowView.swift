import SwiftUI

struct PRRowView: View {
  let pr: PullRequest
  @Environment(\.theme) private var theme
  @State private var hovering = false

  var body: some View {
    HStack(alignment: .top, spacing: 11) {
      AvatarView(login: pr.authorLogin, avatarURL: pr.authorAvatar, initials: pr.initials)
        .padding(.top, 1)

      VStack(alignment: .leading, spacing: 0) {
        titleRow
        metaRow.padding(.top, 5)
        tagRow.padding(.top, 8)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 11)
    .background(hovering ? theme.hover : .clear)
    .overlay(alignment: .bottom) {
      Rectangle().fill(theme.line).frame(height: 1)
    }
    .contentShape(Rectangle())
    .onHover { hovering = $0 }
    .onTapGesture { NSWorkspace.shared.open(pr.url) }
    .animation(.easeInOut(duration: 0.12), value: hovering)
  }

  private var titleRow: some View {
    HStack(alignment: .top, spacing: 10) {
      Text(pr.title)
        .font(.sans(13.5, .medium))
        .foregroundStyle(theme.fg)
        .lineLimit(2)
        .fixedSize(horizontal: false, vertical: true)
      Spacer(minLength: 0)
      HStack(spacing: 7) {
        if pr.ci != nil { ciGlyph }
        Text(pr.diffAdd).foregroundStyle(pr.additions > 0 ? .sage : theme.fg3)
        Text(pr.diffDel).foregroundStyle(pr.deletions > 0 ? .pink : theme.fg3)
      }
      .font(.mono(11))
      .padding(.top, 1)
    }
  }

  private var metaRow: some View {
    HStack(spacing: 7) {
      Text(pr.repo).foregroundStyle(theme.fg2)
      Text("#\(pr.number)").foregroundStyle(theme.fg3)
      Text("\u{00B7}").foregroundStyle(theme.fg3).opacity(0.5)
      Text(pr.age()).foregroundStyle(theme.fg3)
    }
    .font(.mono(10.5))
  }

  private var tagRow: some View {
    HStack(spacing: 6) {
      statusBadge
      ForEach(pr.labels, id: \.self) { label in
        Text(label)
          .font(.mono(9.5))
          .foregroundStyle(theme.fg2)
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
          .background(theme.chipBg)
          .overlay(RoundedRectangle(cornerRadius: 3).stroke(theme.line2, lineWidth: 1))
          .clipShape(RoundedRectangle(cornerRadius: 3))
      }
    }
  }

  private var statusBadge: some View {
    Text(pr.statusLabel.uppercased())
      .font(.mono(9))
      .foregroundStyle(pr.statusColor)
      .padding(.horizontal, 7)
      .padding(.vertical, 2)
      .background(pr.statusColor.opacity(0.13))
      .overlay(RoundedRectangle(cornerRadius: 3).stroke(pr.statusColor.opacity(0.28), lineWidth: 1))
      .clipShape(RoundedRectangle(cornerRadius: 3))
  }

  @ViewBuilder
  private var ciGlyph: some View {
    switch pr.ci {
    case .pass:
      Icon(kind: .check, size: 11, weight: 2.6).foregroundStyle(pr.ciColor)
    case .fail:
      Icon(kind: .x, size: 11, weight: 2.6).foregroundStyle(pr.ciColor)
    case .running:
      Circle().fill(pr.ciColor).frame(width: 7, height: 7)
    case nil:
      EmptyView()
    }
  }
}
