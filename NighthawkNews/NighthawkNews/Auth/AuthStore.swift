import Foundation
import Security
import AuthenticationServices
import GoogleSignIn

class AuthStore: NSObject, ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentEmail: String = ""

    // Hardcoded account "database" — swap for real backend later
    private let accounts: [String: String] = [
        "admin": "admin"
    ]

    fileprivate enum SignInMethod: String {
        case password
        case google
        case apple
    }

    enum SignInError: LocalizedError {
        case invalidCredentials
        case emptyFields
        case googleFailed(String)
        case appleFailed(String)

        var errorDescription: String? {
            switch self {
            case .invalidCredentials:     return "Incorrect email or password."
            case .emptyFields:            return "Please enter your email and password."
            case .googleFailed(let msg):  return msg
            case .appleFailed(let msg):   return msg
            }
        }
    }

    // MARK: - Apple sign-in continuation
    private var appleContinuation: CheckedContinuation<Void, Error>?

    override init() {
        super.init()
        restoreSession()
    }

    // MARK: - Session restore

    /// Rehydrate login state from the keychain on launch. For Google sessions,
    /// also ask GIDSignIn to restore its cached tokens. For Apple sessions,
    /// verify the credential is still authorized; otherwise drop to signed-out.
    private func restoreSession() {
        guard let session = KeychainSession.load() else { return }
        isAuthenticated = true
        currentEmail = session.email
        UserDefaults.standard.set(session.userID, forKey: "NIGHTHAWK_USER_ID")

        switch session.method {
        case .google:
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
        case .apple:
            ASAuthorizationAppleIDProvider().getCredentialState(forUserID: session.userID) { [weak self] state, _ in
                guard let self else { return }
                if state == .revoked || state == .notFound {
                    DispatchQueue.main.async { self.signOut() }
                }
            }
        case .password:
            break
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
        UserDefaults.standard.set(normalized, forKey: "NIGHTHAWK_USER_ID")
        KeychainSession.save(.init(userID: normalized, email: normalized, method: .password))
    }

    // MARK: - Google OAuth
    @MainActor
    func signInWithGoogle(presenting viewController: UIViewController) async throws {
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
            let email = result.user.profile?.email ?? result.user.userID ?? "Google User"
            isAuthenticated = true
            currentEmail = email
            UserDefaults.standard.set(email, forKey: "NIGHTHAWK_USER_ID")
            KeychainSession.save(.init(userID: email, email: email, method: .google))
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

    // MARK: - Sign in with Apple
    @MainActor
    func signInWithApple() async throws {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            self.appleContinuation = cont
            controller.performRequests()
        }
    }

    // MARK: - Sign Out
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        isAuthenticated = false
        currentEmail = ""
        UserDefaults.standard.removeObject(forKey: "NIGHTHAWK_USER_ID")
        KeychainSession.delete()
    }

    /// Permanently delete the local session and any cached identity. Used by
    /// the in-app account deletion flow after the server has wiped the user's
    /// data. Behaves like signOut() but is named distinctly for clarity at the
    /// call site.
    func deleteLocalAccount() {
        signOut()
    }
}

// MARK: - Apple delegate / presentation

extension AuthStore: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            appleContinuation?.resume(throwing: SignInError.appleFailed("Unexpected credential type."))
            appleContinuation = nil
            return
        }

        // Apple only returns name/email on first authorization. Cache whatever
        // we got; on subsequent sign-ins the email field will be nil and we
        // fall back to whatever was previously stored (or the user identifier).
        let userID = credential.user
        let displayEmail: String = {
            if let email = credential.email, !email.isEmpty { return email }
            if let cached = KeychainSession.load(), cached.userID == userID, !cached.email.isEmpty {
                return cached.email
            }
            return "Apple User"
        }()

        DispatchQueue.main.async {
            self.isAuthenticated = true
            self.currentEmail = displayEmail
            UserDefaults.standard.set(userID, forKey: "NIGHTHAWK_USER_ID")
            KeychainSession.save(.init(userID: userID, email: displayEmail, method: .apple))
            self.appleContinuation?.resume()
            self.appleContinuation = nil
        }
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        let nsError = error as NSError
        // User canceled — treat as silent no-op so the UI doesn't show an error.
        if nsError.code == ASAuthorizationError.canceled.rawValue {
            appleContinuation?.resume()
            appleContinuation = nil
            return
        }
        appleContinuation?.resume(throwing: SignInError.appleFailed(error.localizedDescription))
        appleContinuation = nil
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first {
            return window
        }
        return ASPresentationAnchor()
    }
}

// MARK: - Keychain-backed session record

private struct KeychainSession {
    let userID: String       // Stable identifier sent to the backend (email for password/google, Apple `user` for apple)
    let email: String        // Display email shown in Settings
    let method: AuthStore.SignInMethod

    private static let service = "com.nighthawknews.NighthawkNews.auth"
    private static let account = "session"
    private static let separator: Character = "|"

    static func save(_ session: KeychainSession) {
        let payload = "\(session.method.rawValue)\(separator)\(session.userID)\(separator)\(session.email)"
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

        let parts = raw.split(separator: separator, maxSplits: 2, omittingEmptySubsequences: false).map(String.init)
        // Back-compat: older sessions stored "method|email" (2 parts).
        if parts.count == 2,
           let method = AuthStore.SignInMethod(rawValue: parts[0]),
           !parts[1].isEmpty {
            return KeychainSession(userID: parts[1], email: parts[1], method: method)
        }
        guard parts.count == 3,
              let method = AuthStore.SignInMethod(rawValue: parts[0]),
              !parts[1].isEmpty else {
            return nil
        }
        return KeychainSession(userID: parts[1], email: parts[2], method: method)
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
