import Foundation

struct SearchResult {
  var issueCount: Int
  var prs: [PullRequest]
}

enum GitHubError: Error {
  case binaryMissing
  case notAuthenticated
  case process(String)
  case decode(String)
}

final class GitHubClient {
  let ghPath: String?

  init() {
    ghPath = Self.locateGH()
  }

  static func locateGH() -> String? {
    let candidates = [
      "/opt/homebrew/bin/gh",
      "/usr/local/bin/gh",
      "/usr/bin/gh",
      NSHomeDirectory() + "/.local/bin/gh",
      "/run/current-system/sw/bin/gh"
    ]
    let fm = FileManager.default
    return candidates.first { fm.isExecutableFile(atPath: $0) }
  }

  private static let graphQL = """
  query($q: String!, $n: Int!) {
    search(query: $q, type: ISSUE, first: $n) {
      issueCount
      nodes {
        ... on PullRequest {
          number title url isDraft updatedAt additions deletions
          author { login avatarUrl }
          repository { nameWithOwner }
          reviewDecision
          labels(first: 8) { nodes { name } }
          commits(last: 1) { nodes { commit { statusCheckRollup { state } } } }
        }
      }
    }
  }
  """

  private func injectIsPR(_ query: String) -> String {
    let hasIsPR = query
      .split(separator: " ")
      .contains { $0.lowercased() == "is:pr" }
    return hasIsPR ? query : "is:pr " + query
  }

  func search(_ query: String, limit: Int) async throws -> SearchResult {
    guard let gh = ghPath else { throw GitHubError.binaryMissing }
    let composed = injectIsPR(query)
    let args = [
      "api", "graphql",
      "-F", "n=\(limit)",
      "-f", "q=\(composed)",
      "-f", "query=\(Self.graphQL)"
    ]
    let (stdout, stderr, code) = try await run(gh, args)

    if code != 0 {
      let message = String(decoding: stderr, as: UTF8.self)
      if Self.looksUnauthenticated(message) { throw GitHubError.notAuthenticated }
      throw GitHubError.process(message.isEmpty ? "gh exited \(code)" : message)
    }

    return try decode(stdout)
  }

  private static func looksUnauthenticated(_ message: String) -> Bool {
    let lower = message.lowercased()
    return lower.contains("gh auth login")
      || lower.contains("authentication")
      || lower.contains("http 401")
      || lower.contains("not logged")
  }

  private func decode(_ data: Data) throws -> SearchResult {
    let response: GQLResponse
    do {
      response = try JSONDecoder().decode(GQLResponse.self, from: data)
    } catch {
      throw GitHubError.decode(error.localizedDescription)
    }
    if let errors = response.errors, !errors.isEmpty, response.data == nil {
      let message = errors.map(\.message).joined(separator: "; ")
      if Self.looksUnauthenticated(message) { throw GitHubError.notAuthenticated }
      throw GitHubError.process(message)
    }
    guard let search = response.data?.search else {
      throw GitHubError.decode("missing search payload")
    }
    let formatter = ISO8601DateFormatter()
    let prs: [PullRequest] = search.nodes.compactMap { node in
      guard
        let number = node.number,
        let title = node.title,
        let urlString = node.url,
        let url = URL(string: urlString)
      else { return nil }
      return PullRequest(
        id: urlString,
        number: number,
        title: title,
        url: url,
        repo: node.repository?.nameWithOwner ?? "",
        authorLogin: node.author?.login ?? "ghost",
        authorAvatar: node.author?.avatarUrl.flatMap(URL.init(string:)),
        isDraft: node.isDraft ?? false,
        updatedAt: node.updatedAt.flatMap { formatter.date(from: $0) } ?? .distantPast,
        additions: node.additions ?? 0,
        deletions: node.deletions ?? 0,
        reviewDecision: node.reviewDecision,
        ciState: node.commits?.nodes.first?.commit.statusCheckRollup?.state,
        labels: node.labels?.nodes.map(\.name) ?? []
      )
    }
    return SearchResult(issueCount: search.issueCount, prs: prs)
  }

  private func run(_ launchPath: String, _ args: [String]) async throws -> (Data, Data, Int32) {
    try await withCheckedThrowingContinuation { continuation in
      let process = Process()
      process.executableURL = URL(fileURLWithPath: launchPath)
      process.arguments = args
      let outPipe = Pipe()
      let errPipe = Pipe()
      process.standardOutput = outPipe
      process.standardError = errPipe
      process.terminationHandler = { proc in
        let out = outPipe.fileHandleForReading.readDataToEndOfFile()
        let err = errPipe.fileHandleForReading.readDataToEndOfFile()
        continuation.resume(returning: (out, err, proc.terminationStatus))
      }
      do {
        try process.run()
      } catch {
        continuation.resume(throwing: GitHubError.process(error.localizedDescription))
      }
    }
  }
}

private struct GQLResponse: Decodable {
  let data: GQLData?
  let errors: [GQLError]?
}

private struct GQLError: Decodable {
  let message: String
}

private struct GQLData: Decodable {
  let search: GQLSearch
}

private struct GQLSearch: Decodable {
  let issueCount: Int
  let nodes: [GQLNode]
}

private struct GQLNode: Decodable {
  let number: Int?
  let title: String?
  let url: String?
  let isDraft: Bool?
  let updatedAt: String?
  let additions: Int?
  let deletions: Int?
  let author: GQLAuthor?
  let repository: GQLRepo?
  let reviewDecision: String?
  let labels: GQLLabels?
  let commits: GQLCommits?
}

private struct GQLAuthor: Decodable {
  let login: String?
  let avatarUrl: String?
}

private struct GQLRepo: Decodable {
  let nameWithOwner: String
}

private struct GQLLabels: Decodable {
  let nodes: [GQLLabel]
}

private struct GQLLabel: Decodable {
  let name: String
}

private struct GQLCommits: Decodable {
  let nodes: [GQLCommitNode]
}

private struct GQLCommitNode: Decodable {
  let commit: GQLCommit
}

private struct GQLCommit: Decodable {
  let statusCheckRollup: GQLRollup?
}

private struct GQLRollup: Decodable {
  let state: String?
}
