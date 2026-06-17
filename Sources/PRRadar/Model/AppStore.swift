import Foundation
import Observation

@MainActor
@Observable
final class AppStore {
  var queries: [SavedQuery]
  var activeId: String
  var editingId: String?
  var showingSettings = false
  var refreshInterval: TimeInterval
  var results: [String: QueryResult] = [:]
  var ghStatus: GHStatus = .ok
  var editorMatchCount: Int?
  var isRefreshing = false

  static let refreshOptions: [(label: String, seconds: TimeInterval)] = [
    ("1 min", 60), ("5 min", 300), ("15 min", 900), ("30 min", 1800)
  ]
  static let defaultRefreshInterval: TimeInterval = 300

  struct QueryResult {
    var prs: [PullRequest] = []
    var issueCount: Int = 0
    var lastFetched: Date?
    var error: String?
  }

  enum GHStatus: Equatable {
    case ok, missing, loggedOut
    case error(String)
  }

  static let shared = AppStore()

  private let client = GitHubClient()
  private let fetchLimit = 40
  private var timer: Timer?
  private var matchTask: Task<Void, Never>?
  private var started = false

  init() {
    let loaded = Persistence.load()
    queries = loaded?.queries ?? SavedQuery.defaults
    let fallback = (loaded?.queries ?? SavedQuery.defaults).first?.id ?? "review"
    activeId = loaded?.activeId ?? fallback
    refreshInterval = loaded?.refreshSeconds ?? Self.defaultRefreshInterval
    if !queries.contains(where: { $0.id == activeId }) {
      activeId = queries.first?.id ?? fallback
    }
  }

  // MARK: Derived

  var activeQuery: SavedQuery? {
    queries.first { $0.id == activeId } ?? queries.first
  }

  var editingQuery: SavedQuery? {
    guard let editingId else { return nil }
    return queries.first { $0.id == editingId }
  }

  var activeList: [PullRequest] {
    let prs = activeQuery.flatMap { results[$0.id]?.prs } ?? []
    return prs.sorted { $0.updatedAt > $1.updatedAt }
  }

  var activeError: String? {
    activeQuery.flatMap { results[$0.id]?.error }
  }

  func count(for id: String) -> Int {
    results[id]?.issueCount ?? 0
  }

  var knownRepos: [String] {
    var seen = Set<String>()
    var ordered: [String] = []
    for result in results.values {
      for pr in result.prs where !pr.repo.isEmpty && seen.insert(pr.repo).inserted {
        ordered.append(pr.repo)
      }
    }
    return Array(ordered.sorted().prefix(8))
  }

  var badgeCount: Int {
    queries
      .filter(\.countInBadge)
      .reduce(0) { $0 + count(for: $1.id) }
  }

  // MARK: Lifecycle

  func appeared() async {
    if !started {
      started = true
      startTimer()
    }
    await refreshAll()
  }

  private func startTimer() {
    timer?.invalidate()
    timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
      Task { @MainActor in await self?.refreshAll() }
    }
  }

  // MARK: Settings

  func settingsButtonTapped() {
    showingSettings = true
  }

  func closeSettingsButtonTapped() {
    showingSettings = false
  }

  func setRefreshInterval(_ seconds: TimeInterval) {
    guard seconds != refreshInterval else { return }
    refreshInterval = seconds
    persist()
    if started { startTimer() }
  }

  func refreshButtonTapped() async {
    await refreshAll()
  }

  func refreshAll() async {
    guard client.ghPath != nil else {
      ghStatus = .missing
      return
    }
    isRefreshing = true
    defer { isRefreshing = false }
    await withTaskGroup(of: (String, Result<SearchResult, Error>).self) { group in
      for query in queries {
        let id = query.id
        let search = query.search
        group.addTask { [client, fetchLimit] in
          do {
            let result = try await client.search(search, limit: fetchLimit)
            return (id, .success(result))
          } catch {
            return (id, .failure(error))
          }
        }
      }
      for await (id, outcome) in group {
        apply(outcome, to: id)
      }
    }
  }

  private func apply(_ outcome: Result<SearchResult, Error>, to id: String) {
    switch outcome {
    case let .success(result):
      ghStatus = .ok
      results[id] = QueryResult(
        prs: result.prs,
        issueCount: result.issueCount,
        lastFetched: Date(),
        error: nil
      )
    case let .failure(error):
      switch error {
      case GitHubError.notAuthenticated:
        ghStatus = .loggedOut
      case GitHubError.binaryMissing:
        ghStatus = .missing
      default:
        var current = results[id] ?? QueryResult()
        current.error = friendlyMessage(error)
        results[id] = current
      }
    }
  }

  private func friendlyMessage(_ error: Error) -> String {
    switch error {
    case let GitHubError.process(message): return message
    case let GitHubError.decode(message): return "Couldn't read GitHub response: \(message)"
    default: return error.localizedDescription
    }
  }

  // MARK: Tab actions

  func tabTapped(_ id: String) {
    activeId = id
    persist()
  }

  func addQueryButtonTapped() {
    let query = SavedQuery(
      id: SavedQuery.freshID(),
      name: "New query",
      tokens: ["is:open", "is:pr", "author:@me"],
      countInBadge: false
    )
    queries.append(query)
    activeId = query.id
    editingId = query.id
    persist()
    Task { await refresh(query.id) }
  }

  func move(from offsets: IndexSet, to destination: Int) {
    queries.move(fromOffsets: offsets, toOffset: destination)
    persist()
  }

  func reorder(from: Int, to: Int) {
    guard queries.indices.contains(from), to >= 0, to <= queries.count, from != to else { return }
    let item = queries.remove(at: from)
    queries.insert(item, at: min(to, queries.count))
    persist()
  }

  // MARK: Editor actions

  func editButtonTapped(_ id: String) {
    editingId = id
    editorMatchCount = count(for: id)
    scheduleMatchUpdate()
  }

  func closeEditorButtonTapped() {
    let id = editingId
    editingId = nil
    matchTask?.cancel()
    editorMatchCount = nil
    persist()
    if let id { Task { await refresh(id) } }
  }

  func rename(_ id: String, to name: String) {
    guard let index = queries.firstIndex(where: { $0.id == id }) else { return }
    queries[index].name = name
    persist()
  }

  func toggleBadge(_ id: String) {
    guard let index = queries.firstIndex(where: { $0.id == id }) else { return }
    queries[index].countInBadge.toggle()
    persist()
  }

  func addToken(_ raw: String, to id: String) {
    let token = raw.trimmingCharacters(in: .whitespaces)
    guard !token.isEmpty, let index = queries.firstIndex(where: { $0.id == id }) else { return }
    guard !queries[index].tokens.contains(token) else { return }
    queries[index].tokens.append(token)
    persist()
    scheduleMatchUpdate()
  }

  func removeToken(at tokenIndex: Int, from id: String) {
    guard let index = queries.firstIndex(where: { $0.id == id }) else { return }
    guard queries[index].tokens.indices.contains(tokenIndex) else { return }
    queries[index].tokens.remove(at: tokenIndex)
    persist()
    scheduleMatchUpdate()
  }

  func removeLastToken(from id: String) {
    guard let index = queries.firstIndex(where: { $0.id == id }),
          !queries[index].tokens.isEmpty
    else { return }
    queries[index].tokens.removeLast()
    persist()
    scheduleMatchUpdate()
  }

  func deleteCurrentQuery() {
    guard let id = editingId else { return }
    queries.removeAll { $0.id == id }
    if activeId == id {
      activeId = queries.first?.id ?? ""
    }
    editingId = nil
    results[id] = nil
    persist()
  }

  private func scheduleMatchUpdate() {
    matchTask?.cancel()
    guard let query = editingQuery else { return }
    let search = query.search
    matchTask = Task { [client] in
      try? await Task.sleep(for: .milliseconds(400))
      if Task.isCancelled { return }
      do {
        let result = try await client.search(search, limit: 1)
        if Task.isCancelled { return }
        editorMatchCount = result.issueCount
      } catch {
        editorMatchCount = nil
      }
    }
  }

  private func refresh(_ id: String) async {
    guard let query = queries.first(where: { $0.id == id }) else { return }
    do {
      let result = try await client.search(query.search, limit: fetchLimit)
      apply(.success(result), to: id)
    } catch {
      apply(.failure(error), to: id)
    }
  }

  // MARK: Sample data (offscreen render / previews)

  func loadSampleData() {
    func pr(_ n: Int, _ repo: String, _ login: String, _ title: String, _ add: Int, _ del: Int, _ mins: Double, _ review: String?, _ ci: String?, _ labels: [String]) -> PullRequest {
      PullRequest(
        id: "https://github.com/\(repo)/pull/\(n)",
        number: n, title: title,
        url: URL(string: "https://github.com/\(repo)/pull/\(n)")!,
        repo: repo, authorLogin: login, authorAvatar: nil,
        isDraft: false,
        updatedAt: Date(timeIntervalSinceNow: -mins * 60),
        additions: add, deletions: del,
        reviewDecision: review, ciState: ci, labels: labels
      )
    }
    let review = [
      pr(4795, "acme/dashboard", "tomv", "Keyboard navigation for the table cursor", 96, 14, 360, "REVIEW_REQUIRED", "SUCCESS", ["a11y"]),
      pr(4793, "acme/dashboard", "dano", "Add WebSocket reconnect to the live data stream", 120, 30, 2880, "REVIEW_REQUIRED", "FAILURE", ["bug"]),
      pr(4802, "acme/api", "meit", "Cite source rows in search answers", 178, 42, 240, "CHANGES_REQUESTED", "SUCCESS", ["search"]),
      pr(4810, "acme/reports", "priyan", "Add a sensitivity toggle to the report builder", 210, 30, 1440, "REVIEW_REQUIRED", "SUCCESS", ["ui"]),
      pr(4806, "acme/pipeline", "samr", "Cache the hourly aggregation query results", 64, 8, 480, "APPROVED", "PENDING", ["perf"])
    ]
    let mine = [
      pr(4812, "acme/dashboard", "you", "Add P50/P90 bands to the forecast endpoint", 312, 48, 120, nil, "SUCCESS", ["api"]),
      pr(4807, "acme/api", "you", "Refactor answer-card streaming to server-sent events", 540, 210, 1440, nil, "PENDING", ["perf"]),
      pr(4801, "acme/reports", "you", "Bump pandas to 2.2 and fix dtype warnings", 40, 40, 480, "CHANGES_REQUESTED", "FAILURE", ["deps"])
    ]
    results["review"] = QueryResult(prs: review, issueCount: review.count, lastFetched: Date(), error: nil)
    results["mine"] = QueryResult(prs: mine, issueCount: mine.count, lastFetched: Date(), error: nil)
    ghStatus = .ok
  }

  // MARK: Persistence

  private func persist() {
    Persistence.save(
      PersistedState(queries: queries, activeId: activeId, refreshSeconds: refreshInterval)
    )
  }
}
