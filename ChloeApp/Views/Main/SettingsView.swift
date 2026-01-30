import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: Spacing.lg) {
                Text("Settings")
                    .font(.chloeTitle)
                    .foregroundColor(.chloeTextPrimary)

                Text("Coming soon")
                    .font(.chloeBodyDefault)
                    .foregroundColor(.chloeTextTertiary)

                Spacer()

                Button {
                    authVM.signOut()
                } label: {
                    Text("Sign Out")
                        .font(.chloeHeadline)
                        .foregroundColor(.chloePrimary)
                }
                .padding(.bottom, Spacing.xl)
            }
            .padding(.top, Spacing.xl)
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AuthViewModel())
    }
}
