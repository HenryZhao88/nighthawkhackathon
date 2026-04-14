import Foundation
import Combine

@MainActor
class ArticleStore: ObservableObject {
    @Published var articles: [Article] = MockData.articles   // mock shown instantly
    @Published var likedIDs: Set<UUID> = []
    @Published var bookmarkedIDs: Set<UUID> = []
    @Published var viewedIDs: Set<UUID> = []
    @Published var isLoading: Bool = false
    @Published var fetchError: String? = nil

    private var refreshTask: Task<Void, Never>? = nil

    init() {
        // Fetch real articles immediately, then refresh every 30 minutes
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
            }
        } catch {
            // Network/backend unavailable — keep showing whatever we have
            fetchError = error.localizedDescription
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
