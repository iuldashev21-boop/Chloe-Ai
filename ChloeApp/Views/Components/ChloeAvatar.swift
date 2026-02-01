import SwiftUI

struct ChloeAvatar: View {
    var size: CGFloat = 40
    var isThinking: Bool = false

    var body: some View {
        Group {
            if size >= Spacing.orbSize {
                ZStack {
                    LuminousOrb(size: size)
                    OrbStardustEmitter(isEmitting: isThinking, orbSize: size)
                }
            } else {
                Image("chloe-logo")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.chloeBorderWarm, lineWidth: 2)
                    )
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isThinking ? "Chloe is thinking" : "Chloe")
    }
}

#Preview {
    VStack(spacing: 32) {
        ChloeAvatar(size: 60)
        ChloeAvatar(size: Spacing.orbSizeSanctuary, isThinking: true)
    }
}
