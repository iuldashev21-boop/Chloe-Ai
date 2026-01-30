import SwiftUI

struct EmailLoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var email = ""

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: Spacing.lg) {
                Spacer()

                VStack(spacing: Spacing.xs) {
                    Text("Welcome back")
                        .font(.chloeTitle)
                        .foregroundColor(.chloeTextPrimary)

                    Text("Enter your email to continue")
                        .font(.chloeBodyDefault)
                        .foregroundColor(.chloeTextSecondary)
                }

                TextField("your@email.com", text: $email)
                    .font(.chloeBodyDefault)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color.chloeSurface)
                    .cornerRadius(Spacing.cornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: Spacing.cornerRadius)
                            .stroke(Color.chloeBorder, lineWidth: 1)
                    )
                    .padding(.horizontal, Spacing.screenHorizontal)

                Button {
                    Task { await authVM.signIn(email: email) }
                } label: {
                    Text("Continue")
                        .font(.chloeHeadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(email.isBlank ? Color.chloeAccentMuted : Color.chloePrimary)
                        .cornerRadius(Spacing.cornerRadius)
                }
                .disabled(email.isBlank)
                .padding(.horizontal, Spacing.screenHorizontal)

                Spacer()

                DisclaimerText()

                Spacer()
                    .frame(height: Spacing.lg)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        EmailLoginView()
            .environmentObject(AuthViewModel())
    }
}
