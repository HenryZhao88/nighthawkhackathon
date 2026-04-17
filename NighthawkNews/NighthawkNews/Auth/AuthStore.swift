import Foundation
import GoogleSignIn

class AuthStore: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentEmail: String = ""

    // Hardcoded account "database" — swap for real backend later
    private let accounts: [String: String] = [
        "admin": "admin"
    ]

    enum SignInError: LocalizedError {
        case invalidCredentials
        case emptyFields
        case googleFailed(String)

        var errorDescription: String? {
            switch self {
            case .invalidCredentials:     return "Incorrect email or password."
            case .emptyFields:            return "Please enter your email and password."
            case .googleFailed(let msg):  return msg
            }
        }
    }

    // MARK: - Email / Password
    func signIn(email: String, password: String) throws {
        let normalized = email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !normalized.isEmpty, !password.isEmpty else { throw SignInError.emptyFields }
        guard let stored = accounts[normalized], stored == password else {
            throw SignInError.invalidCredentials
        }
        isAuthenticated = true
        currentEmail = normalized
        UserDefaults.standard.set(normalized, forKey: "NEWSHAWK_USER_ID")
    }

    // MARK: - Google OAuth
    @MainActor
    func signInWithGoogle(presenting viewController: UIViewController) async throws {
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
            let email = result.user.profile?.email ?? result.user.userID ?? "Google User"
            isAuthenticated = true
            currentEmail = email
            UserDefaults.standard.set(email, forKey: "NEWSHAWK_USER_ID")
        } catch let error as NSError {
            // Keychain error (-34018) means the app isn't signed with a team yet.
            // Fix: open project in Xcode → Signing & Capabilities → set your Team.
            if error.code == -34018 || error.domain.contains("keychain") ||
               error.localizedDescription.lowercased().contains("keychain") {
                throw SignInError.googleFailed(
                    "Keychain access failed. Open the project in Xcode, go to Signing & Capabilities, and set your Team to your Apple ID."
                )
            }
            // GIDSignIn cancellation — user dismissed the sheet
            if error.code == -5 { return }
            throw SignInError.googleFailed(error.localizedDescription)
        }
    }

    // MARK: - Sign Out
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        isAuthenticated = false
        currentEmail = ""
        UserDefaults.standard.removeObject(forKey: "NEWSHAWK_USER_ID")
    }
}
