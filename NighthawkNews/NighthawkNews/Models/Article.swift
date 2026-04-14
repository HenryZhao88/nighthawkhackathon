import Foundation

struct Article: Identifiable, Hashable, Decodable {
    let id: UUID
    let title: String
    let excerpt: String
    let body: String
    let imageURL: String?
    let source: String
    let category: String
    let publishedAt: Date
    let bias: Double?        // -1.0 (left) … 0.0 (center) … +1.0 (right); nil if unrated
}
