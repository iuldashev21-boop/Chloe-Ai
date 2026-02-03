import SwiftUI

struct ReportSheet: View {
    let messageId: String
    let conversationId: String
    let userMessage: String
    let aiResponse: String
    let onDismiss: () -> Void
    let onReported: () -> Void

    @State private var selectedType: ReportType?
    @State private var otherText: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.md) {
                Text("What's wrong with this response?")
                    .font(.headline)
                    .padding(.top, Spacing.md)

                VStack(spacing: Spacing.sm) {
                    ForEach(ReportType.allCases, id: \.self) { type in
                        ReportOptionRow(
                            type: type,
                            isSelected: selectedType == type,
                            onTap: { selectedType = type }
                        )
                    }
                }
                .padding(.horizontal, Spacing.md)

                if selectedType == .other {
                    TextField("Please describe the issue...", text: $otherText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                        .padding(.horizontal, Spacing.md)
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, Spacing.md)
                }

                Spacer()

                Button {
                    submitReport()
                } label: {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Submit Report")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.chloePrimary)
                .disabled(selectedType == nil || isSubmitting)
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.lg)
            }
            .navigationTitle("Report Response")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func submitReport() {
        guard let type = selectedType else { return }

        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                try await FeedbackService.shared.submitReport(
                    messageId: messageId,
                    conversationId: conversationId,
                    userMessage: userMessage,
                    aiResponse: aiResponse,
                    reportType: type,
                    reportText: type == .other ? otherText : nil
                )
                await MainActor.run {
                    onReported()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to submit report. Please try again."
                    isSubmitting = false
                }
            }
        }
    }
}

struct ReportOptionRow: View {
    let type: ReportType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.displayName)
                        .font(.body)
                        .fontWeight(.medium)
                    Text(type.description)
                        .font(.caption)
                        .foregroundColor(.chloeTextSecondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .chloePrimary : .chloeTextTertiary)
            }
            .padding(Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.chloePrimaryLight : Color.chloeBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.chloePrimary : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(type.rawValue.capitalized)
    }
}

#Preview {
    ReportSheet(
        messageId: "test-123",
        conversationId: "conv-456",
        userMessage: "How do I feel better?",
        aiResponse: "Just cheer up!",
        onDismiss: {},
        onReported: {}
    )
}
