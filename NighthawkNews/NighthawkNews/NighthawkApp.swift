import SwiftUI

@main
struct NighthawkApp: App {
    @StateObject private var store = ArticleStore()
    @AppStorage("theme") private var theme: String = "System"

    var colorScheme: ColorScheme? {
        switch theme {
        case "Light": return .light
        case "Dark": return .dark
        default: return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(store)
                .preferredColorScheme(colorScheme)
        }
    }
}
