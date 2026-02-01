import SwiftUI
import AuthenticationServices
import Combine

struct EmailLoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var shimmerOffset: CGFloat = -200
    @FocusState private var focusedField: Field?
    @State private var showOrb = false
    @State private var showText = false
    @State private var showFields = false
    @State private var keyboardVisible = false

    enum Field: Hashable { case email, password }

    var body: some View {
        ZStack {
            GradientBackground()
            EtherealDustParticles()

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
                .opacity(showOrb ? 1 : 0)
                .scaleEffect(keyboardVisible ? 0.7 : (showOrb ? 1 : 0.8))
                .offset(x: keyboardVisible ? 120 : 0, y: keyboardVisible ? -60 : 0)
                .animation(Spacing.chloeSpring, value: keyboardVisible)
                .animation(Spacing.chloeSpring, value: showOrb)

                // MARK: - Header
                VStack(spacing: Spacing.xs) {
                    Text("Welcome home")
                        .font(.custom(ChloeFont.heroBoldItalic, size: 36))
                        .foregroundColor(.chloeTextPrimary)

                    Text("ENTER YOUR SANCTUARY")
                        .font(.custom(ChloeFont.headerDisplay, size: 11))
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
                        .focused($focusedField, equals: .email)
                        .padding(.horizontal, Spacing.sm)
                        .frame(height: 52)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge))
                        .overlay(
                            RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge)
                                .stroke(Color(hex: "#E8D4D0"), lineWidth: 0.5)
                        )
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .accessibilityLabel("Email address")

                    // MARK: - Password field
                    SecureField("Password", text: $password, prompt: Text("Password").font(.system(size: 17, weight: .light).italic()).foregroundColor(.chloeRosewood))
                        .font(.chloeBodyDefault)
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                        .padding(.horizontal, Spacing.sm)
                        .frame(height: 52)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge))
                        .overlay(
                            RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge)
                                .stroke(Color(hex: "#E8D4D0"), lineWidth: 0.5)
                        )
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .accessibilityLabel("Password")

                    // MARK: - Sign In button
                    Button {
                        Task { await authVM.signIn(email: email) }
                    } label: {
                        Text("Sign In")
                            .font(.system(size: 17, weight: .medium))
                            .tracking(1.5)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                ZStack {
                                    Capsule().fill(.ultraThinMaterial)
                                    Capsule().fill(Color.chloePrimary.opacity(email.isBlank ? 0.3 : 0.6))
                                    LinearGradient(
                                        colors: [.clear, .white.opacity(0.25), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .offset(x: shimmerOffset)
                                    .mask(Capsule())
                                }
                            )
                            .clipShape(Capsule())
                            .shadow(color: .chloePrimary.opacity(0.15), radius: 20, y: 10)
                    }
                    .disabled(email.isBlank)
                    .buttonStyle(PressableButtonStyle())
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .onAppear { startShimmerLoop() }

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
                    .signInWithAppleButtonStyle(.white)
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
        .onTapGesture { focusedField = nil }
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
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            keyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardVisible = false
        }
    }

    private func startShimmerLoop() {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            shimmerOffset = -200
            withAnimation(.easeInOut(duration: 0.8)) {
                shimmerOffset = 200
            }
        }
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
