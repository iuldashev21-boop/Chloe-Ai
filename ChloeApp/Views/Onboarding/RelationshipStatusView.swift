import SwiftUI

struct RelationshipStatusView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private var selectedStatuses: [RelationshipStatus] {
        viewModel.preferences.relationshipStatus ?? []
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Text("What's your relationship status?")
                .font(.chloeTitle)
                .foregroundColor(.chloeTextPrimary)
                .multilineTextAlignment(.center)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.xs) {
                ForEach(RelationshipStatus.allCases, id: \.self) { status in
                    SelectionChip(
                        title: status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized,
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
                Text("Continue")
                    .font(.chloeHeadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(selectedStatuses.isEmpty ? Color.chloeAccentMuted : Color.chloePrimary)
                    .cornerRadius(Spacing.cornerRadius)
            }
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
