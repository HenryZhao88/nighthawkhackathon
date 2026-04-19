import SwiftUI

struct FeedCardView: View {
    let article: Article
    let safeArea: EdgeInsets          // real measured insets from FeedView's GeometryReader
    @EnvironmentObject var store: ArticleStore

    /// Shows the heart animation overlay on double-tap.
    @State private var showLikeAnimation = false

    /// Where the user double-tapped, in the card's local coordinate space.
    /// Used to spawn the heart at the tap location.
    @State private var tapLocation: CGPoint = .zero

    /// Drives the pop-scale curve of the heart burst independently of visibility,
    /// so we can scale up, settle, and fade out cleanly.
    @State private var heartScale: CGFloat = 0.2
    @State private var heartOpacity: Double = 0
    @State private var heartRotation: Double = -12

    private var isLiked: Bool { store.likedIDs.contains(article.id) }
    private var isBookmarked: Bool { store.bookmarkedIDs.contains(article.id) }

    // Bottom clearance: tab bar (49) + home indicator / bottom inset + breathing room.
    // Breathing room was previously 20 — the bottom of the title was clipping behind
    // the tab bar on devices without a home indicator, so lift it well clear.
    private var bottomClearance: CGFloat { safeArea.bottom + 49 + 60 }

    // Inline image view — avoids the layout-cycle bug that AsyncImageView causes
    // when used with .fill inside an unconstrained ZStack.
    @ViewBuilder
    private var feedImage: some View {
        if let urlString = article.imageURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure, .empty:
                    feedPlaceholder
                @unknown default:
                    feedPlaceholder
                }
            }
        } else {
            feedPlaceholder
        }
    }

    private var feedPlaceholder: some View {
        CategoryPlaceholder(category: article.category)
    }

    var body: some View {
        ZStack(alignment: .bottom) {

            // MARK: - Full-bleed background + navigation tap target
            NavigationLink(value: article) {
                ZStack(alignment: .bottom) {
                    Color.clear
                        .overlay {
                            feedImage
                        }
                        .clipped()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.0),
                            Color.black.opacity(0.30),
                            Color.black.opacity(0.82)
                        ],
                        startPoint: UnitPoint(x: 0.5, y: 0.38),
                        endPoint: .bottom
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

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
                    .padding(.trailing, 76)
                    .padding(.bottom, bottomClearance)
                }
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            // Double-tap lives alongside the NavigationLink so it catches the
            // gesture without swallowing single taps (previously a Color.clear
            // overlay ate every tap, so single-tap navigation never fired).
            .highPriorityGesture(
                SpatialTapGesture(count: 2)
                    .onEnded { value in
                        handleDoubleTap(at: value.location)
                    }
            )

            // Heart animation overlay — positioned at the tap location.
            if showLikeAnimation {
                Image(systemName: "heart.fill")
                    .font(.system(size: 110, weight: .bold))
                    .foregroundStyle(.red)
                    .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 6)
                    .scaleEffect(heartScale)
                    .rotationEffect(.degrees(heartRotation))
                    .opacity(heartOpacity)
                    .position(tapLocation)
                    .allowsHitTesting(false)
            }

            // MARK: - Action buttons (sit on top — don't trigger navigation)
            VStack(spacing: 24) {
                FeedActionButton(
                    icon: isLiked ? "heart.fill" : "heart",
                    color: isLiked ? .red : .white
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        store.likeArticle(id: article.id)
                    }
                }

                FeedActionButton(
                    icon: isBookmarked ? "bookmark.fill" : "bookmark",
                    color: isBookmarked ? .yellow : .white
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        store.bookmarkArticle(id: article.id)
                    }
                }
            }
            .padding(.trailing, 16)
            .padding(.bottom, bottomClearance)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private func handleDoubleTap(at location: CGPoint) {
        tapLocation = location

        if !isLiked {
            store.likeArticle(id: article.id)
        }

        // Reset state, then drive a pop → settle → fade sequence.
        heartScale = 0.2
        heartOpacity = 0
        heartRotation = Double.random(in: -14 ... -6)
        showLikeAnimation = true

        // Pop up past target size for an overshoot feel.
        withAnimation(.spring(response: 0.28, dampingFraction: 0.55)) {
            heartScale = 1.25
            heartOpacity = 1.0
            heartRotation = 0
        }

        // Settle back to natural size.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            withAnimation(.easeOut(duration: 0.18)) {
                heartScale = 1.0
            }
        }

        // Float up slightly and fade out.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.easeIn(duration: 0.35)) {
                heartOpacity = 0
                heartScale = 1.4
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            showLikeAnimation = false
        }
    }
}

// MARK: - Action button
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
