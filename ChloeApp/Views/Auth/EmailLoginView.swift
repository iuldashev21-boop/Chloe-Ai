import SwiftUI
import AuthenticationServices
import Combine
import CryptoKit

struct EmailLoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var shimmerOffset: CGFloat = -200
    @State private var shimmerTimer: Timer?
    @FocusState private var focusedField: Field?
    @State private var showOrb = false
    @State private var showText = false
    @State private var showFields = false
    @State private var keyboardVisible = false
    @State private var showPasswordReset = false
    @State private var currentNonce: String?

    enum Field: Hashable { case email, password }

    // MARK: - Validation Helpers

    private var isEmailFormatValid: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let atIndex = trimmed.firstIndex(of: "@") else { return false }
        let afterAt = trimmed[trimmed.index(after: atIndex)...]
        return afterAt.contains(".")
    }

    /// Show email hint only after user has typed enough to warrant feedback
    private var showEmailHint: Bool {
        !email.isBlank && !isEmailFormatValid
    }

    private var isPasswordLongEnough: Bool {
        password.count >= 6
    }

    private var canSubmit: Bool {
        if authVM.isSignUpMode {
            return !email.isBlank && isPasswordLongEnough
        } else {
            return !email.isBlank && !password.isEmpty
        }
    }

    var body: some View {
        ZStack {
            GradientBackground()
            EtherealDustParticles()
                .ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                Spacer()

                // MARK: - Crystalline Spark
                LuminousOrb(size: 80, isFieldFocused: focusedField != nil)
                .opacity(showOrb ? 1 : 0)
                .scaleEffect(keyboardVisible ? 0.7 : (showOrb ? 1 : 0.8))
                .offset(x: keyboardVisible ? 120 : 0, y: keyboardVisible ? -60 : 0)
                .animation(Spacing.chloeSpring, value: keyboardVisible)
                .animation(Spacing.chloeSpring, value: showOrb)
                .accessibilityHidden(true)

                // MARK: - Header
                VStack(spacing: Spacing.xs) {
                    Text("Welcome home")
                        .font(.custom(ChloeFont.heroBoldItalic, size: 40))
                        .tracking(1)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "#2D2324"), Color(hex: "#8E5A5E")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text(authVM.isSignUpMode ? "CREATE YOUR SANCTUARY" : "ENTER YOUR SANCTUARY")
                        .font(.custom(ChloeFont.headerDisplay, size: 13))
                        .tracking(3)
                        .foregroundColor(.chloeRosewood)
                }
                .opacity(showText ? 1 : 0)
                .offset(y: showText ? 0 : 10)
                .animation(Spacing.chloeSpring, value: showText)

                // MARK: - Fields & Buttons Group
                Group {
                    // MARK: - Email field
                    TextField("Email", text: $email, prompt: Text("Email").font(.system(size: 17, weight: .light).italic()).foregroundColor(.chloeRosewood))
                        .font(.chloeBodyDefault)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                        .focused($focusedField, equals: .email)
                        .padding(.horizontal, Spacing.xs)
                        .frame(height: 48)
                        .background(Color.clear)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(Color(hex: "#B76E79").opacity(focusedField == .email ? 0.9 : 0.4))
                                .frame(height: focusedField == .email ? 1 : 0.5)
                                .shadow(color: Color(hex: "#B76E79").opacity(focusedField == .email ? 0.5 : 0), radius: 4)
                                .animation(.easeInOut(duration: 0.3), value: focusedField)
                        }
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .accessibilityLabel("Email address")
                        .accessibilityIdentifier("email-field")

                    // Email format hint
                    if showEmailHint {
                        Text("Enter a valid email address")
                            .font(.chloeCaption)
                            .foregroundColor(.chloeRosewood.opacity(0.8))
                            .padding(.horizontal, Spacing.screenHorizontal)
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.2), value: showEmailHint)
                    }

                    // MARK: - Password field
                    SecureField("Password", text: $password, prompt: Text("Password").font(.system(size: 17, weight: .light).italic()).foregroundColor(.chloeRosewood))
                        .font(.chloeBodyDefault)
                        .textContentType(authVM.isSignUpMode ? .newPassword : .password)
                        .submitLabel(.go)
                        .focused($focusedField, equals: .password)
                        .padding(.horizontal, Spacing.xs)
                        .frame(height: 48)
                        .background(Color.clear)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(Color(hex: "#B76E79").opacity(focusedField == .password ? 0.9 : 0.4))
                                .frame(height: focusedField == .password ? 1 : 0.5)
                                .shadow(color: Color(hex: "#B76E79").opacity(focusedField == .password ? 0.5 : 0), radius: 4)
                                .animation(.easeInOut(duration: 0.3), value: focusedField)
                        }
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .accessibilityLabel("Password")
                        .accessibilityIdentifier("password-field")

                    // Password requirements (signup mode only)
                    if authVM.isSignUpMode && !password.isEmpty {
                        HStack(spacing: Spacing.xxxs) {
                            Image(systemName: isPasswordLongEnough ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 12))
                                .foregroundColor(isPasswordLongEnough ? Color(hex: "#4A7C59") : .chloeTextTertiary)

                            Text("At least 6 characters")
                                .font(.chloeCaption)
                                .foregroundColor(isPasswordLongEnough ? Color(hex: "#4A7C59") : .chloeTextTertiary)
                        }
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: isPasswordLongEnough)
                    }

                    // MARK: - Error message
                    if let errorMessage = authVM.errorMessage {
                        Text(errorMessage)
                            .font(.chloeCaption)
                            .foregroundColor(.red.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.screenHorizontal)
                            .transition(.opacity)
                            .accessibilityAddTraits(.isStaticText)
                            .accessibilityLabel("Error: \(errorMessage)")
                    }

                    // MARK: - Sign In / Sign Up button
                    Button {
                        focusedField = nil
                        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                        Task {
                            if authVM.isSignUpMode {
                                await authVM.signUp(email: trimmedEmail, password: password)
                            } else {
                                await authVM.signIn(email: trimmedEmail, password: password)
                            }
                        }
                    } label: {
                        ZStack {
                            // Button text — hidden during loading
                            Text(authVM.isSignUpMode ? "CREATE ACCOUNT" : "SIGN IN")
                                .font(.chloeButton)
                                .tracking(3)
                                .foregroundColor(.white)
                                .opacity(authVM.isLoading ? 0 : 1)

                            // Loading spinner — shown during auth
                            if authVM.isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.9)
                                    .transition(.opacity)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                            .background(
                                ZStack {
                                    Capsule().fill(.ultraThinMaterial)
                                    Capsule().fill(Color.chloePrimary.opacity(canSubmit ? 0.8 : 0.4))
                                    LinearGradient(
                                        colors: [.clear, .white.opacity(0.25), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .offset(x: shimmerOffset)
                                    .opacity(authVM.isLoading ? 0 : 1)
                                    .mask(Capsule())
                                    // Inner glow — top edge catch light
                                    VStack {
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [.white.opacity(0.35), .clear],
                                                    startPoint: .top,
                                                    endPoint: .center
                                                )
                                            )
                                            .frame(height: 1)
                                            .padding(.horizontal, 1)
                                        Spacer()
                                    }
                                    .clipShape(Capsule())
                                }
                            )
                            .clipShape(Capsule())
                            .shadow(color: Color(hex: "#B76E79").opacity(0.2), radius: 15, y: 8)
                    }
                    .disabled(!canSubmit || authVM.isLoading)
                    .buttonStyle(PressableButtonStyle())
                    .sensoryFeedback(.impact(weight: .medium), trigger: authVM.isLoading)
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .onAppear { startShimmerLoop() }

                    // MARK: - Sign Up / Sign In toggle + Forgot Password
                    HStack(spacing: Spacing.md) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                authVM.isSignUpMode.toggle()
                                authVM.errorMessage = nil
                                authVM.successMessage = nil
                            }
                        } label: {
                            if authVM.isSignUpMode {
                                (Text("Already have an account? ")
                                    .font(.chloeCaption)
                                    .foregroundColor(.chloeTextSecondary)
                                + Text("Sign In")
                                    .font(.chloeCaption)
                                    .foregroundColor(.chloePrimary))
                            } else {
                                (Text("Don't have an account? ")
                                    .font(.chloeCaption)
                                    .foregroundColor(.chloeTextSecondary)
                                + Text("Sign Up")
                                    .font(.chloeCaption)
                                    .foregroundColor(.chloePrimary))
                            }
                        }

                        // Show forgot password only in sign-in mode
                        if !authVM.isSignUpMode {
                            Text("·")
                                .font(.chloeCaption)
                                .foregroundColor(.chloeTextTertiary)

                            Button {
                                showPasswordReset = true
                            } label: {
                                Text("Forgot password?")
                                    .font(.chloeCaption)
                                    .foregroundColor(.chloePrimary)
                            }
                        }
                    }

                    // MARK: - "or" divider
                    HStack(spacing: Spacing.xs) {
                        Rectangle()
                            .fill(Color.chloeRosewood.opacity(0.3))
                            .frame(height: 0.5)
                        Text("or")
                            .font(.chloeCaptionLight)
                            .foregroundColor(.chloeRosewood)
                        Rectangle()
                            .fill(Color.chloeRosewood.opacity(0.3))
                            .frame(height: 0.5)
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .accessibilityHidden(true)

                    // MARK: - Sign in with Apple
                    SignInWithAppleButton(.signIn) { request in
                        let nonce = randomNonceString()
                        currentNonce = nonce
                        request.requestedScopes = [.email, .fullName]
                        request.nonce = sha256(nonce)
                    } onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                                  let identityToken = appleIDCredential.identityToken,
                                  let idTokenString = String(data: identityToken, encoding: .utf8),
                                  let nonce = currentNonce else {
                                authVM.errorMessage = "Apple sign-in failed. Please try again."
                                return
                            }
                            let fullName = appleIDCredential.fullName
                            Task {
                                await authVM.signInWithApple(
                                    idToken: idTokenString,
                                    nonce: nonce,
                                    fullName: fullName
                                )
                            }
                        case .failure(let error):
                            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                                authVM.errorMessage = "Apple sign-in failed. Please try again."
                            }
                        }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .cornerRadius(28)
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .disabled(authVM.isLoading)

                    // MARK: - Skip (Dev)
                    #if DEBUG
                    Button {
                        Task { await authVM.devSignIn() }
                        // Also mark onboarding complete for skip flow
                        var profile = SyncDataService.shared.loadProfile() ?? Profile()
                        profile.onboardingComplete = true
                        profile.updatedAt = Date()
                        try? SyncDataService.shared.saveProfile(profile)
                        AppEvents.onboardingDidComplete.send()
                    } label: {
                        Text("Skip (Dev)")
                            .font(.chloeCaptionLight)
                            .foregroundColor(.chloePrimary)
                    }
                    #endif

                    DisclaimerText()
                }
                .opacity(showFields ? 1 : 0)
                .offset(y: showFields ? 0 : 20)
                .animation(Spacing.chloeSpring, value: showFields)

                Spacer()
                    .frame(height: Spacing.lg)
            }
            .sensoryFeedback(.selection, trigger: focusedField)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $authVM.showEmailConfirmation) {
            EmailConfirmationView(
                email: authVM.pendingConfirmationEmail,
                onResend: {
                    await authVM.resendConfirmationEmail()
                },
                onChangeEmail: {
                    authVM.cancelEmailConfirmation()
                }
            )
        }
        .navigationDestination(isPresented: $showPasswordReset) {
            PasswordResetView()
        }
        .background {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { focusedField = nil }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                withAnimation { showOrb = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation { showText = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation { showFields = true }
            }
        }
        .onDisappear {
            stopShimmerLoop()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            keyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardVisible = false
        }
    }

    private func startShimmerLoop() {
        shimmerTimer?.invalidate()
        shimmerTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            shimmerOffset = -200
            withAnimation(.easeInOut(duration: 0.8)) {
                shimmerOffset = 200
            }
        }
    }

    private func stopShimmerLoop() {
        shimmerTimer?.invalidate()
        shimmerTimer = nil
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            // Fallback: use UUID-based randomness instead of crashing
            let uuid1 = UUID().uuidString.replacingOccurrences(of: "-", with: "")
            let uuid2 = UUID().uuidString.replacingOccurrences(of: "-", with: "")
            return String((uuid1 + uuid2).prefix(length))
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

}

#Preview {
    NavigationStack {
        EmailLoginView()
            .environmentObject(AuthViewModel())
    }
}
