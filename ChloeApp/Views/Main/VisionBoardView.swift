import SwiftUI

struct VisionBoardView: View {
    @StateObject private var viewModel = VisionBoardViewModel()
    @State private var showAddVision = false

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.sm),
        GridItem(.flexible(), spacing: Spacing.sm)
    ]

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            GradientBackground()

            if viewModel.items.isEmpty {
                emptyState
            } else {
                itemGrid
            }

            addButton
        }
        .navigationTitle("Vision Board")
        .toolbar(.visible, for: .navigationBar)
        .sheet(isPresented: $showAddVision) {
            AddVisionSheet { item in
                viewModel.addItem(item)
            }
        }
        .onAppear {
            viewModel.loadItems()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "star")
                .font(.system(size: 40, weight: .thin))
                .foregroundColor(.chloeTextTertiary)
                .accessibilityHidden(true)

            Text("Add your first vision")
                .font(.chloeBodyDefault)
                .foregroundColor(.chloeTextTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Item Grid

    private var itemGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: Spacing.sm) {
                ForEach(viewModel.items) { item in
                    visionCard(item)
                        .contextMenu {
                            Button(role: .destructive) {
                                viewModel.deleteItem(id: item.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.sm)
        }
    }

    // MARK: - Vision Card

    private func visionCard(_ item: VisionItem) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if let imagePath = item.imageUri,
               let image = UIImage(contentsOfFile: imagePath) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 120)
                    .clipped()
                    .cornerRadius(Spacing.cornerRadius)
            } else {
                RoundedRectangle(cornerRadius: Spacing.cornerRadius)
                    .fill(Color.chloePrimaryLight)
                    .frame(height: 120)
                    .overlay(
                        Image(systemName: item.category.icon)
                            .font(.system(size: 28, weight: .light))
                            .foregroundColor(.chloePrimary)
                    )
            }

            Text(item.title)
                .font(.chloeHeadline)
                .foregroundColor(.chloeTextPrimary)
                .lineLimit(2)

            Text(item.category.displayName)
                .font(.chloeCaption)
                .foregroundColor(.chloeTextTertiary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title), \(item.category.displayName)")
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(
            color: Color.chloeRosewood.opacity(0.12),
            radius: 16,
            x: 0,
            y: 6
        )
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            showAddVision = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .light))
                .foregroundColor(.chloePrimary)
                .frame(width: 52, height: 52)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(
                    color: Color.chloeRosewood.opacity(0.12),
                    radius: 8,
                    x: 0,
                    y: 3
                )
        }
        .accessibilityLabel("Add vision")
        .padding(.trailing, Spacing.screenHorizontal)
        .padding(.bottom, Spacing.lg)
    }
}

#Preview {
    NavigationStack {
        VisionBoardView()
    }
}
