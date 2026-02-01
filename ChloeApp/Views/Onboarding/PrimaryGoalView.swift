import SwiftUI

struct PrimaryGoalView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private var selectedGoals: [PrimaryGoal] {
        viewModel.preferences.primaryGoal ?? []
    }

    private let descriptions: [PrimaryGoal: String] = [
        .findingPerson: "Attracting your ideal match",
        .understandingMen: "Decoding what he really means",
        .buildingConfidence: "Becoming unshakably self-assured",
        .healingBreakup: "Turning heartbreak into growth",
        .improvingRelationship: "Deepening your current connection",
        .feminineEnergy: "Embracing softness as your power",
    ]

    private let columns = [GridItem(.flexible(), spacing: Spacing.xs), GridItem(.flexible(), spacing: Spacing.xs)]

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            ChloeAvatar(size: 40)

            Text("What's your primary goal?")
                .font(.chloeOnboardingQuestion)
                .foregroundColor(.chloeTextPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.screenHorizontal)

            LazyVGrid(columns: columns, spacing: Spacing.xs) {
                ForEach(PrimaryGoal.allCases, id: \.self) { goal in
                    OnboardingCard(
                        title: goal.rawValue.replacingOccurrences(of: "_", with: " ").capitalized,
                        description: descriptions[goal] ?? "",
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
                ChloeButtonLabel(title: "Continue", isEnabled: !selectedGoals.isEmpty)
            }
            .buttonStyle(PressableButtonStyle())
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
