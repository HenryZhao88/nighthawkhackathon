import SwiftUI

struct ArticleCard: View {
    let article: Article
    @EnvironmentObject var store: ArticleStore

    private var isLiked: Bool      { store.likedIDs.contains(article.id) }
    private var isBookmarked: Bool { store.bookmarkedIDs.contains(article.id) }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Thumbnail
            AsyncImageView(urlString: article.imageURL, category: article.category)
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.system(size: 17, weight: .bold))
                    .lineLimit(2)
                    .foregroundStyle(Color.primary)

                Text(article.excerpt)
                    .font(.system(size: 14))
                    .lineLimit(2)
                    .foregroundStyle(Color.secondary)

                Spacer(minLength: 6)

                HStack(spacing: 4) {
                    Text(article.source)
                    Text("·")
                    Text(article.publishedAt.timeAgoString())

                    Spacer()

                    // Like button
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                            store.likeArticle(id: article.id)
                        }
                    } label: {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundStyle(isLiked ? .red : Color(uiColor: .tertiaryLabel))
                            .font(.system(size: 15))
                    }
                    .buttonStyle(.plain)

                    // Bookmark button
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                            store.bookmarkArticle(id: article.id)
                        }
                    } label: {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .foregroundStyle(isBookmarked ? .yellow : Color(uiColor: .tertiaryLabel))
                            .font(.system(size: 15))
                    }
                    .buttonStyle(.plain)
                }
                .font(.caption)
                .foregroundStyle(Color(uiColor: .tertiaryLabel))

                if let bias = article.bias {
                    PoliticalBiasBar(bias: bias)
                        .padding(.top, 4)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}
