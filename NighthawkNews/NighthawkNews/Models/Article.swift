import Foundation

struct Article: Identifiable, Hashable {
    let id: UUID
    let title: String
    let excerpt: String
    let body: String
    let imageURL: String?
    let source: String
    let category: String
    let publishedAt: Date
}
