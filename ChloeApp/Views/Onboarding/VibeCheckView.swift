import SwiftUI

struct VibeCheckView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var selectedVibe: VibeScore? = nil

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Text("How are you feeling today?")
                .font(.chloeTitle)
                .foregroundColor(.chloeTextPrimary)

            Text("Pick what resonates most")
                .font(.chloeBodyDefault)
                .foregroundColor(.chloeTextSecondary)

            VStack(spacing: Spacing.sm) {
                ForEach(VibeScore.allCases, id: \.self) { vibe in
                    SelectionChip(
                        title: vibeLabel(for: vibe),
                        isSelected: selectedVibe == vibe,
                        action: { selectedVibe = vibe }
                    )
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)

            Spacer()

            Button {
                viewModel.preferences.vibeScore = selectedVibe
                viewModel.nextStep()
            } label: {
                Text("Continue")
                    .font(.chloeHeadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(selectedVibe == nil ? Color.chloeAccentMuted : Color.chloePrimary)
                    .cornerRadius(Spacing.cornerRadius)
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.xl)
        }
    }

    private func vibeLabel(for vibe: VibeScore) -> String {
        switch vibe {
        case .low: return "Struggling a bit"
        case .medium: return "Doing okay"
        case .high: return "Feeling great"
        }
    }
}

#Preview {
    VibeCheckView(viewModel: OnboardingViewModel())
}
