import SwiftUI
import AuthenticationServices

struct EmailLoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: Spacing.lg) {
                Spacer()

                // MARK: - Orb
                ZStack {
                    LuminousOrb(size: 100)
                    RadialGradient(
                        colors: [Color.chloeEtherealGold.opacity(0.15), Color.chloeEtherealGold.opacity(0.0)],
                        center: .center, startRadius: 10, endRadius: 120
                    )
                    .frame(width: 240, height: 240)
                    .offset(y: 80)
                    .allowsHitTesting(false)
                }

                // MARK: - Header
                VStack(spacing: Spacing.xs) {
                    Text("Welcome back")
                        .font(.chloeGreeting)
                        .foregroundColor(.chloeTextPrimary)

                    Text("Enter your email to continue")
                        .font(.chloeBodyLight)
                        .foregroundColor(.chloeRosewood)
                }

                // MARK: - Email field
                TextField("Email", text: $email, prompt: Text("Email").foregroundColor(.chloeRosewood))
                    .font(.chloeBodyDefault)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(Spacing.sm)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .accessibilityLabel("Email address")

                // MARK: - Password field
                SecureField("Password", text: $password, prompt: Text("Password").foregroundColor(.chloeRosewood))
                    .font(.chloeBodyDefault)
                    .textContentType(.password)
                    .padding(Spacing.sm)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .accessibilityLabel("Password")

                // MARK: - Sign In button
                Button {
                    Task { await authVM.signIn(email: email) }
                } label: {
                    Text("SIGN IN")
                        .font(.custom(ChloeFont.headerDisplay, size: 15))
                        .tracking(3)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.chloePrimary.opacity(email.isBlank ? 0.45 : 1.0))
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                }
                .disabled(email.isBlank)
                .buttonStyle(PressableButtonStyle())
                .padding(.horizontal, Spacing.screenHorizontal)

                // MARK: - Sign Up link
                Button {
                    // TODO: navigate to sign-up
                } label: {
                    (Text("Don't have an account? ")
                        .font(.chloeCaption)
                        .foregroundColor(.chloeTextSecondary)
                    + Text("Sign Up")
                        .font(.chloeCaption)
                        .foregroundColor(.chloePrimary))
                }

                // MARK: - "or" divider
                HStack(spacing: Spacing.xs) {
                    Rectangle()
                        .fill(Color.chloeRosewood.opacity(0.3))
                        .frame(height: 0.5)
                    Text("or")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.chloeRosewood)
                    Rectangle()
                        .fill(Color.chloeRosewood.opacity(0.3))
                        .frame(height: 0.5)
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .accessibilityHidden(true)

                // MARK: - Sign in with Apple
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.email, .fullName]
                } onCompletion: { _ in
                    // TODO: handle Apple sign-in result
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .buttonStyle(PressableButtonStyle())
                .padding(.horizontal, Spacing.screenHorizontal)

                // MARK: - Skip (Dev)
                Button {
                    skipToMain()
                } label: {
                    Text("Skip (Dev)")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.chloePrimary)
                }

                DisclaimerText()

                Spacer()
                    .frame(height: Spacing.lg)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Dev skip (mirrors SettingsView.skipToMain)
    private func skipToMain() {
        var profile = StorageService.shared.loadProfile() ?? Profile()
        if profile.email.isEmpty {
            profile.email = "dev@chloe.test"
        }
        profile.onboardingComplete = true
        profile.updatedAt = Date()
        try? StorageService.shared.saveProfile(profile)

        authVM.email = profile.email
        authVM.isAuthenticated = true

        NotificationCenter.default.post(name: .onboardingDidComplete, object: nil)
    }
}

#Preview {
    NavigationStack {
        EmailLoginView()
            .environmentObject(AuthViewModel())
    }
}
