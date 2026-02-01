import SwiftUI

struct ChloeButtonLabel: View {
    let title: String
    var isEnabled: Bool = true

    @State private var pulseOpacity: Double = 1.0

    var body: some View {
        Text(title)
            .font(.system(size: 15, weight: .medium))
            .tracking(2)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(
                ZStack {
                    Capsule().fill(.ultraThinMaterial)
                    Capsule().fill(Color(hex: "#B76E79").opacity(isEnabled ? 0.2 : 0.1))
                }
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.4), lineWidth: 0.5)
            )
            .shadow(color: Color(hex: "#B76E79").opacity(0.2), radius: 20)
            .opacity(isEnabled ? 1.0 : pulseOpacity)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseOpacity)
            .onAppear {
                if !isEnabled {
                    pulseOpacity = 0.7
                }
            }
            .onChange(of: isEnabled) { _, newValue in
                if newValue {
                    pulseOpacity = 1.0
                } else {
                    pulseOpacity = 0.7
                }
            }
    }
}

#Preview {
    ZStack {
        Color.chloeBackground.ignoresSafeArea()
        VStack(spacing: 20) {
            ChloeButtonLabel(title: "Begin My Journey", isEnabled: true)
            ChloeButtonLabel(title: "Continue", isEnabled: false)
        }
        .padding()
    }
}
