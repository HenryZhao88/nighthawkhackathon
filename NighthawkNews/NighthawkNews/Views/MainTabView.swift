import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 1

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(0)

            FeedView()
                .tabItem {
                    Label("Feed", systemImage: "square.stack")
                }
                .tag(1)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(2)
        }
        .gesture(
            DragGesture(minimumDistance: 40)
                .onEnded { value in
                    let horizontal = value.translation.width
                    let vertical = value.translation.height
                    // Only register horizontal swipes (not vertical scrolls)
                    guard abs(horizontal) > abs(vertical) else { return }
                    withAnimation {
                        if horizontal < 0 {
                            selectedTab = min(selectedTab + 1, 2)
                        } else {
                            selectedTab = max(selectedTab - 1, 0)
                        }
                    }
                }
        )
    }
}
