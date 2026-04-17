import SwiftUI

struct FeedView: View {
    @EnvironmentObject var store: ArticleStore

    /// Snapshot of the ranked+shuffled feed. Regenerated whenever the Feed tab
    /// appears or the user pulls to refresh, so each visit feels fresh.
    @State private var feed: [Article] = []

    /// Track which article is currently visible (for dwell tracking).
    @State private var currentArticleID: UUID?

    /// Whether the initial async feed load has completed.
    @State private var hasLoadedBackendFeed = false

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(feed) { article in
                            FeedCardView(article: article, safeArea: geo.safeAreaInsets)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .id(article.id)
                                .onAppear {
                                    onCardAppear(article)
                                }
                                .onDisappear {
                                    onCardDisappear(article)
                                }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
            }
            .ignoresSafeArea()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Article.self) { article in
                ArticleDetailView(article: article)
            }
            .onAppear { regenerateIfNeeded() }
            .onChange(of: store.articles.count) { _, _ in regenerate() }
        }
    }

    // MARK: - Dwell tracking

    private func onCardAppear(_ article: Article) {
        currentArticleID = article.id
        DwellTracker.shared.startTracking(article.id)
        store.markSeenInSession(id: article.id)
    }

    private func onCardDisappear(_ article: Article) {
        DwellTracker.shared.stopTracking(article.id)
        if currentArticleID == article.id {
            currentArticleID = nil
        }
    }

    // MARK: - Feed generation

    private func regenerateIfNeeded() {
        if feed.isEmpty { regenerate() }
    }

    private func regenerate() {
        // Show local feed immediately for instant UX
        feed = store.generateLocalFeed()

        // Then fetch the backend-personalised feed asynchronously
        Task {
            let backendFeed = await store.generateFeed()
            if !backendFeed.isEmpty {
                feed = backendFeed
                hasLoadedBackendFeed = true
            }
        }
    }
}
