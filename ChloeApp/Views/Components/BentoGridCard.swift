import SwiftUI

struct BentoGridCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(Spacing.cardPadding)
            .chloeCardStyle()
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
