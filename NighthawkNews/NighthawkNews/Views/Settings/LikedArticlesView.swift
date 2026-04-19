import SwiftUI

struct LikedArticlesView: View {
    @EnvironmentObject var store: ArticleStore

    var body: some View {
        Group {
            if store.likedArticles.isEmpty {
                ContentUnavailableView(
                    "No Liked Articles",
                    systemImage: "heart",
                    description: Text("Articles you like in the Feed will appear here.")
                )
            } else {
                List(store.likedArticles) { article in
                    NavigationLink(value: article) {
                        ArticleRow(article: article)
                    }
                }
            }
        }
        .navigationDestination(for: Article.self) { article in
            ArticleDetailView(article: article)
        }
        .navigationTitle("Liked Articles")
    }
}

private struct ArticleRow: View {
    let article: Article

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(article.title)
                .font(.headline)
                .lineLimit(2)
            HStack(spacing: 4) {
                Text(article.source)
                Text("·")
                Text(article.publishedAt.timeAgoString())
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
