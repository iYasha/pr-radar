import Foundation

struct PersistedState: Codable {
  var queries: [SavedQuery]
  var activeId: String
  var refreshSeconds: Double?   // optional: older state files predate this field
}

enum Persistence {
  private static var fileURL: URL? {
    guard let support = try? FileManager.default.url(
      for: .applicationSupportDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    ) else { return nil }
    let dir = support.appendingPathComponent("PR Radar", isDirectory: true)
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir.appendingPathComponent("state.json")
  }

  static func load() -> PersistedState? {
    guard let url = fileURL, let data = try? Data(contentsOf: url) else { return nil }
    return try? JSONDecoder().decode(PersistedState.self, from: data)
  }

  static func save(_ state: PersistedState) {
    guard let url = fileURL else { return }
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    guard let data = try? encoder.encode(state) else { return }
    try? data.write(to: url, options: .atomic)
  }
}
