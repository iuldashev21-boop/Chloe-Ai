import SwiftUI

struct ChatInputBar: View {
    @Binding var text: String
    var onSend: () -> Void
    var onRecentsPressed: () -> Void = {}
    var onTakePhoto: () -> Void = {}
    var onUploadImage: () -> Void = {}
    var onVisionBoard: () -> Void = {}

    @State private var showBloomMenu = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Bloom menu floats above the plus button
            if showBloomMenu {
                PlusBloomMenu(
                    isPresented: $showBloomMenu,
                    onTakePhoto: onTakePhoto,
                    onUploadImage: onUploadImage,
                    onVisionBoard: onVisionBoard
                )
                .offset(x: Spacing.screenHorizontal + 16, y: -28)
                .zIndex(1)
            }

            // Main input capsule
            HStack(spacing: Spacing.xxs) {
                // Plus button
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        showBloomMenu.toggle()
                    }
                } label: {
                    Image(systemName: showBloomMenu ? "xmark" : "plus")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(.chloeRosewood)
                        .frame(width: 32, height: 32)
                        .contentTransition(.symbolEffect(.replace))
                }

                // Text field
                TextField("", text: $text, axis: .vertical)
                    .font(.chloeInputPlaceholder(16))
                    .lineLimit(1...5)
                    .placeholder(when: text.isEmpty) {
                        Text("Talk to Chloe...")
                            .font(.chloeInputPlaceholder(16))
                            .foregroundColor(.chloeTextTertiary)
                    }

                // Mic / Send button
                Button {
                    if !text.isBlank {
                        onSend()
                    }
                } label: {
                    Image(systemName: text.isBlank ? "mic" : "arrow.up.circle.fill")
                        .font(.system(size: text.isBlank ? 18 : 24, weight: .light))
                        .foregroundColor(text.isBlank ? .chloeTextTertiary : .chloePrimary)
                        .contentTransition(.symbolEffect(.replace))
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                Capsule()
                    .stroke(Color.chloeBorderWarm, lineWidth: 1)
            )
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.xs)
        }
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
        ChatInputBar(text: .constant(""), onSend: {})
        ChatInputBar(text: .constant("Hello"), onSend: {})
    }
    .background(Color.chloeBackground)
}
