import Foundation
import GoogleSignIn

class AuthStore: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentEmail: String = ""

    // Hardcoded account "database" — swap for real backend later
    private let accounts: [String: String] = [
        "admin@henry.com": "admin"
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
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !password.isEmpty else { throw SignInError.emptyFields }
        guard let stored = accounts[trimmed.lowercased()], stored == password else {
            throw SignInError.invalidCredentials
        }
        isAuthenticated = true
        currentEmail = trimmed
    }

    // MARK: - Google OAuth
    @MainActor
    func signInWithGoogle(presenting viewController: UIViewController) async throws {
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
        let email = result.user.profile?.email ?? result.user.userID ?? "Google User"
        isAuthenticated = true
        currentEmail = email
    }

    // MARK: - Sign Out
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        isAuthenticated = false
        currentEmail = ""
    }
}
