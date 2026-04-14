import SwiftUI

struct SettingsView: View {
    @AppStorage("theme") private var theme: String = "System"

    var body: some View {
        Form {
            // MARK: Appearance
            Section("Appearance") {
                Picker("Theme", selection: $theme) {
                    Text("System").tag("System")
                    Text("Light").tag("Light")
                    Text("Dark").tag("Dark")
                }
                .pickerStyle(.menu)
            }

            // MARK: Activity
            Section("Activity") {
                NavigationLink("Liked Articles") {
                    LikedArticlesView()
                }
                NavigationLink("Previously Viewed") {
                    ViewedArticlesView()
                }
            }

            // MARK: Account
            Section("Account") {
                Button(role: .destructive) {
                    // TODO: sign out
                } label: {
                    Text("Sign Out")
                }
            }
        }
        .navigationTitle("Settings")
    }
}
