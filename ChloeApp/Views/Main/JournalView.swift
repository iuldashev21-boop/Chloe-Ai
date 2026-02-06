import SwiftUI

struct JournalView: View {
    @StateObject private var viewModel = JournalViewModel()
    @State private var showEditor = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            GradientBackground()

            if viewModel.isLoading {
                ProgressView()
                    .controlSize(.regular)
                    .tint(.chloePrimary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.entries.isEmpty {
                emptyState
            } else {
                entryList
            }

            composeButton
        }
        .navigationTitle("Journal")
        .toolbar(.visible, for: .navigationBar)
        .sheet(isPresented: $showEditor) {
            JournalEntryEditorView { entry in
                viewModel.addEntry(entry)
            }
        }
        .onAppear {
            viewModel.loadEntries()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            icon: "book",
            title: "No journal entries yet",
            subtitle: "Tap + to start writing about your day"
        )
    }

    // MARK: - Entry List

    private var entryList: some View {
        List {
            ForEach(viewModel.entries) { entry in
                NavigationLink(destination: JournalDetailView(entry: entry)) {
                    entryCard(entry)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(
                    top: Spacing.sm / 2,
                    leading: Spacing.screenHorizontal,
                    bottom: Spacing.sm / 2,
                    trailing: Spacing.screenHorizontal
                ))
            }
            .onDelete { offsets in
                viewModel.deleteEntry(at: offsets)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Entry Card

    private func entryCard(_ entry: JournalEntry) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            // Mood emoji
            if let mood = JournalMood(rawValue: entry.mood) {
                Text(mood.emoji)
                    .font(.system(size: 24))
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(entry.title)
                    .font(.chloeHeadline)
                    .foregroundColor(.chloeTextPrimary)
                    .lineLimit(2)

                Text(entry.createdAt, style: .relative)
                    .font(.chloeCaption)
                    .foregroundColor(.chloeTextTertiary)
                + Text(" ago")
                    .font(.chloeCaption)
                    .foregroundColor(.chloeTextTertiary)
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.cardPadding)
        .chloeCardStyle()
    }

    // MARK: - Compose Button

    private var composeButton: some View {
        ChloeFloatingActionButton(accessibilityLabel: "New journal entry") {
            showEditor = true
        }
    }
}

#Preview {
    NavigationStack {
        JournalView()
    }
}
