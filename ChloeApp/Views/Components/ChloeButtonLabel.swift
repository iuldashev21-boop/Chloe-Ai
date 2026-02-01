import SwiftUI

struct ChloeButtonLabel: View {
    let title: String
    var isEnabled: Bool = true

    @State private var pulseOpacity: Double = 1.0

    var body: some View {
        Text(title.uppercased())
            .font(.chloeButton)
            .tracking(3)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(Color.chloePrimary.opacity(isEnabled ? 1.0 : 0.45))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
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
    VStack(spacing: 20) {
        ChloeButtonLabel(title: "Continue", isEnabled: true)
        ChloeButtonLabel(title: "Waiting...", isEnabled: false)
    }
    .padding()
}
