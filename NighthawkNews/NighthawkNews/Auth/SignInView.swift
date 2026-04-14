import SwiftUI

struct SignInView: View {
    @EnvironmentObject var auth: AuthStore

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false
    @State private var shake: Bool = false
    @State private var showGoogleStub: Bool = false

    var body: some View {
        ZStack {
            // Background
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // MARK: - Header
                    VStack(spacing: 12) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(Color.accentColor)
                            .padding(.top, 72)

                        Text("Nighthawk")
                            .font(.system(size: 36, weight: .black, design: .default))
                            .foregroundStyle(Color.primary)

                        Text("News that actually grabs you.")
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                    }
                    .padding(.bottom, 48)

                    // MARK: - Card
                    VStack(spacing: 20) {
                        // Email field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.secondary)
                                .padding(.leading, 4)

                            HStack(spacing: 10) {
                                Image(systemName: "envelope")
                                    .foregroundStyle(Color.secondary)
                                    .frame(width: 18)
                                TextField("you@example.com", text: $email)
                                    .keyboardType(.emailAddress)
                                    .textContentType(.emailAddress)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 13)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                        }

                        // Password field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.secondary)
                                .padding(.leading, 4)

                            HStack(spacing: 10) {
                                Image(systemName: "lock")
                                    .foregroundStyle(Color.secondary)
                                    .frame(width: 18)

                                if showPassword {
                                    TextField("Password", text: $password)
                                        .textContentType(.password)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                } else {
                                    SecureField("Password", text: $password)
                                        .textContentType(.password)
                                }

                                Button {
                                    showPassword.toggle()
                                } label: {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundStyle(Color.secondary)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 13)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                        }

                        // Error message
                        if !errorMessage.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill")
                                Text(errorMessage)
                                    .font(.subheadline)
                            }
                            .foregroundStyle(Color.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 4)
                            .offset(x: shake ? -6 : 0)
                            .animation(
                                shake
                                    ? .spring(response: 0.12, dampingFraction: 0.3).repeatCount(4, autoreverses: true)
                                    : .default,
                                value: shake
                            )
                        }

                        // Sign In button
                        Button {
                            attemptSignIn()
                        } label: {
                            ZStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Sign In")
                                        .font(.headline)
                                        .foregroundStyle(Color.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(isLoading)

                        // Divider
                        HStack(spacing: 12) {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.25))
                                .frame(height: 1)
                            Text("or")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                            Rectangle()
                                .fill(Color.secondary.opacity(0.25))
                                .frame(height: 1)
                        }
                        .padding(.vertical, 4)

                        // Google Sign In
                        Button {
                            showGoogleStub = true
                        } label: {
                            HStack(spacing: 10) {
                                // Google "G" logo in brand colors
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 24, height: 24)
                                    Text("G")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(Color(red: 0.25, green: 0.52, blue: 0.96))
                                }

                                Text("Continue with Google")
                                    .font(.headline)
                                    .foregroundStyle(Color.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                            )
                        }
                        .alert("Google Sign In", isPresented: $showGoogleStub) {
                            Button("OK", role: .cancel) {}
                        } message: {
                            Text("Google authentication isn't wired up yet. Use email/password for now.")
                        }
                    }
                    .padding(24)
                    .background(Color(uiColor: .systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 4)
                    .padding(.horizontal, 20)

                    Spacer(minLength: 40)
                }
            }
        }
        .onSubmit {
            attemptSignIn()
        }
    }

    private func attemptSignIn() {
        guard !isLoading else { return }
        errorMessage = ""
        isLoading = true

        // Small artificial delay for UX realism
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            do {
                try auth.signIn(email: email, password: password)
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
                shake = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    shake = false
                }
            }
            isLoading = false
        }
    }
}
