import SwiftUI

struct BentoGridCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(Spacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(
                color: Color.chloeRosewood.opacity(0.12),
                radius: 16,
                x: 0,
                y: 6
            )
    }
}

#Preview {
    ZStack {
        Color.chloeBackground.ignoresSafeArea()
        VStack(spacing: Spacing.sm) {
            BentoGridCard {
                HStack {
                    Image(systemName: "book")
                        .foregroundColor(.chloePrimary)
                    Text("Journaling")
                        .font(.chloeHeadline)
                        .foregroundColor(.chloeTextPrimary)
                    Spacer()
                }
            }
            BentoGridCard {
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(.chloePrimary)
                    Text("Goals")
                        .font(.chloeHeadline)
                        .foregroundColor(.chloeTextPrimary)
                    Spacer()
                }
            }
            BentoGridCard {
                HStack {
                    Image(systemName: "eye")
                        .foregroundColor(.chloePrimary)
                    Text("Vision Board")
                        .font(.chloeHeadline)
                        .foregroundColor(.chloeTextPrimary)
                    Spacer()
                }
            }
        }
        .padding(.horizontal, Spacing.screenHorizontal)
    }
}
