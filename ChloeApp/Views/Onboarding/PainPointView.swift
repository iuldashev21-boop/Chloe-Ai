import SwiftUI

struct PainPointView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private var selectedPoints: [PainPoint] {
        viewModel.preferences.painPoint ?? []
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Text("What's your biggest struggle?")
                .font(.chloeTitle)
                .foregroundColor(.chloeTextPrimary)

            VStack(spacing: Spacing.xs) {
                ForEach(PainPoint.allCases, id: \.self) { point in
                    SelectionChip(
                        title: point.rawValue.replacingOccurrences(of: "_", with: " ").capitalized,
                        isSelected: selectedPoints.contains(point),
                        action: { toggleSelection(point) }
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

    private func toggleSelection(_ point: PainPoint) {
        var current = viewModel.preferences.painPoint ?? []
        if let index = current.firstIndex(of: point) {
            current.remove(at: index)
        } else {
            current.append(point)
        }
        viewModel.preferences.painPoint = current.isEmpty ? nil : current
    }
}

#Preview {
    PainPointView(viewModel: OnboardingViewModel())
}
