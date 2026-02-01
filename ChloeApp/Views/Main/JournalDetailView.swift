import SwiftUI

struct JournalDetailView: View {
    let entry: JournalEntry

    private var moodEnum: JournalMood? {
        JournalMood(rawValue: entry.mood)
    }

    var body: some View {
        ZStack {
            Color.chloeBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header section
                    headerSection
                        .padding(.bottom, Spacing.lg)

                    // Decorative separator
                    separator
                        .padding(.bottom, Spacing.lg)

                    // Content
                    contentSection
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.xxxl)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Mood badge
            if let mood = moodEnum {
                HStack(spacing: Spacing.xxs) {
                    Text(mood.emoji)
                        .font(.system(size: 20))

                    Text(mood.label)
                        .font(.chloeSubheadline)
                        .foregroundColor(.chloePrimary)
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)
                .background(Color.chloePrimaryLight)
                .cornerRadius(Spacing.cornerRadiusLarge)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Mood: \(mood.label)")
            }

            // Title
            Text(entry.title)
                .font(.chloeLargeTitle)
                .foregroundColor(.chloeTextPrimary)
                .fixedSize(horizontal: false, vertical: true)

            // Date
            Text(entry.createdAt.journalHeader)
                .font(.chloeCaption)
                .foregroundColor(.chloeTextTertiary)
        }
    }

    // MARK: - Separator

    private var separator: some View {
        HStack(spacing: Spacing.xs) {
            Rectangle()
                .fill(Color.chloeBorderWarm)
                .frame(height: 1)

            Circle()
                .fill(Color.chloeAccentMuted)
                .frame(width: 6, height: 6)

            Rectangle()
                .fill(Color.chloeBorderWarm)
                .frame(height: 1)
        }
        .accessibilityHidden(true)
    }

    // MARK: - Content

    private var contentSection: some View {
        Group {
            if entry.content.isEmpty {
                Text("No content")
                    .font(.chloeBodyDefault)
                    .foregroundColor(.chloeTextTertiary)
                    .italic()
            } else {
                Text(entry.content)
                    .font(.chloeBodyDefault)
                    .foregroundColor(.chloeTextPrimary)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    NavigationStack {
        JournalDetailView(
            entry: JournalEntry(
                title: "A Morning of Clarity",
                content: "Today I woke up feeling lighter than I have in weeks. The sun was streaming through the curtains and I just lay there for a moment, breathing it all in.\n\nI've been working on letting go of the things I can't control, and today it felt like something shifted. Not dramatically — more like a quiet settling, the way water finds its level.\n\nI want to remember this feeling. This calm certainty that everything is unfolding exactly as it should. I am enough, right here, right now.",
                mood: JournalMood.calm.rawValue,
                createdAt: Date()
            )
        )
    }
}
