import Foundation
import Combine

@MainActor
class ArticleStore: ObservableObject {
    @Published var articles: [Article]
    @Published var likedIDs: Set<UUID>
    @Published var bookmarkedIDs: Set<UUID>
    @Published var viewedIDs: Set<UUID>
    @Published var isLoading: Bool = false
    @Published var fetchError: String? = nil
    @Published var isShowingStaleData: Bool = false

    private var refreshTask: Task<Void, Never>? = nil
    private var cancellables: Set<AnyCancellable> = []

    private enum Keys {
        static let liked      = "NEWSHAWK_LIKED_IDS"
        static let bookmarked = "NEWSHAWK_BOOKMARKED_IDS"
        static let viewed     = "NEWSHAWK_VIEWED_IDS"
    }

    init() {
        // Restore persisted interactions before anything else so UI shows
        // correct like/bookmark state on first render.
        self.likedIDs      = Self.loadIDSet(forKey: Keys.liked)
        self.bookmarkedIDs = Self.loadIDSet(forKey: Keys.bookmarked)
        self.viewedIDs     = Self.loadIDSet(forKey: Keys.viewed)

        // Boot order: on-disk article cache → bundled mock data if the app
        // has never successfully fetched before.
        if let cached = ArticleStorage.load(), !cached.isEmpty {
            self.articles = cached
            self.isShowingStaleData = true
        } else {
            self.articles = MockData.articles
            self.isShowingStaleData = true
        }

        observeInteractionChanges()
        startRefreshLoop()
    }

    // MARK: - Persistence of user interactions

    private static func loadIDSet(forKey key: String) -> Set<UUID> {
        guard let raw = UserDefaults.standard.array(forKey: key) as? [String] else {
            return []
        }
        return Set(raw.compactMap(UUID.init(uuidString:)))
    }

    private static func saveIDSet(_ set: Set<UUID>, forKey key: String) {
        UserDefaults.standard.set(set.map(\.uuidString), forKey: key)
    }

    private func observeInteractionChanges() {
        $likedIDs
            .dropFirst()
            .sink { Self.saveIDSet($0, forKey: Keys.liked) }
            .store(in: &cancellables)
        $bookmarkedIDs
            .dropFirst()
            .sink { Self.saveIDSet($0, forKey: Keys.bookmarked) }
            .store(in: &cancellables)
        $viewedIDs
            .dropFirst()
            .sink { Self.saveIDSet($0, forKey: Keys.viewed) }
            .store(in: &cancellables)
    }

    // MARK: - Refresh loop

    private func startRefreshLoop() {
        refreshTask?.cancel()
        refreshTask = Task {
            while !Task.isCancelled {
                await refresh()
                try? await Task.sleep(for: .seconds(30 * 60))
            }
        }
    }

    func refresh() async {
        isLoading = true
        fetchError = nil
        do {
            let fetched = try await NewsService.fetchArticles()
            if !fetched.isEmpty {
                articles = fetched
                isShowingStaleData = false
                ArticleStorage.save(fetched)
            }
        } catch {
            fetchError = error.localizedDescription
            isShowingStaleData = true
        }
        isLoading = false
    }

    // MARK: - Article actions

    func likeArticle(id: UUID) {
        if likedIDs.contains(id) { likedIDs.remove(id) } else { likedIDs.insert(id) }
    }

    func bookmarkArticle(id: UUID) {
        if bookmarkedIDs.contains(id) { bookmarkedIDs.remove(id) } else { bookmarkedIDs.insert(id) }
    }

    func markViewed(id: UUID) {
        guard !viewedIDs.contains(id) else { return }   // avoid redundant disk writes
        viewedIDs.insert(id)
    }

    // MARK: - Queries

    func articles(in category: String) -> [Article] {
        guard category != "All" else { return articles }
        return articles.filter { $0.category == category }
    }

    var likedArticles: [Article]      { articles.filter { likedIDs.contains($0.id) } }
    var bookmarkedArticles: [Article] { articles.filter { bookmarkedIDs.contains($0.id) } }
    var viewedArticles: [Article]     { articles.filter { viewedIDs.contains($0.id) } }

    /// Build a fresh "For You" feed — personalised, diversified, and randomised.
    /// Call this every time you want a new order (e.g. on FeedView appear or
    /// pull-to-refresh). Two consecutive calls with the same profile will
    /// return different orderings.
    func generateFeed() -> [Article] {
        RecommendationEngine.feed(
            from: articles,
            using: .init(likedIDs: likedIDs, viewedIDs: viewedIDs, articles: articles)
        )
    }
}
