import SwiftUI

struct EmailConfirmationView: View {
    let email: String
    let onResend: () async -> Void
    let onChangeEmail: () -> Void

    @State private var isResending = false
    @State private var resendSuccess = false
    @State private var appeared = false
    @State private var iconScale: CGFloat = 0.5

    var body: some View {
        ZStack {
            GradientBackground()
            EtherealDustParticles()
                .ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                Spacer()

                // MARK: - Email Icon
                ZStack {
                    Circle()
                        .fill(Color.chloePrimaryLight)
                        .frame(width: 120, height: 120)

                    Image(systemName: "envelope.badge")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.chloePrimary, .chloeAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .scaleEffect(iconScale)
                .opacity(appeared ? 1 : 0)

                // MARK: - Header
                VStack(spacing: Spacing.xs) {
                    Text("Check your inbox")
                        .font(.custom(ChloeFont.heroBoldItalic, size: 32))
                        .tracking(1)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "#2D2324"), Color(hex: "#8E5A5E")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text("ONE MORE STEP")
                        .font(.custom(ChloeFont.headerDisplay, size: 13))
                        .tracking(3)
                        .foregroundColor(.chloeRosewood)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

                // MARK: - Instructions
                VStack(spacing: Spacing.sm) {
                    Text("We sent a confirmation link to")
                        .font(.chloeBodyDefault)
                        .foregroundColor(.chloeTextSecondary)

                    Text(email)
                        .font(.chloeBodyDefault.weight(.semibold))
                        .foregroundColor(.chloeTextPrimary)

                    Text("Tap the link in your email, then come back here to sign in.")
                        .font(.chloeBodyDefault)
                        .foregroundColor(.chloeTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, Spacing.xxs)
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

                Spacer()

                // MARK: - Resend Button
                VStack(spacing: Spacing.sm) {
                    if resendSuccess {
                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.chloeSuccess)
                            Text("Email sent!")
                                .font(.chloeCaption)
                                .foregroundColor(.chloeSuccess)
                        }
                        .transition(.opacity.combined(with: .scale))
                    } else {
                        Button {
                            Task {
                                isResending = true
                                await onResend()
                                isResending = false
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    resendSuccess = true
                                }
                                // Reset after 3 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    withAnimation { resendSuccess = false }
                                }
                            }
                        } label: {
                            HStack(spacing: Spacing.xxs) {
                                if isResending {
                                    ProgressView()
                                        .tint(.chloePrimary)
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                                Text("Resend confirmation email")
                            }
                            .font(.chloeBodyDefault)
                            .foregroundColor(.chloePrimary)
                        }
                        .disabled(isResending)
                    }

                    Button {
                        onChangeEmail()
                    } label: {
                        Text("Use a different email")
                            .font(.chloeCaption)
                            .foregroundColor(.chloeTextTertiary)
                    }
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .opacity(appeared ? 1 : 0)

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
                iconScale = 1.0
            }
        }
    }
}

#Preview {
    NavigationStack {
        EmailConfirmationView(
            email: "test@example.com",
            onResend: {},
            onChangeEmail: {}
        )
    }
}
