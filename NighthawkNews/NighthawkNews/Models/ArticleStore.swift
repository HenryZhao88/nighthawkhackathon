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

    /// IDs of articles the user has scrolled past in this session (for /feed endpoint).
    @Published var sessionSeenIDs: Set<UUID> = []

    private var refreshTask: Task<Void, Never>? = nil
    private var cancellables: Set<AnyCancellable> = []

    private enum Keys {
        static let liked      = "NIGHTHAWK_LIKED_IDS"
        static let bookmarked = "NIGHTHAWK_BOOKMARKED_IDS"
        static let viewed     = "NIGHTHAWK_VIEWED_IDS"
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
                if Task.isCancelled { break }
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
        let wasLiked = likedIDs.contains(id)
        if wasLiked { likedIDs.remove(id) } else { likedIDs.insert(id) }
        // Only send the positive signal (unlike is implicit — no negative signal)
        if !wasLiked {
            InteractionService.shared.queue(articleID: id, interaction: "like")
        }
        pushState(articleID: id, kind: .liked, value: !wasLiked)
    }

    func bookmarkArticle(id: UUID) {
        let wasBookmarked = bookmarkedIDs.contains(id)
        if wasBookmarked { bookmarkedIDs.remove(id) } else { bookmarkedIDs.insert(id) }
        if !wasBookmarked {
            InteractionService.shared.queue(articleID: id, interaction: "bookmark")
        }
        pushState(articleID: id, kind: .bookmarked, value: !wasBookmarked)
    }

    func markViewed(id: UUID) {
        guard !viewedIDs.contains(id) else { return }
        viewedIDs.insert(id)
        pushState(articleID: id, kind: .viewed, value: true)
    }

    /// Record that this article appeared in the feed during this session.
    func markSeenInSession(id: UUID) {
        sessionSeenIDs.insert(id)
    }

    // MARK: - Queries

    func articles(in category: String) -> [Article] {
        guard category != "All" else { return articles }
        return articles.filter { $0.category == category }
    }

    var likedArticles: [Article]      { articles.filter { likedIDs.contains($0.id) } }
    var bookmarkedArticles: [Article] { articles.filter { bookmarkedIDs.contains($0.id) } }
    var viewedArticles: [Article]     { articles.filter { viewedIDs.contains($0.id) } }

    /// Build a personalised feed via the backend 5-stage pipeline.
    /// Falls back to the local RecommendationEngine when offline.
    func generateFeed() async -> [Article] {
        let userID = UserDefaults.standard.string(forKey: "NIGHTHAWK_USER_ID") ?? "anonymous"
        do {
            let feed = try await NewsService.fetchFeed(
                userID: userID,
                sessionSeen: Array(sessionSeenIDs)
            )
            if !feed.isEmpty { return feed }
        } catch {
            print("[ArticleStore] backend feed failed, falling back to local: \(error)")
        }
        // Offline fallback: local recommendation engine
        return RecommendationEngine.feed(
            from: articles,
            using: .init(likedIDs: likedIDs, viewedIDs: viewedIDs, articles: articles)
        )
    }

    // MARK: - Server-side state sync

    /// Replace local liked/bookmarked/viewed sets with the server's source of
    /// truth. Called on sign-in / app launch so a user's saved articles appear
    /// across devices. Local sets remain populated on failure (offline-friendly).
    func syncFromServer() async {
        let userID = UserDefaults.standard.string(forKey: "NIGHTHAWK_USER_ID") ?? ""
        let trimmed = userID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != "anonymous" else { return }

        do {
            let state = try await UserStateService.fetch(userID: trimmed)
            likedIDs      = Set(state.liked.compactMap(UUID.init(uuidString:)))
            bookmarkedIDs = Set(state.bookmarked.compactMap(UUID.init(uuidString:)))
            viewedIDs     = Set(state.viewed.compactMap(UUID.init(uuidString:)))
        } catch {
            print("[ArticleStore] state sync failed: \(error)")
        }
    }

    /// Fire-and-forget push of a single state change to the server. UI has
    /// already updated locally; failure here just means the next `syncFromServer`
    /// will reconcile (server state will lag until then).
    private func pushState(articleID: UUID, kind: UserStateService.Kind, value: Bool) {
        let userID = UserDefaults.standard.string(forKey: "NIGHTHAWK_USER_ID") ?? ""
        let trimmed = userID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != "anonymous" else { return }

        Task.detached {
            do {
                try await UserStateService.set(
                    userID: trimmed, articleID: articleID, kind: kind, value: value
                )
            } catch {
                print("[ArticleStore] state push failed (\(kind), value=\(value)): \(error)")
            }
        }
    }

    // MARK: - Account deletion

    /// Permanently delete all server-side data for the current user, then
    /// clear local liked / bookmarked / viewed state. The auth session itself
    /// is torn down by the caller via `AuthStore.deleteLocalAccount()`.
    /// Throws on network failure so the UI can surface an error and let the
    /// user retry — we do NOT want to wipe local state if the server still
    /// holds the user's data.
    func deleteAccount() async throws {
        let userID = UserDefaults.standard.string(forKey: "NIGHTHAWK_USER_ID") ?? ""
        let trimmed = userID.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty, trimmed != "anonymous" {
            try await UserStateService.deleteAccount(userID: trimmed)
        }
        likedIDs = []
        bookmarkedIDs = []
        viewedIDs = []
        sessionSeenIDs = []
        UserDefaults.standard.removeObject(forKey: "NIGHTHAWK_LIKED_IDS")
        UserDefaults.standard.removeObject(forKey: "NIGHTHAWK_BOOKMARKED_IDS")
        UserDefaults.standard.removeObject(forKey: "NIGHTHAWK_VIEWED_IDS")
    }

    /// Synchronous local-only feed for immediate display while backend loads.
    func generateLocalFeed() -> [Article] {
        RecommendationEngine.feed(
            from: articles,
            using: .init(likedIDs: likedIDs, viewedIDs: viewedIDs, articles: articles)
        )
    }
}
