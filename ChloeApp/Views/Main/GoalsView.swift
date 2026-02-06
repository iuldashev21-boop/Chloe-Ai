import SwiftUI

struct GoalsView: View {
    @StateObject private var viewModel = GoalsViewModel()
    @State private var showAddGoal = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            GradientBackground()

            if viewModel.isLoading {
                ProgressView()
                    .controlSize(.regular)
                    .tint(.chloePrimary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.goals.isEmpty {
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
        EmptyStateView(
            icon: "target",
            title: "No goals set yet",
            subtitle: "Set your first goal to start tracking progress"
        )
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
        .refreshable {
            viewModel.loadGoals()
        }
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
        .chloeCardStyle()
    }

    // MARK: - Add Button

    private var addButton: some View {
        ChloeFloatingActionButton(accessibilityLabel: "Add goal") {
            showAddGoal = true
        }
    }
}

// MARK: - Add Goal Sheet

private struct AddGoalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var isSaving = false

    var onAdd: (Goal) -> Void

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.chloeBackground.ignoresSafeArea()

                VStack(spacing: Spacing.lg) {
                    VStack(alignment: .trailing, spacing: Spacing.xxxs) {
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

                        if title.count > 150 {
                            Text("\(200 - title.count)")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(title.count >= 200 ? .red.opacity(0.8) : .chloeTextTertiary)
                                .padding(.trailing, Spacing.xxs)
                        }
                    }

                    VStack(alignment: .trailing, spacing: Spacing.xxxs) {
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

                        if description.count > 400 {
                            Text("\(500 - description.count)")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(description.count >= 500 ? .red.opacity(0.8) : .chloeTextTertiary)
                                .padding(.trailing, Spacing.xxs)
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.top, Spacing.md)
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
                        guard !isSaving else { return }
                        isSaving = true
                        let goal = Goal(
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                            description: description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        onAdd(goal)
                        dismiss()
                    }
                    .foregroundColor(canSave && !isSaving ? .chloePrimary : .chloeTextTertiary)
                    .disabled(!canSave || isSaving)
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
