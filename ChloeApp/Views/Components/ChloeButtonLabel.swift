import SwiftUI

struct ChloeButtonLabel: View {
    let title: String
    var isEnabled: Bool = true

    @State private var pulseOpacity: Double = 1.0
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        Text(title.uppercased())
            .font(.chloeButton)
            .tracking(3)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                ZStack {
                    Capsule().fill(.ultraThinMaterial)
                    Capsule().fill(Color.chloePrimary.opacity(isEnabled ? 0.8 : 0.45))
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.25), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: shimmerOffset)
                    .mask(Capsule())
                    // Inner glow — top edge catch light
                    VStack {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.35), .clear],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                            .frame(height: 1)
                            .padding(.horizontal, 1)
                        Spacer()
                    }
                    .clipShape(Capsule())
                }
            )
            .clipShape(Capsule())
            .shadow(color: Color(hex: "#B76E79").opacity(isEnabled ? 0.3 : 0.1), radius: 25, y: 12)
            .opacity(isEnabled ? 1.0 : pulseOpacity)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseOpacity)
            .onAppear {
                if !isEnabled {
                    pulseOpacity = 0.7
                }
                startShimmerLoop()
            }
            .onChange(of: isEnabled) { _, newValue in
                if newValue {
                    pulseOpacity = 1.0
                } else {
                    pulseOpacity = 0.7
                }
            }
    }

    private func startShimmerLoop() {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            shimmerOffset = -200
            withAnimation(.easeInOut(duration: 0.8)) {
                shimmerOffset = 200
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
