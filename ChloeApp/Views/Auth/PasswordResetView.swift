import SwiftUI

struct PasswordResetView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var appeared = false
    @FocusState private var emailFocused: Bool

    private var isEmailFormatValid: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let atIndex = trimmed.firstIndex(of: "@") else { return false }
        let afterAt = trimmed[trimmed.index(after: atIndex)...]
        return afterAt.contains(".")
    }

    private var showEmailHint: Bool {
        !email.isBlank && !isEmailFormatValid
    }

    private var canSubmit: Bool {
        isEmailFormatValid
    }

    var body: some View {
        ZStack {
            GradientBackground()
            EtherealDustParticles()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                Spacer()

                // MARK: - Icon
                ZStack {
                    Circle()
                        .fill(Color.chloePrimaryLight)
                        .frame(width: 100, height: 100)

                    Image(systemName: "key.fill")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.chloePrimary, .chloeAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .scaleEffect(appeared ? 1 : 0.5)
                .opacity(appeared ? 1 : 0)

                // MARK: - Header
                VStack(spacing: Spacing.xs) {
                    Text("Reset password")
                        .font(.custom(ChloeFont.heroBoldItalic, size: 32))
                        .tracking(1)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "#2D2324"), Color(hex: "#8E5A5E")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text("WE'LL SEND YOU A LINK")
                        .font(.custom(ChloeFont.headerDisplay, size: 13))
                        .tracking(3)
                        .foregroundColor(.chloeRosewood)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

                if showSuccess {
                    // MARK: - Success State
                    successView
                        .transition(.opacity.combined(with: .scale))
                } else {
                    // MARK: - Form State
                    formView
                        .transition(.opacity)
                }

                Spacer()

                DisclaimerText()

                Spacer()
                    .frame(height: Spacing.lg)
            }
                .frame(minHeight: UIScreen.main.bounds.height)
                }
                .scrollDismissesKeyboard(.interactively)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                appeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                emailFocused = true
            }
        }
    }

    // MARK: - Form View

    private var formView: some View {
        VStack(spacing: Spacing.md) {
            Text("Enter the email address you used to sign up and we'll send you a link to reset your password.")
                .font(.chloeBodyDefault)
                .foregroundColor(.chloeTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.screenHorizontal)

            // Email field
            TextField("Email", text: $email, prompt: Text("Email").font(.system(size: 17, weight: .light).italic()).foregroundColor(.chloeRosewood))
                .font(.chloeBodyDefault)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .submitLabel(.send)
                .focused($emailFocused)
                .padding(.horizontal, Spacing.xs)
                .frame(height: 48)
                .background(Color.clear)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color(hex: "#B76E79").opacity(emailFocused ? 0.9 : 0.4))
                        .frame(height: emailFocused ? 1 : 0.5)
                        .shadow(color: Color(hex: "#B76E79").opacity(emailFocused ? 0.5 : 0), radius: 4)
                        .animation(.easeInOut(duration: 0.3), value: emailFocused)
                }
                .padding(.horizontal, Spacing.screenHorizontal)

            // Email format hint
            if showEmailHint {
                Text("Enter a valid email address")
                    .font(.chloeCaption)
                    .foregroundColor(.chloeRosewood.opacity(0.8))
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: showEmailHint)
            }

            // Error message
            if let error = errorMessage {
                Text(error)
                    .font(.chloeCaption)
                    .foregroundColor(.red.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .transition(.opacity)
            }

            // Send button
            Button {
                Task {
                    await sendResetLink()
                }
            } label: {
                HStack(spacing: Spacing.xxs) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    }
                    Text("SEND RESET LINK")
                        .font(.chloeButton)
                        .tracking(3)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    Capsule()
                        .fill(Color.chloePrimary.opacity(canSubmit ? 0.8 : 0.4))
                )
            }
            .disabled(!canSubmit || isLoading)
            .buttonStyle(PressableButtonStyle())
            .padding(.horizontal, Spacing.screenHorizontal)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
    }

    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#4A7C59").opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color(hex: "#4A7C59"))
            }

            Text("Check your email")
                .font(.chloeHeadline)
                .foregroundColor(.chloeTextPrimary)

            Text("We sent a password reset link to")
                .font(.chloeBodyDefault)
                .foregroundColor(.chloeTextSecondary)

            Text(email)
                .font(.chloeBodyDefault.weight(.semibold))
                .foregroundColor(.chloeTextPrimary)

            Text("Click the link in your email to create a new password, then come back and sign in.")
                .font(.chloeBodyDefault)
                .foregroundColor(.chloeTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.screenHorizontal)

            Button {
                dismiss()
            } label: {
                Text("BACK TO SIGN IN")
                    .font(.chloeButton)
                    .tracking(3)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        Capsule()
                            .fill(Color.chloePrimary.opacity(0.8))
                    )
            }
            .buttonStyle(PressableButtonStyle())
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.top, Spacing.sm)
        }
    }

    // MARK: - Actions

    private func sendResetLink() async {
        emailFocused = false
        isLoading = true
        errorMessage = nil

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            try await authVM.sendPasswordReset(email: trimmedEmail)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showSuccess = true
            }
        } catch {
            let errorString = String(describing: error).lowercased()
            if errorString.contains("rate") || errorString.contains("429") || errorString.contains("limit") {
                errorMessage = "Too many requests. Please wait a few minutes and try again."
            } else {
                errorMessage = "Unable to send reset email. Please check your email address."
            }
        }

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        PasswordResetView()
            .environmentObject(AuthViewModel())
    }
}
