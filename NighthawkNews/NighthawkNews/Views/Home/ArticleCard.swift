import SwiftUI

struct ArticleCard: View {
    let article: Article

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
