import SwiftUI

struct SettingsView: View {
    @AppStorage("theme") private var theme: String = "System"
    @EnvironmentObject var auth: AuthStore
    @State private var confirmSignOut = false

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
                NavigationLink("Bookmarks") {
                    BookmarkedArticlesView()
                }
                NavigationLink("Previously Viewed") {
                    ViewedArticlesView()
                }
            }

            // MARK: Account
            Section("Account") {
                LabeledContent("Signed in as") {
                    Text(auth.currentEmail)
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }

                Button(role: .destructive) {
                    confirmSignOut = true
                } label: {
                    Text("Sign Out")
                }
                .confirmationDialog("Sign out of NighthawkNews?", isPresented: $confirmSignOut, titleVisibility: .visible) {
                    Button("Sign Out", role: .destructive) {
                        auth.signOut()
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }
        }
        .padding(.top, -10)
        .navigationTitle("Settings")
    }
}
