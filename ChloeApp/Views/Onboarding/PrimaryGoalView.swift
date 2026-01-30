import SwiftUI

struct PrimaryGoalView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private var selectedGoals: [PrimaryGoal] {
        viewModel.preferences.primaryGoal ?? []
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Text("What's your primary goal?")
                .font(.chloeTitle)
                .foregroundColor(.chloeTextPrimary)

            VStack(spacing: Spacing.xs) {
                ForEach(PrimaryGoal.allCases, id: \.self) { goal in
                    SelectionChip(
                        title: goal.rawValue.replacingOccurrences(of: "_", with: " ").capitalized,
                        isSelected: selectedGoals.contains(goal),
                        action: { toggleSelection(goal) }
                    )
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)

            Spacer()

            Button {
                viewModel.nextStep()
            } label: {
                Text("Continue")
                    .font(.chloeHeadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.chloePrimary)
                    .cornerRadius(Spacing.cornerRadius)
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.xl)
        }
    }

    private func toggleSelection(_ goal: PrimaryGoal) {
        var current = viewModel.preferences.primaryGoal ?? []
        if let index = current.firstIndex(of: goal) {
            current.remove(at: index)
        } else {
            current.append(goal)
        }
        viewModel.preferences.primaryGoal = current.isEmpty ? nil : current
    }
}

#Preview {
    PrimaryGoalView(viewModel: OnboardingViewModel())
}
