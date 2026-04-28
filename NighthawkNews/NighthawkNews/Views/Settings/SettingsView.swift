import SwiftUI

struct SettingsView: View {
    @AppStorage("theme") private var theme: String = "System"
    @EnvironmentObject var auth: AuthStore
    @EnvironmentObject var store: ArticleStore
    @State private var confirmSignOut = false
    @State private var confirmDelete = false
    @State private var deleteError: String? = nil
    @State private var isDeleting = false

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

            // MARK: Delete Account (App Store guideline 5.1.1(v))
            Section {
                Button(role: .destructive) {
                    confirmDelete = true
                } label: {
                    if isDeleting {
                        HStack {
                            ProgressView()
                            Text("Deleting…")
                        }
                    } else {
                        Text("Delete Account")
                    }
                }
                .disabled(isDeleting)
            } footer: {
                Text("Permanently deletes your account and removes all of your liked articles, bookmarks, view history, and personalization data from our servers. This cannot be undone.")
            }
            .confirmationDialog(
                "Delete your account?",
                isPresented: $confirmDelete,
                titleVisibility: .visible
            ) {
                Button("Delete Account", role: .destructive) {
                    Task { await performDelete() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes your account and all associated data. This action cannot be undone.")
            }
            .alert(
                "Couldn't delete account",
                isPresented: Binding(
                    get: { deleteError != nil },
                    set: { if !$0 { deleteError = nil } }
                )
            ) {
                Button("OK", role: .cancel) { deleteError = nil }
            } message: {
                Text(deleteError ?? "")
            }
        }
        .padding(.top, -10)
        .navigationTitle("Settings")
    }

    @MainActor
    private func performDelete() async {
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await store.deleteAccount()
            auth.deleteLocalAccount()
        } catch {
            deleteError = "We couldn't reach the server to delete your account. Please check your connection and try again."
        }
    }
}
