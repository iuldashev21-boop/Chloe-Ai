import SwiftUI

struct CoreDesireView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private var selectedDesires: [CoreDesire] {
        viewModel.preferences.coreDesire ?? []
    }

    private let descriptions: [CoreDesire: String] = [
        .marriage: "Building a forever partnership",
        .detachment: "Releasing what no longer serves you",
        .glowUp: "Becoming your most radiant self",
        .highValueDating: "Attracting with confidence and standards",
        .selfMastery: "Total command of your inner world",
    ]

    private let columns = [GridItem(.flexible(), spacing: Spacing.xs), GridItem(.flexible(), spacing: Spacing.xs)]

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            ChloeAvatar(size: 40)

            Text("What do you desire most?")
                .font(.chloeOnboardingQuestion)
                .foregroundColor(.chloeTextPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.screenHorizontal)

            LazyVGrid(columns: columns, spacing: Spacing.xs) {
                ForEach(CoreDesire.allCases, id: \.self) { desire in
                    OnboardingCard(
                        title: desire.rawValue.replacingOccurrences(of: "_", with: " ").capitalized,
                        description: descriptions[desire] ?? "",
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
                ChloeButtonLabel(title: "Continue", isEnabled: !selectedDesires.isEmpty)
            }
            .buttonStyle(PressableButtonStyle())
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
