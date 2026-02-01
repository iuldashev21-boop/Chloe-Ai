import SwiftUI

struct PlusBloomMenu: View {
    @Binding var isPresented: Bool
    var onTakePhoto: () -> Void
    var onUploadImage: () -> Void
    var onVisionBoard: () -> Void

    // Radial layout: 3 circles in a tight arc directly above the + button
    private let circleSize: CGFloat = 40
    private let radius: CGFloat = 46

    // Angles for the 3 circles (tight fan upward)
    private let angles: [Angle] = [
        .degrees(-155),  // upper-left
        .degrees(-110),  // upper-center
        .degrees(-65)    // upper-right
    ]

    var body: some View {
        ZStack {
            // Tap-outside dismissal — large enough to cover the screen
            if isPresented {
                Color.clear
                    .frame(width: 2000, height: 2000)
                    .contentShape(Rectangle())
                    .onTapGesture { dismiss() }
            }

            // Radial circle buttons
            ZStack {
                bloomCircle(icon: "camera", index: 0, action: onTakePhoto)
                bloomCircle(icon: "photo", index: 1, action: onUploadImage)
                bloomCircle(icon: "star", index: 2, action: onVisionBoard)
            }
        }
    }

    private func bloomCircle(icon: String, index: Int, action: @escaping () -> Void) -> some View {
        let angle = angles[index]
        let xOffset = isPresented ? radius * CGFloat(cos(angle.radians)) : 0
        let yOffset = isPresented ? radius * CGFloat(sin(angle.radians)) : 0

        return Button {
            dismiss()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .thin))
                .foregroundColor(.chloeRosewood)
                .frame(width: circleSize, height: circleSize)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    Circle()
                        .stroke(Color.chloeRosewood.opacity(0.4), lineWidth: 1)
                )
        }
        .offset(x: xOffset, y: yOffset)
        .scaleEffect(isPresented ? 1.0 : 0.3)
        .opacity(isPresented ? 1 : 0)
        .animation(
            .spring(response: 0.35, dampingFraction: 0.75)
                .delay(Double(index) * 0.05),
            value: isPresented
        )
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isPresented = false
        }
    }
}

#Preview {
    ZStack {
        Color.chloeBackground.ignoresSafeArea()
        VStack {
            Spacer()
            PlusBloomMenu(
                isPresented: .constant(true),
                onTakePhoto: {},
                onUploadImage: {},
                onVisionBoard: {}
            )
        }
    }
}
