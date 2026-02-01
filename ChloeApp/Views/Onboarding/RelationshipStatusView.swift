import SwiftUI

struct RelationshipStatusView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private var selectedStatuses: [RelationshipStatus] {
        viewModel.preferences.relationshipStatus ?? []
    }

    private let descriptions: [RelationshipStatus: String] = [
        .singleExploring: "Open to possibilities and self-discovery",
        .datingNew: "Navigating the early butterflies",
        .inRelationship: "Growing deeper with your person",
        .complicated: "Figuring out mixed signals",
        .breakupRecovery: "Healing and rebuilding yourself",
        .happilyTaken: "Committed and thriving together",
    ]

    private let columns = [GridItem(.flexible(), spacing: Spacing.xs), GridItem(.flexible(), spacing: Spacing.xs)]

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            ChloeAvatar(size: 40)

            Text("What's your relationship status?")
                .font(.chloeOnboardingQuestion)
                .foregroundColor(.chloeTextPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.screenHorizontal)

            LazyVGrid(columns: columns, spacing: Spacing.xs) {
                ForEach(RelationshipStatus.allCases, id: \.self) { status in
                    OnboardingCard(
                        title: status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized,
                        description: descriptions[status] ?? "",
                        isSelected: selectedStatuses.contains(status),
                        action: { toggleSelection(status) }
                    )
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)

            Spacer()

            Button {
                viewModel.nextStep()
            } label: {
                ChloeButtonLabel(title: "Continue", isEnabled: !selectedStatuses.isEmpty)
            }
            .buttonStyle(PressableButtonStyle())
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.xl)
        }
    }

    private func toggleSelection(_ status: RelationshipStatus) {
        var current = viewModel.preferences.relationshipStatus ?? []
        if let index = current.firstIndex(of: status) {
            current.remove(at: index)
        } else {
            current.append(status)
        }
        viewModel.preferences.relationshipStatus = current.isEmpty ? nil : current
    }
}

#Preview {
    RelationshipStatusView(viewModel: OnboardingViewModel())
}
