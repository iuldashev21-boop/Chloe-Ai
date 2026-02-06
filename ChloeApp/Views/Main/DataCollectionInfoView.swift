import SwiftUI

/// Informational sheet explaining what data Chloe collects and how it is used.
/// Presented from the "What We Collect" row in the Privacy & Legal section of Settings.
struct DataCollectionInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        // Header
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Image(systemName: "lock.shield")
                                .font(.system(size: 36, weight: .light))
                                .foregroundColor(.chloePrimary)

                            Text("Your Data & Privacy")
                                .font(.chloeTitle2)
                                .foregroundColor(.chloeTextPrimary)

                            Text("Chloe collects the following data to provide your experience:")
                                .font(.chloeBodyDefault)
                                .foregroundColor(.chloeTextSecondary)
                        }

                        // Data categories
                        VStack(spacing: Spacing.xs) {
                            dataRow(
                                icon: "person.crop.circle",
                                title: "Profile Information",
                                detail: "Your name, email address, and personality archetype are stored to personalize your experience."
                            )

                            dataRow(
                                icon: "bubble.left.and.bubble.right",
                                title: "Chat Conversations",
                                detail: "Messages between you and Chloe are stored with encryption in our cloud database (Supabase) so you can continue conversations across sessions."
                            )

                            dataRow(
                                icon: "book.closed",
                                title: "Journal Entries",
                                detail: "Your journal entries, including mood tags, are stored so you can reflect on your personal growth over time."
                            )

                            dataRow(
                                icon: "target",
                                title: "Goals & Vision Board",
                                detail: "Goals you set and vision board items you create are stored to help you track progress toward what matters to you."
                            )

                            dataRow(
                                icon: "chart.bar",
                                title: "Anonymous Analytics",
                                detail: "We use TelemetryDeck for anonymous usage analytics. This data contains no personally identifiable information (PII) -- it helps us understand how features are used so we can improve the app."
                            )
                        }

                        // Divider
                        Rectangle()
                            .fill(Color.chloeBorder)
                            .frame(height: 1)
                            .padding(.vertical, Spacing.xxs)

                        // Commitments
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            commitmentRow(
                                icon: "hand.raised.slash",
                                text: "Your data is never sold to third parties."
                            )

                            commitmentRow(
                                icon: "trash",
                                text: "You can delete all your data at any time from Settings."
                            )

                            commitmentRow(
                                icon: "square.and.arrow.up",
                                text: "You can export a copy of all your data at any time."
                            )

                            commitmentRow(
                                icon: "lock.fill",
                                text: "All network communication uses HTTPS encryption."
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.top, Spacing.lg)
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .navigationTitle("What We Collect")
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

    // MARK: - Row Builders

    private func dataRow(icon: String, title: String, detail: String) -> some View {
        BentoGridCard {
            HStack(alignment: .top, spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.chloePrimary)
                    .frame(width: 28)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    Text(title)
                        .font(.chloeSubheadline)
                        .foregroundColor(.chloeTextPrimary)

                    Text(detail)
                        .font(.chloeCaption)
                        .foregroundColor(.chloeTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func commitmentRow(icon: String, text: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.chloePrimary)
                .frame(width: 24)

            Text(text)
                .font(.chloeBodyDefault)
                .foregroundColor(.chloeTextPrimary)
        }
    }
}

#Preview {
    DataCollectionInfoView()
}
