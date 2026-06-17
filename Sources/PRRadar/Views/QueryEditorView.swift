import SwiftUI

struct QueryEditorView: View {
  let store: AppStore
  let query: SavedQuery
  @Environment(\.theme) private var theme
  @Environment(\.openURL) private var openURL

  @State private var name = ""
  @State private var tokenText = ""
  @FocusState private var fieldFocused: Bool

  private let syntaxHelpURL = URL(
    string: "https://docs.github.com/en/search-github/searching-on-github/searching-issues-and-pull-requests"
  )!

  var body: some View {
    VStack(spacing: 0) {
      header
      MaybeScroll(axes: .vertical) {
        VStack(alignment: .leading, spacing: 0) {
          eyebrow("Name")
          nameField
          queryEyebrow.padding(.top, 18)
          tokenBox
          matchesLine.padding(.top, 13)
          badgeToggle.padding(.top, 16)
          deleteButton.padding(.top, 22)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
      }
    }
    .background(theme.bg)
    .onAppear { name = query.name }
    .onChange(of: name) { _, newValue in store.rename(query.id, to: newValue) }
  }

  private var header: some View {
    HStack(spacing: 8) {
      Button { store.closeEditorButtonTapped() } label: {
        Icon(kind: .chevronLeft, size: 16)
          .foregroundStyle(theme.fg2)
          .frame(width: 27, height: 27)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      Text("Edit query").font(.sans(13, .semibold)).foregroundStyle(theme.fg)
      Spacer()
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

  private var queryEyebrow: some View {
    HStack(alignment: .firstTextBaseline, spacing: 3) {
      Text("QUERY")
        .font(.mono(9.5))
        .tracking(0.8)
        .foregroundStyle(theme.fg3)
      Button { openURL(syntaxHelpURL) } label: {
        Icon(kind: .helpCircle, size: 11, weight: 1.8)
          .foregroundStyle(theme.fg3)
          .frame(width: 14, height: 11, alignment: .center)
          .contentShape(Rectangle())
          .alignmentGuide(.firstTextBaseline) { d in d[VerticalAlignment.center] + 3 }
      }
      .buttonStyle(.plain)
      .help("Which filters can I use? — opens GitHub search syntax docs")
      Spacer()
    }
    .padding(.bottom, 8)
  }

  private var nameField: some View {
    TextField("", text: $name)
      .textFieldStyle(.plain)
      .font(.sans(14, .medium))
      .foregroundStyle(theme.fg)
      .padding(.horizontal, 11)
      .padding(.vertical, 9)
      .background(theme.bg2)
      .overlay(RoundedRectangle(cornerRadius: 6).stroke(theme.line2, lineWidth: 1))
      .clipShape(RoundedRectangle(cornerRadius: 6))
  }

  private var tokenBox: some View {
    FlowLayout(spacing: 6, lineSpacing: 6) {
      ForEach(Array(query.tokens.enumerated()), id: \.offset) { index, token in
        chip(token, index: index)
      }
      inputField
    }
    .padding(11)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(theme.bg2)
    .overlay(RoundedRectangle(cornerRadius: 6).stroke(theme.line2, lineWidth: 1))
    .clipShape(RoundedRectangle(cornerRadius: 6))
    .contentShape(Rectangle())
    .onTapGesture { fieldFocused = true }
  }

  private func chip(_ token: String, index: Int) -> some View {
    let parts = SavedQuery.tokenParts(token)
    return HStack(spacing: 4) {
      if let value = parts.value {
        Text(parts.key + ":").foregroundStyle(theme.fg3)
        Text(value).foregroundStyle(theme.fg)
      } else {
        Text(parts.key).foregroundStyle(theme.fg)
      }
      Button { store.removeToken(at: index, from: query.id) } label: {
        Icon(kind: .x, size: 9, weight: 2.2).foregroundStyle(theme.fg3)
      }
      .buttonStyle(.plain)
    }
    .font(.mono(11))
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(theme.chipBg)
    .overlay(RoundedRectangle(cornerRadius: 4).stroke(theme.line2, lineWidth: 1))
    .clipShape(RoundedRectangle(cornerRadius: 4))
    .onTapGesture { reedit(token, index: index) }
  }

  private var inputField: some View {
    TextField("type a qualifier\u{2026}", text: $tokenText)
      .textFieldStyle(.plain)
      .font(.mono(11))
      .foregroundStyle(theme.fg)
      .frame(minWidth: 90)
      .focused($fieldFocused)
      .onChange(of: tokenText) { _, newValue in handleChange(newValue) }
      .onSubmit { commit(tokenText) }
      .onKeyPress(.delete) {
        if tokenText.isEmpty {
          store.removeLastToken(from: query.id)
          return .handled
        }
        return .ignored
      }
  }

  private var matchesLine: some View {
    Text(matchesText)
      .font(.mono(10))
      .foregroundStyle(theme.fg3)
  }

  private var matchesText: String {
    guard let count = store.editorMatchCount else { return "Matching\u{2026}" }
    return "Matches \(count) open pull request\(count == 1 ? "" : "s") right now."
  }

  private var badgeToggle: some View {
    Button { store.toggleBadge(query.id) } label: {
      HStack(spacing: 7) {
        ZStack {
          RoundedRectangle(cornerRadius: 4)
            .fill(query.countInBadge ? Color.blue : theme.chipBg)
          if query.countInBadge {
            Icon(kind: .check, size: 9, weight: 2.4).foregroundStyle(.white)
          }
        }
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(theme.line2, lineWidth: 1))
        .frame(width: 15, height: 15)
        Text("Count in menu-bar badge")
          .font(.mono(10))
          .foregroundStyle(theme.fg2)
      }
    }
    .buttonStyle(.plain)
  }

  private var deleteButton: some View {
    Button { store.deleteCurrentQuery() } label: {
      HStack(spacing: 6) {
        Icon(kind: .trash, size: 12).foregroundStyle(.pink)
        Text("Delete query").font(.mono(10)).foregroundStyle(.pink)
      }
    }
    .buttonStyle(.plain)
  }

  // MARK: Token entry

  private func handleChange(_ value: String) {
    guard value.contains(",") else { return }
    let pieces = value.split(separator: ",", omittingEmptySubsequences: false)
    for piece in pieces.dropLast() {
      commit(String(piece))
    }
    tokenText = String(pieces.last ?? "")
  }

  private func commit(_ raw: String) {
    let trimmed = raw.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty else { tokenText = ""; return }
    store.addToken(trimmed, to: query.id)
    tokenText = ""
  }

  private func reedit(_ token: String, index: Int) {
    commit(tokenText)
    store.removeToken(at: index, from: query.id)
    tokenText = token
    fieldFocused = true
  }

}
