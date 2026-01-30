import SwiftUI

struct CoreDesireView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private var selectedDesires: [CoreDesire] {
        viewModel.preferences.coreDesire ?? []
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Text("What do you desire most?")
                .font(.chloeTitle)
                .foregroundColor(.chloeTextPrimary)

            VStack(spacing: Spacing.xs) {
                ForEach(CoreDesire.allCases, id: \.self) { desire in
                    SelectionChip(
                        title: desire.rawValue.replacingOccurrences(of: "_", with: " ").capitalized,
                        isSelected: selectedDesires.contains(desire),
                        action: { toggleSelection(desire) }
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

    private func toggleSelection(_ desire: CoreDesire) {
        var current = viewModel.preferences.coreDesire ?? []
        if let index = current.firstIndex(of: desire) {
            current.remove(at: index)
        } else {
            current.append(desire)
        }
        viewModel.preferences.coreDesire = current.isEmpty ? nil : current
    }
}

#Preview {
    CoreDesireView(viewModel: OnboardingViewModel())
}
