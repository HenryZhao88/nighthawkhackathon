import SwiftUI

struct FeedView: View {
    @EnvironmentObject var store: ArticleStore

    var body: some View {
        NavigationStack {
            // GeometryReader ignores safe area so it measures the TRUE full screen
            // (behind status bar, behind tab bar). We pass those measurements into
            // the cards so they can place text/buttons dynamically.
            GeometryReader { geo in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(store.recommendedArticles) { article in
                            FeedCardView(article: article, safeArea: geo.safeAreaInsets)
                                .frame(width: geo.size.width, height: geo.size.height)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
            }
            .ignoresSafeArea()          // GeometryReader fills the real full screen
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Article.self) { article in
                ArticleDetailView(article: article)
            }
        }
    }
}
