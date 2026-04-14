import SwiftUI

struct FeedCardView: View {
    let article: Article
    @EnvironmentObject var store: ArticleStore

    private var isLiked: Bool { store.likedIDs.contains(article.id) }

    var body: some View {
        ZStack(alignment: .bottom) {
            // MARK: - Background + Tappable navigation layer
            NavigationLink(value: article) {
                ZStack(alignment: .bottom) {
                    // Full-bleed image
                    AsyncImageView(urlString: article.imageURL)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()

                    // Gradient overlay
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.0),
                            Color.black.opacity(0.25),
                            Color.black.opacity(0.80)
                        ],
                        startPoint: UnitPoint(x: 0.5, y: 0.35),
                        endPoint: .bottom
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Text — lower third, leave right margin for buttons
                    VStack(alignment: .leading, spacing: 8) {
                        Text(article.source.uppercased())
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.white.opacity(0.7))
                            .tracking(0.8)

                        Text(article.title)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.white)
                            .lineLimit(3)
                            .shadow(color: Color.black.opacity(0.4), radius: 3, x: 0, y: 1)

                        Text(article.excerpt)
                            .font(.subheadline)
                            .foregroundStyle(Color.white.opacity(0.85))
                            .lineLimit(2)
                            .shadow(color: Color.black.opacity(0.4), radius: 3, x: 0, y: 1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.trailing, 76)   // leave room for action buttons
                    .padding(.bottom, 100)    // above tab bar
                }
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())

            // MARK: - Action buttons (higher z-order, don't trigger nav)
            VStack(spacing: 24) {
                FeedActionButton(
                    icon: isLiked ? "heart.fill" : "heart",
                    color: isLiked ? Color.red : Color.white
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        store.likeArticle(id: article.id)
                    }
                }

                // Bookmark — placeholder
                FeedActionButton(icon: "bookmark", color: Color.white) {
                    // TODO: bookmark
                }

                // Share — placeholder
                FeedActionButton(icon: "square.and.arrow.up", color: Color.white) {
                    // TODO: share sheet
                }
            }
            .padding(.trailing, 16)
            .padding(.bottom, 100)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Action button component
struct FeedActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(color)
                .shadow(color: Color.black.opacity(0.6), radius: 4, x: 0, y: 2)
                .frame(width: 44, height: 44)
        }
    }
}
