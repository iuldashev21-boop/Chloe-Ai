import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    @State private var profile: Profile?
    @State private var appeared = false

    var body: some View {
        ZStack {
            GradientBackground()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Navigation title
                    Text("Settings")
                        .font(.chloeTitle)
                        .foregroundColor(.chloeTextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Spacing.screenHorizontal)

                    // Account Section
                    settingsSection("ACCOUNT") {
                        HStack(spacing: Spacing.sm) {
                            // Avatar circle
                            Circle()
                                .fill(Color.chloePrimary.opacity(0.15))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Text(avatarInitial)
                                        .font(.chloeHeadline)
                                        .foregroundColor(.chloePrimary)
                                )

                            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                                Text(profile?.displayName ?? "Chloe User")
                                    .font(.chloeBodyDefault)
                                    .foregroundColor(.chloeTextPrimary)

                                Text(profile?.email ?? "")
                                    .font(.chloeCaption)
                                    .foregroundColor(.chloeTextSecondary)
                            }

                            Spacer()

                            // Subscription badge
                            Text(tierLabel)
                                .font(.chloeCaption)
                                .foregroundColor(.white)
                                .padding(.horizontal, Spacing.xxs)
                                .padding(.vertical, Spacing.xxxs)
                                .background(
                                    Capsule()
                                        .fill(profile?.subscriptionTier == .premium
                                              ? Color.chloePrimary
                                              : Color.chloeTextTertiary)
                                )
                        }
                    }

                    // Preferences Section
                    settingsSection("PREFERENCES") {
                        VStack(spacing: 0) {
                            settingsToggleRow(
                                icon: "bell",
                                label: "Notifications",
                                isOn: $notificationsEnabled
                            )

                            Divider()
                                .padding(.leading, 40)

                            settingsToggleRow(
                                icon: "hand.tap",
                                label: "Haptic Feedback",
                                isOn: $hapticFeedbackEnabled
                            )
                        }
                    }

                    // Support Section
                    settingsSection("SUPPORT") {
                        VStack(spacing: 0) {
                            settingsRow(icon: "info.circle", label: "About Chloe") {
                                Text(appVersion)
                                    .font(.chloeCaption)
                                    .foregroundColor(.chloeTextSecondary)
                            }

                            Divider()
                                .padding(.leading, 40)

                            settingsRow(icon: "envelope", label: "Send Feedback") {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.chloeTextTertiary)
                            }
                        }
                    }

                    // Sign Out
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        authVM.signOut()
                    } label: {
                        Text("SIGN OUT")
                            .font(.chloeButton)
                            .tracking(1.5)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.chloeRosewood)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.top, Spacing.sm)
                }
                .padding(.top, Spacing.xl)
                .padding(.bottom, Spacing.xxl)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)
        }
        .navigationBarHidden(true)
        .onAppear {
            profile = StorageService.shared.loadProfile()
            withAnimation(Spacing.chloeSpring) {
                appeared = true
            }
        }
    }

    // MARK: - Helpers

    private var avatarInitial: String {
        let name = profile?.displayName ?? ""
        return name.isEmpty ? "?" : String(name.prefix(1)).uppercased()
    }

    private var tierLabel: String {
        profile?.subscriptionTier == .premium ? "Premium" : "Free"
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (\(build))"
    }

    // MARK: - Section Builder

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.chloeSidebarSectionHeader)
                .tracking(2)
                .foregroundColor(.chloeTextTertiary)
                .padding(.horizontal, Spacing.screenHorizontal)

            BentoGridCard {
                content()
            }
            .padding(.horizontal, Spacing.screenHorizontal)
        }
    }

    // MARK: - Row Builders

    private func settingsRow<Trailing: View>(icon: String, label: String, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.chloePrimary)
                .frame(width: 24)

            Text(label)
                .font(.chloeBodyDefault)
                .foregroundColor(.chloeTextPrimary)

            Spacer()

            trailing()
        }
        .padding(.vertical, Spacing.xs)
    }

    private func settingsToggleRow(icon: String, label: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.chloePrimary)
                .frame(width: 24)

            Text(label)
                .font(.chloeBodyDefault)
                .foregroundColor(.chloeTextPrimary)

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(.chloePrimary)
        }
        .padding(.vertical, Spacing.xs)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AuthViewModel())
    }
}
