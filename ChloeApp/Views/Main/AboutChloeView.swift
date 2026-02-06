import SwiftUI

/// Informational sheet showing app version, credits, and links.
/// Presented from the "About Chloe" row in the Support section of Settings.
struct AboutChloeView: View {
    @Environment(\.dismiss) private var dismiss

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // App Icon & Name
                        VStack(spacing: Spacing.sm) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 48, weight: .light))
                                .foregroundColor(.chloePrimary)
                                .padding(.top, Spacing.lg)

                            Text("Chloe")
                                .font(.chloeTitle)
                                .foregroundColor(.chloeTextPrimary)

                            Text("Your Pocket Life Coach")
                                .font(.chloeSubheadline)
                                .foregroundColor(.chloeTextSecondary)

                            Text(appVersion)
                                .font(.chloeCaption)
                                .foregroundColor(.chloeTextTertiary)
                                .padding(.top, Spacing.xxxs)
                        }

                        // Description
                        BentoGridCard {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("Chloe is your AI-powered companion for personal growth, self-reflection, and emotional well-being. She helps you set goals, journal your thoughts, build vision boards, and navigate life with confidence.")
                                    .font(.chloeBodyDefault)
                                    .foregroundColor(.chloeTextSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.horizontal, Spacing.screenHorizontal)

                        // Links
                        BentoGridCard {
                            VStack(spacing: 0) {
                                Link(destination: URL(string: "https://auth-redirect-one.vercel.app/privacy")!) {
                                    linkRow(icon: "hand.raised", label: "Privacy Policy")
                                }
                                .buttonStyle(.plain)

                                Divider()
                                    .padding(.leading, 40)

                                Link(destination: URL(string: "https://auth-redirect-one.vercel.app/terms")!) {
                                    linkRow(icon: "doc.text", label: "Terms of Service")
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Spacing.screenHorizontal)

                        // Credits
                        VStack(spacing: Spacing.xxs) {
                            Text("Made with care")
                                .font(.chloeCaption)
                                .foregroundColor(.chloeTextTertiary)

                            Text("Copyright \(copyrightYear) Chloe App")
                                .font(.chloeCaption)
                                .foregroundColor(.chloeTextTertiary)
                        }
                        .padding(.top, Spacing.sm)
                        .padding(.bottom, Spacing.xxl)
                    }
                }
            }
            .navigationTitle("About Chloe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.chloeBodyDefault)
                    .foregroundColor(.chloePrimary)
                }
            }
        }
    }

    // MARK: - Helpers

    private func linkRow(icon: String, label: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.chloePrimary)
                .frame(width: 24)
                .accessibilityHidden(true)

            Text(label)
                .font(.chloeBodyDefault)
                .foregroundColor(.chloeTextPrimary)

            Spacer()

            Image(systemName: "arrow.up.right")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.chloeTextTertiary)
                .accessibilityHidden(true)
        }
        .padding(.vertical, Spacing.xs)
    }

    private var copyrightYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: Date())
    }
}

#Preview {
    AboutChloeView()
}
