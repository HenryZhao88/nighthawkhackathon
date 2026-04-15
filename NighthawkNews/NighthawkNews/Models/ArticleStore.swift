import Foundation
import Combine

@MainActor
class ArticleStore: ObservableObject {
    @Published var articles: [Article]
    @Published var likedIDs: Set<UUID> = []
    @Published var bookmarkedIDs: Set<UUID> = []
    @Published var viewedIDs: Set<UUID> = []
    @Published var isLoading: Bool = false
    @Published var fetchError: String? = nil
    @Published var isShowingStaleData: Bool = false

    private var refreshTask: Task<Void, Never>? = nil

    init() {
        // Boot order: on-disk cache (real articles from last session) →
        // bundled mock data if the app has never fetched before.
        if let cached = ArticleStorage.load(), !cached.isEmpty {
            self.articles = cached
            self.isShowingStaleData = true
        } else {
            self.articles = MockData.articles
            self.isShowingStaleData = true
        }

        startRefreshLoop()
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
            // Network/backend unavailable — keep showing whatever we have
            // (disk cache or mock). UI can read fetchError + isShowingStaleData.
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
}
