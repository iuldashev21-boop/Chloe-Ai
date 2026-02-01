import SwiftUI

struct GoalsView: View {
    @StateObject private var viewModel = GoalsViewModel()
    @State private var showAddGoal = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            GradientBackground()

            if viewModel.goals.isEmpty {
                emptyState
            } else {
                goalList
            }

            addButton
        }
        .navigationTitle("Goals")
        .toolbar(.visible, for: .navigationBar)
        .sheet(isPresented: $showAddGoal) {
            AddGoalSheet { goal in
                viewModel.addGoal(goal)
            }
        }
        .onAppear {
            viewModel.loadGoals()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "target")
                .font(.system(size: 40, weight: .thin))
                .foregroundColor(.chloeTextTertiary)
                .accessibilityHidden(true)

            Text("Set your first goal")
                .font(.chloeBodyDefault)
                .foregroundColor(.chloeTextTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Goal List

    private var goalList: some View {
        List {
            ForEach(viewModel.goals) { goal in
                goalCard(goal)
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
                viewModel.deleteGoal(at: offsets)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Goal Card

    private func goalCard(_ goal: Goal) -> some View {
        HStack(spacing: Spacing.sm) {
            Button {
                viewModel.toggleGoalStatus(goalId: goal.id)
            } label: {
                Image(systemName: goal.status == .completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .light))
                    .foregroundColor(goal.status == .completed ? .chloePrimary : .chloeTextTertiary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(goal.status == .completed ? "Mark \(goal.title) incomplete" : "Mark \(goal.title) complete")

            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(goal.title)
                    .font(.chloeHeadline)
                    .foregroundColor(.chloeTextPrimary)
                    .strikethrough(goal.status == .completed)
                    .lineLimit(2)

                if let description = goal.description, !description.isEmpty {
                    Text(description)
                        .font(.chloeCaption)
                        .foregroundColor(.chloeTextTertiary)
                        .lineLimit(1)
                }

                Text(goal.createdAt, style: .relative)
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

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            showAddGoal = true
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
        .accessibilityLabel("Add goal")
        .padding(.trailing, Spacing.screenHorizontal)
        .padding(.bottom, Spacing.lg)
    }
}

// MARK: - Add Goal Sheet

private struct AddGoalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""

    var onAdd: (Goal) -> Void

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.chloeBackground.ignoresSafeArea()

                VStack(spacing: Spacing.lg) {
                    TextField("Goal title", text: $title)
                        .font(.chloeBodyDefault)
                        .foregroundColor(.chloeTextPrimary)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.chloeSurface)
                        .cornerRadius(Spacing.cornerRadius)
                        .onChange(of: title) {
                            if title.count > 200 {
                                title = String(title.prefix(200))
                            }
                        }

                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .font(.chloeBodyDefault)
                        .foregroundColor(.chloeTextPrimary)
                        .lineLimit(1...4)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.chloeSurface)
                        .cornerRadius(Spacing.cornerRadius)
                        .onChange(of: description) {
                            if description.count > 500 {
                                description = String(description.prefix(500))
                            }
                        }

                    Spacer()
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.top, Spacing.md)
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.chloeTextSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        let goal = Goal(
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                            description: description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        onAdd(goal)
                        dismiss()
                    }
                    .foregroundColor(canSave ? .chloePrimary : .chloeTextTertiary)
                    .disabled(!canSave)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    NavigationStack {
        GoalsView()
    }
}
