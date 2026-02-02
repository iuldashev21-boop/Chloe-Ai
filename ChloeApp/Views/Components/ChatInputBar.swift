import SwiftUI

struct ChatInputBar: View {
    @Binding var text: String
    @Binding var pendingImage: UIImage?
    var onSend: () -> Void
    var onRecentsPressed: () -> Void = {}
    var onTakePhoto: () -> Void = {}
    var onUploadImage: () -> Void = {}
    var onPickFile: () -> Void = {}

    @State private var showAddSheet = false

    private var canSend: Bool {
        !text.isBlank || pendingImage != nil
    }

    var body: some View {
        VStack(spacing: Spacing.xxxs) {
            // Image preview thumbnail
            if let image = pendingImage {
                HStack {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.chloeBorderWarm, lineWidth: 0.5)
                            )

                        Button {
                            withAnimation(.easeOut(duration: 0.2)) {
                                pendingImage = nil
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.white, Color.chloeTextTertiary)
                        }
                        .offset(x: 6, y: -6)
                    }
                    Spacer()
                }
                .padding(.horizontal, Spacing.sm)
                .transition(.scale.combined(with: .opacity))
            }

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
                    if canSend {
                        onSend()
                    }
                } label: {
                    Image(systemName: canSend ? "arrow.up.circle.fill" : "mic")
                        .font(.system(size: canSend ? 24 : 18, weight: .light))
                        .foregroundColor(canSend ? .chloePrimary : .chloeTextTertiary)
                        .contentTransition(.symbolEffect(.replace))
                }
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
        ChatInputBar(text: .constant(""), pendingImage: .constant(nil), onSend: {})
        ChatInputBar(text: .constant("Hello"), pendingImage: .constant(nil), onSend: {})
    }
    .background(Color.chloeBackground)
}
