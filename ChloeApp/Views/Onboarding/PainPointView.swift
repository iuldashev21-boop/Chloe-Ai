import SwiftUI

struct PainPointView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private var selectedPoints: [PainPoint] {
        viewModel.preferences.painPoint ?? []
    }

    private let descriptions: [PainPoint: String] = [
        .anxiousAttachment: "Overthinking and needing reassurance",
        .peoplePleasing: "Putting everyone else first",
        .lowSelfWorth: "Struggling to see your own value",
        .fearOfAbandonment: "Worrying they'll leave",
        .codependency: "Losing yourself in relationships",
        .settling: "Accepting less than you deserve",
    ]

    private let columns = [GridItem(.flexible(), spacing: Spacing.xs), GridItem(.flexible(), spacing: Spacing.xs)]

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            ChloeAvatar(size: 40)

            Text("What's your biggest struggle?")
                .font(.chloeOnboardingQuestion)
                .foregroundColor(.chloeTextPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.screenHorizontal)

            LazyVGrid(columns: columns, spacing: Spacing.xs) {
                ForEach(PainPoint.allCases, id: \.self) { point in
                    OnboardingCard(
                        title: point.rawValue.replacingOccurrences(of: "_", with: " ").capitalized,
                        description: descriptions[point] ?? "",
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
                ChloeButtonLabel(title: "Continue", isEnabled: !selectedPoints.isEmpty)
            }
            .buttonStyle(PressableButtonStyle())
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
