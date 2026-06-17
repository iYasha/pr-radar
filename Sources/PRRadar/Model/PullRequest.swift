import SwiftUI

struct PullRequest: Identifiable, Equatable {
  let id: String
  let number: Int
  let title: String
  let url: URL
  let repo: String
  let authorLogin: String
  let authorAvatar: URL?
  let isDraft: Bool
  let updatedAt: Date
  let additions: Int
  let deletions: Int
  let reviewDecision: String?
  let ciState: String?
  let labels: [String]

  enum CI {
    case pass, fail, running
  }

  var statusLabel: String {
    switch reviewDecision {
    case "APPROVED": return "Approved"
    case "CHANGES_REQUESTED": return "Changes"
    case "REVIEW_REQUIRED": return "Review"
    default: return "Pending"
    }
  }

  var statusColor: Color {
    switch reviewDecision {
    case "APPROVED": return .sage
    case "CHANGES_REQUESTED": return .pink
    case "REVIEW_REQUIRED": return .blue
    default: return .clay
    }
  }

  var ci: CI? {
    switch ciState {
    case "SUCCESS": return .pass
    case "FAILURE", "ERROR": return .fail
    case "PENDING", "EXPECTED": return .running
    default: return nil
    }
  }

  var ciText: String {
    switch ci {
    case .pass: return "checks pass"
    case .fail: return "checks failed"
    case .running: return "running"
    case nil: return ""
    }
  }

  var ciColor: Color {
    switch ci {
    case .pass: return .sage
    case .fail: return .pink
    case .running: return .cyan
    case nil: return .clay
    }
  }

  var initials: String {
    String(authorLogin.prefix(2)).uppercased()
  }

  var diffAdd: String { "+\(additions)" }
  var diffDel: String { "\u{2212}\(deletions)" }

  func age(now: Date = Date()) -> String {
    let seconds = max(0, now.timeIntervalSince(updatedAt))
    if seconds < 3600 { return "\(Int(seconds / 60))m" }
    if seconds < 86_400 { return "\(Int(seconds / 3600))h" }
    return "\(Int(seconds / 86_400))d"
  }
}
