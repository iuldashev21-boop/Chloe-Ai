import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    @State private var profile: Profile?
    @State private var appeared = false
    @State private var showClearDataAlert = false
    @State private var showResetAlert = false

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

                    // Developer Mode Section
                    devModeSection

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
        .alert("Clear All Data?", isPresented: $showClearDataAlert) {
            Button("Clear Everything", role: .destructive) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                notificationsEnabled = true
                hapticFeedbackEnabled = true
                authVM.signOut()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete all local data including your profile, conversations, journal entries, and preferences. You'll need to sign in and complete onboarding again.")
        }
        .alert("Reset to Welcome?", isPresented: $showResetAlert) {
            Button("Reset", role: .destructive) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                authVM.signOut()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will sign you out and return to the welcome screen. Your data will be cleared.")
        }
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

    // MARK: - Developer Mode

    private var devModeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("DEVELOPER")
                .font(.chloeSidebarSectionHeader)
                .tracking(2)
                .foregroundColor(.red.opacity(0.5))
                .padding(.horizontal, Spacing.screenHorizontal)

            VStack(spacing: Spacing.xs) {
                // Skip to Main App toggle
                BentoGridCard {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.orange)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Skip to Main App")
                                .font(.chloeBodyDefault)
                                .foregroundColor(.chloeTextPrimary)
                            Text("Bypass auth & onboarding")
                                .font(.chloeCaption)
                                .foregroundColor(.chloeTextTertiary)
                        }

                        Spacer()

                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            skipToMain()
                        } label: {
                            Text("GO")
                                .font(.chloeCaption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, Spacing.xs)
                                .padding(.vertical, Spacing.xxxs)
                                .background(Capsule().fill(Color.orange))
                        }
                    }
                }

                // Destructive actions
                BentoGridCard {
                    VStack(spacing: 0) {
                        // Reset to Welcome
                        Button {
                            showResetAlert = true
                        } label: {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.orange)
                                    .frame(width: 24)

                                Text("Reset to Welcome Screen")
                                    .font(.chloeBodyDefault)
                                    .foregroundColor(.chloeTextPrimary)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.chloeTextTertiary)
                            }
                            .padding(.vertical, Spacing.xs)
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .padding(.leading, 40)

                        // Clear All Data
                        Button {
                            showClearDataAlert = true
                        } label: {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "trash")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.red.opacity(0.8))
                                    .frame(width: 24)

                                Text("Clear All Data")
                                    .font(.chloeBodyDefault)
                                    .foregroundColor(.red.opacity(0.8))

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.chloeTextTertiary)
                            }
                            .padding(.vertical, Spacing.xs)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
        }
    }

    private func skipToMain() {
        // Create a complete profile so auth + onboarding are satisfied
        var profile = StorageService.shared.loadProfile() ?? Profile()
        if profile.email.isEmpty {
            profile.email = "dev@chloe.test"
        }
        profile.onboardingComplete = true
        profile.updatedAt = Date()
        try? StorageService.shared.saveProfile(profile)

        // Update auth state
        authVM.email = profile.email
        authVM.isAuthenticated = true

        // Signal onboarding complete
        NotificationCenter.default.post(name: .onboardingDidComplete, object: nil)
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
