import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var store: ArticleStore
    @State private var selectedTab = 1

    var body: some View {
        ZStack(alignment: .bottom) {
            PageViewController(
                pages: [
                    AnyView(NavigationStack { HomeView() }.environmentObject(store)),
                    AnyView(FeedView().environmentObject(store)),
                    AnyView(SearchView().environmentObject(store)),
                    AnyView(NavigationStack { SettingsView() }.environmentObject(store)),
                ],
                currentIndex: $selectedTab
            )
            .ignoresSafeArea()

            GlassTabBar(selected: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}
