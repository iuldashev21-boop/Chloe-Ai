import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: Spacing.xl) {
                Spacer()

                ChloeAvatar(size: 100)

                VStack(spacing: Spacing.xs) {
                    Text("Chloe")
                        .font(.chloeLargeTitle)
                        .foregroundColor(.chloePrimary)

                    Text("Your pocket feminine energy coach")
                        .font(.chloeBodyDefault)
                        .foregroundColor(.chloeTextSecondary)
                }

                Spacer()

                NavigationLink(destination: EmailLoginView()) {
                    ChloeButtonLabel(title: "Get Started")
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.horizontal, Spacing.screenHorizontal)

                DisclaimerText()

                Spacer()
                    .frame(height: Spacing.xl)
            }
        }
    }
}

#Preview {
    NavigationStack {
        WelcomeView()
            .environmentObject(AuthViewModel())
    }
}
