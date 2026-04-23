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

    /// Prevent multiple feed loads from stacking.
    @State private var fetchTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(feed) { article in
                            FeedCardView(article: article, safeArea: geo.safeAreaInsets)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .id(article.id)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $currentArticleID)
            }
            .ignoresSafeArea()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Article.self) { article in
                ArticleDetailView(article: article)
            }
            .onAppear {
                regenerateIfNeeded()
                if let currentArticleID {
                    DwellTracker.shared.startTracking(currentArticleID, context: .feed)
                }
            }
            .onDisappear {
                if let currentArticleID {
                    DwellTracker.shared.stopTracking(currentArticleID, context: .feed)
                }
                fetchTask?.cancel()
            }
            .onChange(of: store.articles.count) { _, _ in regenerate() }
            .onChange(of: currentArticleID) { oldID, newID in
                if let oldID {
                    DwellTracker.shared.stopTracking(oldID, context: .feed)
                }
                if let newID {
                    DwellTracker.shared.startTracking(newID, context: .feed)
                    store.markSeenInSession(id: newID)
                }
            }
        }
    }

    // MARK: - Feed generation

    private func regenerateIfNeeded() {
        if feed.isEmpty { regenerate() }
    }

    private func regenerate() {
        fetchTask?.cancel()
        
        // Show local feed immediately for instant UX
        feed = store.generateLocalFeed()

        // Then fetch the backend-personalised feed asynchronously
        fetchTask = Task {
            let backendFeed = await store.generateFeed()
            if !Task.isCancelled, !backendFeed.isEmpty {
                feed = backendFeed
                hasLoadedBackendFeed = true
            }
        }
    }
}
