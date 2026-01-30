import SwiftUI

struct DisclaimerText: View {
    var text: String = "Chloe is an AI companion, not a licensed therapist. If you're in crisis, please contact a professional."

    var body: some View {
        Text(text)
            .font(.chloeCaption)
            .foregroundColor(.chloeTextTertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Spacing.screenHorizontal)
    }
}

#Preview {
    DisclaimerText()
}
