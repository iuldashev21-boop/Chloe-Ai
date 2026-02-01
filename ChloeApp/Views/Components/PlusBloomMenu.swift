import SwiftUI

struct AddToChatSheet: View {
    var onTakePhoto: () -> Void
    var onUploadImage: () -> Void
    var onPickFile: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Header
            ZStack {
                Text("Add to Chat")
                    .font(.chloeBodyDefault)
                    .foregroundColor(.chloeTextPrimary)

                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.chloeTextSecondary)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.chloeTextTertiary.opacity(0.12)))
                    }
                    .accessibilityLabel("Close")

                    Spacer()
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)

            // Cards
            HStack(spacing: Spacing.sm) {
                cardButton(icon: "camera", label: "Camera") {
                    dismiss()
                    onTakePhoto()
                }

                cardButton(icon: "photo", label: "Photos") {
                    dismiss()
                    onUploadImage()
                }

                cardButton(icon: "doc", label: "Files") {
                    dismiss()
                    onPickFile()
                }
            }
            .padding(.horizontal, Spacing.md)

            Spacer()
        }
        .background(Color.chloeBackground)
        .presentationDetents([.height(220)])
        .presentationDragIndicator(.visible)
    }

    private func cardButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.chloeRosewood)

                Text(label)
                    .font(.chloeCaption)
                    .foregroundColor(.chloeTextPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 90)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.chloeBorderWarm, lineWidth: 1)
            )
        }
    }
}

#Preview {
    Color.chloeBackground.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            AddToChatSheet(
                onTakePhoto: {},
                onUploadImage: {},
                onPickFile: {}
            )
        }
}
