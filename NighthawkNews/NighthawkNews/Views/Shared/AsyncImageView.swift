import SwiftUI

struct AsyncImageView: View {
    let urlString: String?
    var category: String = ""
    var contentMode: ContentMode = .fill

    var body: some View {
        Group {
            if let urlString, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: contentMode)
                    default:
                        CategoryPlaceholder(category: category)
                    }
                }
            } else {
                CategoryPlaceholder(category: category)
            }
        }
    }
}

// MARK: - Category-branded placeholder

struct CategoryPlaceholder: View {
    let category: String

    private var config: (icon: String, colors: [Color]) {
        switch category {
        case "Tech":
            return ("cpu", [Color(red: 0.18, green: 0.44, blue: 0.96), Color(red: 0.09, green: 0.25, blue: 0.72)])
        case "Business":
            return ("chart.line.uptrend.xyaxis", [Color(red: 0.13, green: 0.65, blue: 0.45), Color(red: 0.06, green: 0.40, blue: 0.28)])
        case "Politics":
            return ("building.columns", [Color(red: 0.80, green: 0.25, blue: 0.25), Color(red: 0.55, green: 0.10, blue: 0.10)])
        case "Sports":
            return ("trophy", [Color(red: 0.95, green: 0.55, blue: 0.10), Color(red: 0.75, green: 0.35, blue: 0.00)])
        case "Science":
            return ("atom", [Color(red: 0.45, green: 0.20, blue: 0.90), Color(red: 0.28, green: 0.10, blue: 0.65)])
        case "Entertainment":
            return ("film", [Color(red: 0.90, green: 0.25, blue: 0.65), Color(red: 0.65, green: 0.10, blue: 0.45)])
        default:
            return ("newspaper", [Color(red: 0.35, green: 0.35, blue: 0.40), Color(red: 0.20, green: 0.20, blue: 0.25)])
        }
    }

    var body: some View {
        let (icon, colors) = config
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                    if !category.isEmpty {
                        Text(category.uppercased())
                            .font(.caption2.weight(.bold))
                            .tracking(1.2)
                            .foregroundStyle(.white.opacity(0.60))
                    }
                }
            }
    }
}
