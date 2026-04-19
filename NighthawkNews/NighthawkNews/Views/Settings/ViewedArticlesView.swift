import SwiftUI

struct ViewedArticlesView: View {
    @EnvironmentObject var store: ArticleStore

    var body: some View {
        Group {
            if store.viewedArticles.isEmpty {
                ContentUnavailableView(
                    "Nothing Viewed Yet",
                    systemImage: "clock",
                    description: Text("Articles you open will appear here.")
                )
            } else {
                List(store.viewedArticles) { article in
                    NavigationLink(value: article) {
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
            }
        }
        .navigationDestination(for: Article.self) { article in
            ArticleDetailView(article: article)
        }
        .navigationTitle("Previously Viewed")
    }
}
