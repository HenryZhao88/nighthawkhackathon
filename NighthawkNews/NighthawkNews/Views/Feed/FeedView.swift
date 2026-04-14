import SwiftUI

struct FeedView: View {
    @EnvironmentObject var store: ArticleStore

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(store.articles) { article in
                        FeedCardView(article: article)
                            .containerRelativeFrame([.horizontal, .vertical])
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .ignoresSafeArea()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Article.self) { article in
                ArticleDetailView(article: article)
            }
        }
    }
}
