import SwiftUI

struct JournalView: View {
    @StateObject private var viewModel = JournalViewModel()
    @State private var showEditor = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            GradientBackground()

            if viewModel.entries.isEmpty {
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
        VStack(spacing: Spacing.sm) {
            Image(systemName: "book.closed")
                .font(.system(size: 40, weight: .thin))
                .foregroundColor(.chloeTextTertiary)

            Text("Begin writing")
                .font(.chloeBodyDefault)
                .foregroundColor(.chloeTextTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(
            color: Color.chloeRosewood.opacity(0.12),
            radius: 16,
            x: 0,
            y: 6
        )
    }

    // MARK: - Compose Button

    private var composeButton: some View {
        Button {
            showEditor = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .light))
                .foregroundColor(.chloePrimary)
                .frame(width: 52, height: 52)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(
                    color: Color.chloeRosewood.opacity(0.12),
                    radius: 8,
                    x: 0,
                    y: 3
                )
        }
        .padding(.trailing, Spacing.screenHorizontal)
        .padding(.bottom, Spacing.lg)
    }
}

#Preview {
    NavigationStack {
        JournalView()
    }
}
