import SwiftUI

struct ChatInputBar: View {
    @Binding var text: String
    var onSend: () -> Void
    var onRecentsPressed: () -> Void = {}
    var onTakePhoto: () -> Void = {}
    var onUploadImage: () -> Void = {}
    var onPickFile: () -> Void = {}

    @State private var showAddSheet = false

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            // Plus button
            Button {
                showAddSheet = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(.chloeRosewood)
                    .frame(width: 44, height: 44)
            }

            // Text field
            TextField("", text: $text, axis: .vertical)
                .font(.chloeInputPlaceholder(16))
                .lineLimit(1...5)
                .placeholder(when: text.isBlank) {
                    Text("What's on your heart?")
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
                .fill(Color.clear)
        )
        .overlay(
            Capsule()
                .stroke(Color.chloeBorderWarm, lineWidth: 1)
        )
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.vertical, Spacing.xs)
        .background(Color.clear)
        .shadow(color: Color.chloePrimary.opacity(0.1), radius: 15, y: -5)
        .sheet(isPresented: $showAddSheet) {
            AddToChatSheet(
                onTakePhoto: onTakePhoto,
                onUploadImage: onUploadImage,
                onPickFile: onPickFile
            )
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
