import SwiftUI

struct JournalEntryEditorView: View {
    @Environment(\.dismiss) var dismiss

    var onSave: (JournalEntry) -> Void

    @State private var title = ""
    @State private var content = ""
    @State private var selectedMood: JournalMood?
    @State private var showMoodPicker = false

    @FocusState private var titleFocused: Bool
    @FocusState private var contentFocused: Bool

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.chloeBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Top spacer for Done pill clearance
                Spacer()
                    .frame(height: Spacing.xxl)

                // Title
                titleField
                    .padding(.bottom, Spacing.sm)

                // Content
                contentField

                // Mood selector at bottom
                moodSection
                    .padding(.top, Spacing.sm)
                    .padding(.bottom, Spacing.md)
            }
            .padding(.horizontal, Spacing.screenHorizontal)

            // Floating Done pill
            donePill
                .padding(.top, Spacing.sm)
                .padding(.trailing, Spacing.screenHorizontal)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Done Pill

    private var donePill: some View {
        Button {
            let entry = JournalEntry(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                mood: selectedMood?.rawValue ?? ""
            )
            onSave(entry)
            dismiss()
        } label: {
            Text("Done")
                .font(.chloeCaption)
                .foregroundColor(canSave ? .white : .chloeTextTertiary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)
                .background(canSave ? Color.chloePrimary : Color.chloeSurface)
                .cornerRadius(Spacing.cornerRadiusLarge)
        }
        .disabled(!canSave)
        .accessibilityLabel("Save entry")
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: canSave)
    }

    // MARK: - Title Field

    private var titleField: some View {
        TextField("Entry title...", text: $title)
            .font(.chloeTitle)
            .foregroundColor(.chloeTextPrimary)
            .focused($titleFocused)
            .onChange(of: title) {
                if title.count > 200 {
                    title = String(title.prefix(200))
                }
            }
            .onAppear {
                titleFocused = true
            }
    }

    // MARK: - Content Field

    private var contentField: some View {
        ZStack(alignment: .topLeading) {
            if content.isEmpty {
                Text("Write your thoughts...")
                    .font(.chloeBodyDefault)
                    .foregroundColor(.chloeTextTertiary)
                    .padding(.top, 8)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $content)
                .font(.chloeBodyDefault)
                .foregroundColor(.chloeTextPrimary)
                .focused($contentFocused)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .onChange(of: content) {
                    if content.count > 10000 {
                        content = String(content.prefix(10000))
                    }
                }
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Mood Section

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if showMoodPicker {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xxs) {
                        ForEach(JournalMood.allCases, id: \.self) { mood in
                            MoodPill(
                                mood: mood,
                                isSelected: selectedMood == mood
                            ) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    if selectedMood == mood {
                                        selectedMood = nil
                                    } else {
                                        selectedMood = mood
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        showMoodPicker = true
                    }
                } label: {
                    HStack(spacing: Spacing.xxxs) {
                        if let mood = selectedMood {
                            Text(mood.emoji)
                                .font(.system(size: 18))
                            Text(mood.label)
                                .font(.chloeCaption)
                                .foregroundColor(.chloeTextPrimary)
                        } else {
                            Text("Add mood")
                                .font(.chloeCaption)
                                .foregroundColor(.chloeTextSecondary)
                        }
                    }
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(Color.chloeSurface)
                    .cornerRadius(Spacing.cornerRadiusLarge)
                    .overlay(
                        RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge)
                            .stroke(Color.chloeBorderWarm, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Mood Pill

private struct MoodPill: View {
    let mood: JournalMood
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xxxs) {
                Text(mood.emoji)
                    .font(.system(size: 18))

                Text(mood.label)
                    .font(.chloeCaption)
                    .foregroundColor(isSelected ? .white : .chloeTextPrimary)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(isSelected ? Color.chloePrimary : Color.chloeSurface)
            .cornerRadius(Spacing.cornerRadiusLarge)
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge)
                    .stroke(
                        isSelected ? Color.clear : Color.chloeBorderWarm,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
        .accessibilityLabel(mood.label)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    JournalEntryEditorView { _ in
    }
}
