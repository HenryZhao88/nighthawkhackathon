import Foundation
import Security
import GoogleSignIn

class AuthStore: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentEmail: String = ""

    // Hardcoded account "database" — swap for real backend later
    private let accounts: [String: String] = [
        "admin": "admin"
    ]

    fileprivate enum SignInMethod: String {
        case password
        case google
    }

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

    init() {
        restoreSession()
    }

    // MARK: - Session restore

    /// Rehydrate login state from the keychain on launch. For Google sessions,
    /// also ask GIDSignIn to restore its cached tokens; if that fails we drop
    /// back to signed-out so we don't show a stale identity.
    private func restoreSession() {
        guard let session = KeychainSession.load() else { return }
        isAuthenticated = true
        currentEmail = session.email
        UserDefaults.standard.set(session.email, forKey: "NEWSHAWK_USER_ID")

        if session.method == .google {
            Task { @MainActor in
                await withCheckedContinuation { continuation in
                    GIDSignIn.sharedInstance.restorePreviousSignIn { _, error in
                        if error != nil {
                            self.signOut()
                        }
                        continuation.resume()
                    }
                }
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
        KeychainSession.save(.init(email: normalized, method: .password))
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
            KeychainSession.save(.init(email: email, method: .google))
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
        KeychainSession.delete()
    }
}

// MARK: - Keychain-backed session record

private struct KeychainSession {
    let email: String
    let method: AuthStore.SignInMethod

    private static let service = "com.newshawk.NewsHawkNews.auth"
    private static let account = "session"
    private static let separator: Character = "|"

    static func save(_ session: KeychainSession) {
        let payload = "\(session.method.rawValue)\(separator)\(session.email)"
        let data = Data(payload.utf8)

        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)

        var attrs = query
        attrs[kSecValueData as String] = data
        attrs[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let status = SecItemAdd(attrs as CFDictionary, nil)
        if status != errSecSuccess {
            print("[AuthStore] keychain save failed: \(status)")
        }
    }

    static func load() -> KeychainSession? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let raw = String(data: data, encoding: .utf8) else {
            return nil
        }

        let parts = raw.split(separator: separator, maxSplits: 1).map(String.init)
        guard parts.count == 2,
              let method = AuthStore.SignInMethod(rawValue: parts[0]),
              !parts[1].isEmpty else {
            return nil
        }
        return KeychainSession(email: parts[1], method: method)
    }

    static func delete() {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
