import SwiftUI

struct SearchView: View {
    @EnvironmentObject var store: ArticleStore
    @StateObject private var history = SearchHistoryStore()
    @State private var query: String = ""

    var body: some View {
        NavigationStack {
            SearchContent(history: history, query: $query)
                .navigationTitle("Search")
                .navigationBarTitleDisplayMode(.large)
                .background(Color(uiColor: .systemGroupedBackground))
                .searchable(
                    text: $query,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Search articles, sources, topics"
                )
                .onSubmit(of: .search) {
                    history.record(query)
                }
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .navigationDestination(for: Article.self) { article in
                    ArticleDetailView(article: article)
                }
        }
    }
}

// MARK: - Content (lives inside .searchable so it can read \.isSearching)

private struct SearchContent: View {
    @EnvironmentObject var store: ArticleStore
    @ObservedObject var history: SearchHistoryStore
    @Binding var query: String
    @Environment(\.isSearching) private var isSearching

    private var trimmed: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Group {
            if !trimmed.isEmpty {
                let results = RecommendationService.matches(for: trimmed, in: store.articles)
                if results.isEmpty {
                    Placeholder(
                        icon: "questionmark.circle",
                        title: "No matches",
                        message: "Nothing in the cached feed matches \"\(query)\"."
                    )
                } else {
                    ArticleListView(articles: results)
                }
            } else {
                LandingView(
                    history: history,
                    query: $query,
                    showHistory: isSearching
                )
            }
        }
    }
}

// MARK: - Landing (empty query) view

private struct LandingView: View {
    @EnvironmentObject var store: ArticleStore
    @ObservedObject var history: SearchHistoryStore
    @Binding var query: String
    let showHistory: Bool

    private var recommendation: RecommendationService.Result {
        RecommendationService.recommend(
            from: store.articles,
            signals: .init(
                searchHistory: history.queries,
                likedIDs: store.likedIDs,
                viewedIDs: store.viewedIDs
            )
        )
    }

    var body: some View {
        let rec = recommendation
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if showHistory && !history.queries.isEmpty {
                    recentSection
                }
                if !rec.articles.isEmpty {
                    recommendedSection(rec)
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SectionHeader("Recent")
                Spacer()
                Button("Clear") { history.clear() }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)

            VStack(spacing: 0) {
                ForEach(Array(history.queries.enumerated()), id: \.element) { index, q in
                    Button {
                        query = q
                        history.record(q)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundStyle(.secondary)
                            Text(q)
                                .foregroundStyle(.primary)
                            Spacer()
                            Button {
                                history.remove(q)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .padding(6)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if index < history.queries.count - 1 {
                        Divider().padding(.leading, 44)
                    }
                }
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 16)
        }
    }

    private func recommendedSection(_ rec: RecommendationService.Result) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("Recommended for you")
                .padding(.horizontal, 16)
            Text(subtitle(for: rec.source))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)

            LazyVStack(spacing: 12) {
                ForEach(rec.articles) { article in
                    NavigationLink(value: article) {
                        ArticleCard(article: article)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
        }
    }

    private func subtitle(for source: RecommendationService.Source) -> String {
        switch source {
        case .searchHistory: return "Based on your recent searches"
        case .likes:         return "Based on articles you've liked"
        case .recent:        return "Latest from the newsroom"
        }
    }
}

// MARK: - Small reusable bits

private struct SectionHeader: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text).font(.title3.weight(.semibold))
    }
}

private struct Placeholder: View {
    let icon: String
    let title: String
    let message: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.secondary)
            Text(title).font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}
