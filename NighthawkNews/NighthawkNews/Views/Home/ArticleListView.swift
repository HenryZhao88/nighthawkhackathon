import SwiftUI

struct ArticleListView: View {
    let articles: [Article]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(articles) { article in
                    NavigationLink(value: article) {
                        ArticleCard(article: article)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationDestination(for: Article.self) { article in
            ArticleDetailView(article: article)
        }
        .animation(.easeInOut(duration: 0.25), value: articles.map(\.id))
    }
}
