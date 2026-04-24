import Foundation

@MainActor
final class SearchHistoryStore: ObservableObject {
    @Published private(set) var queries: [String]

    private static let key = "NEWSHAWK_SEARCH_HISTORY"
    private static let maxEntries = 10

    init() {
        let saved = UserDefaults.standard.stringArray(forKey: Self.key) ?? []
        self.queries = saved
    }

    func record(_ raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var next = queries.filter { $0.caseInsensitiveCompare(trimmed) != .orderedSame }
        next.insert(trimmed, at: 0)
        if next.count > Self.maxEntries { next = Array(next.prefix(Self.maxEntries)) }
        queries = next
        persist()
    }

    func remove(_ query: String) {
        queries.removeAll { $0 == query }
        persist()
    }

    func clear() {
        queries = []
        persist()
    }

    private func persist() {
        UserDefaults.standard.set(queries, forKey: Self.key)
    }
}
