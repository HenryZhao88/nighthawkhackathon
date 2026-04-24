import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: ArticleStore
    @State private var selectedCategory = "All"

    private let categories = ["All", "Tech", "Business", "Politics", "Sports", "Science", "Entertainment"]

    var body: some View {
        VStack(spacing: 0) {
            CategoryFilterBar(selected: $selectedCategory, categories: categories)
            ArticleListView(articles: store.articles(in: selectedCategory))
        }
        .padding(.top, -10)
        .navigationTitle("NighthawkNews")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}
