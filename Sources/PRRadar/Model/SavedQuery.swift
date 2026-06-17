import Foundation

struct SavedQuery: Identifiable, Codable, Equatable {
  var id: String
  var name: String
  var tokens: [String]
  var countInBadge: Bool

  var search: String {
    tokens.joined(separator: " ")
  }

  static func tokenParts(_ token: String) -> (key: String, value: String?) {
    guard let colon = token.firstIndex(of: ":") else {
      return (token, nil)
    }
    return (String(token[..<colon]), String(token[token.index(after: colon)...]))
  }

  static func freshID() -> String {
    "q" + String(UInt64(Date().timeIntervalSince1970 * 1000))
  }

  static let defaults: [SavedQuery] = [
    SavedQuery(
      id: "review",
      name: "To review",
      tokens: ["is:open", "is:pr", "review-requested:@me", "draft:false"],
      countInBadge: true
    ),
    SavedQuery(
      id: "mine",
      name: "My PRs",
      tokens: ["is:open", "is:pr", "author:@me", "sort:updated-desc"],
      countInBadge: false
    )
  ]
}
