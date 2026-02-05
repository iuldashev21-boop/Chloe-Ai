import SwiftUI

struct NewPasswordView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var appeared = false
    @FocusState private var focusedField: Field?

    enum Field: Hashable { case password, confirm }

    private var canSave: Bool {
        password.count >= 6 && password == confirmPassword
    }

    var body: some View {
        ZStack {
            GradientBackground()
            EtherealDustParticles()
                .ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                Spacer()

                // MARK: - Icon
                ZStack {
                    Circle()
                        .fill(Color.chloePrimaryLight)
                        .frame(width: 100, height: 100)

                    Image(systemName: "lock.rotation")
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
                    Text("Set new password")
                        .font(.custom(ChloeFont.heroBoldItalic, size: 32))
                        .tracking(1)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "#2D2324"), Color(hex: "#8E5A5E")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text("CHOOSE A STRONG PASSWORD")
                        .font(.custom(ChloeFont.headerDisplay, size: 13))
                        .tracking(3)
                        .foregroundColor(.chloeRosewood)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

                // MARK: - Form
                VStack(spacing: Spacing.md) {
                    // Password field
                    SecureField("New password", text: $password, prompt: Text("New password").font(.system(size: 17, weight: .light).italic()).foregroundColor(.chloeRosewood))
                        .font(.chloeBodyDefault)
                        .textContentType(.newPassword)
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

                    // Confirm password field
                    SecureField("Confirm password", text: $confirmPassword, prompt: Text("Confirm password").font(.system(size: 17, weight: .light).italic()).foregroundColor(.chloeRosewood))
                        .font(.chloeBodyDefault)
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .confirm)
                        .padding(.horizontal, Spacing.xs)
                        .frame(height: 48)
                        .background(Color.clear)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(Color(hex: "#B76E79").opacity(focusedField == .confirm ? 0.9 : 0.4))
                                .frame(height: focusedField == .confirm ? 1 : 0.5)
                                .shadow(color: Color(hex: "#B76E79").opacity(focusedField == .confirm ? 0.5 : 0), radius: 4)
                                .animation(.easeInOut(duration: 0.3), value: focusedField)
                        }
                        .padding(.horizontal, Spacing.screenHorizontal)

                    // Password requirements hint
                    if !password.isEmpty && password.count < 6 {
                        Text("Password must be at least 6 characters")
                            .font(.chloeCaption)
                            .foregroundColor(.chloeRosewood)
                            .padding(.horizontal, Spacing.screenHorizontal)
                    }

                    // Mismatch hint
                    if !confirmPassword.isEmpty && password != confirmPassword {
                        Text("Passwords don't match")
                            .font(.chloeCaption)
                            .foregroundColor(.red.opacity(0.9))
                            .padding(.horizontal, Spacing.screenHorizontal)
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

                    // Save button
                    Button {
                        Task {
                            await savePassword()
                        }
                    } label: {
                        HStack(spacing: Spacing.xxs) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                            }
                            Text("SAVE PASSWORD")
                                .font(.chloeButton)
                                .tracking(3)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            Capsule()
                                .fill(Color.chloePrimary.opacity(canSave ? 0.8 : 0.4))
                        )
                    }
                    .disabled(!canSave || isLoading)
                    .buttonStyle(PressableButtonStyle())
                    .padding(.horizontal, Spacing.screenHorizontal)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                Spacer()

                DisclaimerText()

                Spacer()
                    .frame(height: Spacing.lg)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                appeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                focusedField = .password
            }
        }
    }

    private func savePassword() async {
        focusedField = nil
        isLoading = true
        errorMessage = nil

        do {
            try await authVM.updatePassword(password)
            // Success - AuthViewModel will dismiss this screen
        } catch {
            errorMessage = "Failed to update password. Please try again."
        }

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        NewPasswordView()
            .environmentObject(AuthViewModel())
    }
}
