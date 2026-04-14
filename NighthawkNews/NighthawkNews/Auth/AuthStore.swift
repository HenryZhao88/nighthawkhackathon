import Foundation

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

        var errorDescription: String? {
            switch self {
            case .invalidCredentials: return "Incorrect email or password."
            case .emptyFields:        return "Please enter your email and password."
            }
        }
    }

    func signIn(email: String, password: String) throws {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !password.isEmpty else { throw SignInError.emptyFields }
        guard let stored = accounts[trimmed.lowercased()], stored == password else {
            throw SignInError.invalidCredentials
        }
        isAuthenticated = true
        currentEmail = trimmed
    }

    func signOut() {
        isAuthenticated = false
        currentEmail = ""
    }
}
