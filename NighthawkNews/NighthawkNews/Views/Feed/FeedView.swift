import SwiftUI

struct FeedView: View {
    @EnvironmentObject var store: ArticleStore

    /// Snapshot of the ranked+shuffled feed. Regenerated whenever the Feed tab
    /// appears or the user pulls to refresh, so each visit feels fresh.
    @State private var feed: [Article] = []

    var body: some View {
        NavigationStack {
            // GeometryReader ignores safe area so it measures the TRUE full screen
            // (behind status bar, behind tab bar). We pass those measurements into
            // the cards so they can place text/buttons dynamically.
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
            }
            .ignoresSafeArea()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Article.self) { article in
                ArticleDetailView(article: article)
            }
            .onAppear { regenerateIfNeeded() }
            // When the underlying article pool changes (backend refresh), reshuffle.
            .onChange(of: store.articles.count) { _, _ in regenerate() }
        }
    }

    private func regenerateIfNeeded() {
        if feed.isEmpty { regenerate() }
    }

    private func regenerate() {
        feed = store.generateFeed()
    }
}
