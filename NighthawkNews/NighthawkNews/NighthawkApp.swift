import SwiftUI
import GoogleSignIn

@main
struct NighthawkApp: App {
    @StateObject private var store = ArticleStore()
    @StateObject private var auth = AuthStore()
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
            Group {
                if auth.isAuthenticated {
                    MainTabView()
                        .environmentObject(store)
                } else {
                    SignInView()
                        .environmentObject(auth)
                }
            }
            .environmentObject(auth)
            .preferredColorScheme(colorScheme)
            .animation(.easeInOut(duration: 0.3), value: auth.isAuthenticated)
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
}
