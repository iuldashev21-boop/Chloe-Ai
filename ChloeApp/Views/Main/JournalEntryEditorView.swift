import SwiftUI

struct JournalEntryEditorView: View {
    @Environment(\.dismiss) var dismiss

    var onSave: (JournalEntry) -> Void

    @State private var title = ""
    @State private var content = ""
    @State private var selectedMood: JournalMood?

    @FocusState private var titleFocused: Bool
    @FocusState private var contentFocused: Bool

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.chloeBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        // Mood selector
                        moodSelector

                        // Divider
                        Rectangle()
                            .fill(Color.chloeBorderWarm)
                            .frame(height: 1)
                            .padding(.horizontal, Spacing.screenHorizontal)

                        // Title
                        titleField

                        // Content
                        contentField
                    }
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.xxxl)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.chloeBodyDefault)
                    .foregroundColor(.chloeTextSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let entry = JournalEntry(
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                            mood: selectedMood?.rawValue ?? ""
                        )
                        onSave(entry)
                        dismiss()
                    }
                    .font(.chloeHeadline)
                    .foregroundColor(canSave ? .chloePrimary : .chloeTextTertiary)
                    .disabled(!canSave)
                    .animation(.easeInOut(duration: 0.2), value: canSave)
                }
            }
        }
    }

    // MARK: - Mood Selector

    private var moodSelector: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("How are you feeling?")
                .font(.chloeSubheadline)
                .foregroundColor(.chloeTextSecondary)
                .padding(.horizontal, Spacing.screenHorizontal)

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
                .padding(.horizontal, Spacing.screenHorizontal)
            }
        }
    }

    // MARK: - Title Field

    private var titleField: some View {
        TextField("Entry title...", text: $title)
            .font(.chloeTitle)
            .foregroundColor(.chloeTextPrimary)
            .focused($titleFocused)
            .padding(.horizontal, Spacing.screenHorizontal)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    titleFocused = true
                }
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
                .frame(minHeight: 240)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
        }
        .padding(.horizontal, Spacing.screenHorizontal)
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
    }
}

#Preview {
    JournalEntryEditorView { entry in
        print("Saved: \(entry.title)")
    }
}
