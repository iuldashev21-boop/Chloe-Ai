import SwiftUI

struct TrinityPill: View {
    @Binding var text: String
    var onPlusPressed: () -> Void = {}
    var onHistoryPressed: () -> Void = {}
    var onMicPressed: () -> Void = {}
    var onSend: () -> Void = {}

    var body: some View {
        HStack(spacing: Spacing.xs) {
            // Left: Plus icon
            Button(action: onPlusPressed) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .thin))
                    .foregroundColor(.chloeRosewood)
                    .frame(width: 32, height: 32)
            }

            // Center: Text field
            TextField("", text: $text, axis: .vertical)
                .font(.custom("CormorantGaramond-Italic", size: 16))
                .lineLimit(1...3)
                .placeholder(when: text.isEmpty) {
                    Text("Talk to Chloe...")
                        .font(.custom("CormorantGaramond-Italic", size: 16))
                        .foregroundColor(.chloeTextTertiary)
                }

            // Right: History + Mic/Send
            Button(action: onHistoryPressed) {
                Image(systemName: "clock")
                    .font(.system(size: 18, weight: .thin))
                    .foregroundColor(.chloeTextTertiary)
                    .frame(width: 32, height: 32)
            }

            Button {
                if text.isBlank {
                    onMicPressed()
                } else {
                    onSend()
                }
            } label: {
                Image(systemName: text.isBlank ? "mic" : "arrow.up.circle.fill")
                    .font(.system(size: text.isBlank ? 18 : 24, weight: .thin))
                    .foregroundColor(text.isBlank ? .chloeTextTertiary : .chloePrimary)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, Spacing.sm)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.chloeBorderWarm, lineWidth: 1)
        )
        .padding(.horizontal, Spacing.screenHorizontal)
    }
}

// MARK: - Placeholder modifier

private extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: .leading) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    VStack {
        Spacer()
        TrinityPill(text: .constant(""))
        TrinityPill(text: .constant("Hello Chloe"))
    }
    .padding(.bottom, 20)
    .background(Color.chloeBackground)
}
