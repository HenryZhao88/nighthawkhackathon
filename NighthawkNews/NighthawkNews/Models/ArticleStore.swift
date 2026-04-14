import Foundation
import Combine

class ArticleStore: ObservableObject {
    @Published var articles: [Article] = MockData.articles
    @Published var likedIDs: Set<UUID> = []
    @Published var viewedIDs: Set<UUID> = []

    func likeArticle(id: UUID) {
        if likedIDs.contains(id) {
            likedIDs.remove(id)
        } else {
            likedIDs.insert(id)
        }
    }

    func markViewed(id: UUID) {
        viewedIDs.insert(id)
    }

    func articles(in category: String) -> [Article] {
        guard category != "All" else { return articles }
        return articles.filter { $0.category == category }
    }

    var likedArticles: [Article] {
        articles.filter { likedIDs.contains($0.id) }
    }

    var viewedArticles: [Article] {
        articles.filter { viewedIDs.contains($0.id) }
    }
}
