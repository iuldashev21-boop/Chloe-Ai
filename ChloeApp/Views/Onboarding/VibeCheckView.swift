import SwiftUI

struct VibeCheckView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var selectedVibe: VibeScore? = nil

    private let vibeInfo: [(vibe: VibeScore, title: String, description: String)] = [
        (.low, "Struggling a bit", "Things feel heavy right now"),
        (.medium, "Doing okay", "Steady but room to grow"),
        (.high, "Feeling great", "Confident and in your power"),
    ]

    private let columns = [GridItem(.flexible(), spacing: Spacing.xs), GridItem(.flexible(), spacing: Spacing.xs)]

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            ChloeAvatar(size: 40)

            Text("How are you feeling today?")
                .font(.chloeOnboardingQuestion)
                .foregroundColor(.chloeTextPrimary)
                .multilineTextAlignment(.center)

            Text("Pick what resonates most")
                .font(.chloeCaption)
                .foregroundColor(.chloeTextSecondary)

            LazyVGrid(columns: columns, spacing: Spacing.xs) {
                ForEach(vibeInfo, id: \.vibe) { item in
                    OnboardingCard(
                        title: item.title,
                        description: item.description,
                        isSelected: selectedVibe == item.vibe,
                        action: { selectedVibe = item.vibe }
                    )
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)

            Spacer()

            Button {
                viewModel.preferences.vibeScore = selectedVibe
                viewModel.nextStep()
            } label: {
                ChloeButtonLabel(title: "Continue", isEnabled: selectedVibe != nil)
            }
            .buttonStyle(PressableButtonStyle())
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.xl)
        }
    }
}

#Preview {
    VibeCheckView(viewModel: OnboardingViewModel())
}
