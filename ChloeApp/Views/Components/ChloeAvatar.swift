import SwiftUI

struct ChloeAvatar: View {
    var size: CGFloat = 40

    var body: some View {
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

#Preview {
    ChloeAvatar(size: 60)
}
