import SwiftUI

struct ArticleDetailView: View {
    let article: Article
    @EnvironmentObject var store: ArticleStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // MARK: Hero image 16:9
                AsyncImageView(urlString: article.imageURL, category: article.category)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .clipped()

                VStack(alignment: .leading, spacing: 16) {
                    // Headline
                    Text(article.title)
                        .font(.largeTitle.weight(.bold))
                        .fixedSize(horizontal: false, vertical: true)

                    // Source + time
                    HStack(spacing: 4) {
                        Text(article.source)
                            .fontWeight(.semibold)
                        Text("·")
                        Text(article.publishedAt.timeAgoString())
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    if let bias = article.bias {
                        PoliticalBiasBar(bias: bias)
                    }

                    Divider()

                    // Body
                    Text(article.body)
                        .font(.system(size: 17))
                        .lineSpacing(7)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            store.markViewed(id: article.id)
        }
    }
}
