import SwiftUI
import PhotosUI

struct AddVisionSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var selectedCategory: VisionCategory = .other
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var savedImagePath: String? = nil
    @State private var isProcessingImage = false

    var onAdd: (VisionItem) -> Void

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.chloeBackground.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: Spacing.lg) {
                        photoSection
                        titleSection
                        categorySection
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.xxl)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("New Vision")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.chloeBodyDefault)
                    .foregroundColor(.chloeTextSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Vision") {
                        saveVision()
                    }
                    .font(.chloeSubheadline)
                    .foregroundColor(canSave ? .chloePrimary : .chloeTextTertiary)
                    .disabled(!canSave)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Photo")
                .font(.chloeHeadline)
                .foregroundColor(.chloeTextPrimary)

            PhotosPicker(
                selection: $selectedPhotoItem,
                matching: .images
            ) {
                ZStack {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .clipped()
                            .cornerRadius(Spacing.cornerRadius)
                            .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
                    } else {
                        RoundedRectangle(cornerRadius: Spacing.cornerRadius)
                            .fill(Color.chloeSurface)
                            .frame(height: 180)
                            .overlay(
                                RoundedRectangle(cornerRadius: Spacing.cornerRadius)
                                    .strokeBorder(
                                        Color.chloeBorderWarm,
                                        style: StrokeStyle(lineWidth: 1.5, dash: [8, 6])
                                    )
                            )
                            .overlay(
                                VStack(spacing: Spacing.xs) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.chloePrimaryLight)
                                            .frame(width: 56, height: 56)

                                        Image(systemName: "photo.badge.plus")
                                            .font(.system(size: 22, weight: .light))
                                            .foregroundColor(.chloePrimary)
                                    }

                                    Text("Add a Photo")
                                        .font(.chloeSubheadline)
                                        .foregroundColor(.chloePrimary)

                                    Text("Optional")
                                        .font(.chloeCaption)
                                        .foregroundColor(.chloeTextTertiary)
                                }
                            )
                    }

                    if isProcessingImage {
                        Color.black.opacity(0.3)
                            .cornerRadius(Spacing.cornerRadius)
                        ProgressView()
                            .tint(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            .onChange(of: selectedPhotoItem) { _, newItem in
                handlePhotoSelection(newItem)
            }
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Title")
                .font(.chloeHeadline)
                .foregroundColor(.chloeTextPrimary)

            TextField("What's your vision?", text: $title)
                .font(.chloeBodyDefault)
                .foregroundColor(.chloeTextPrimary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.sm)
                .background(Color.chloeSurface)
                .cornerRadius(Spacing.cornerRadius)
                .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
        }
    }

    // MARK: - Category Section

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Category")
                .font(.chloeHeadline)
                .foregroundColor(.chloeTextPrimary)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: Spacing.xxs),
                    GridItem(.flexible(), spacing: Spacing.xxs),
                    GridItem(.flexible(), spacing: Spacing.xxs)
                ],
                spacing: Spacing.xxs
            ) {
                ForEach(VisionCategory.allCases, id: \.self) { category in
                    CategoryTile(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category
                        }
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func saveVision() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let item = VisionItem(
            title: trimmedTitle,
            category: selectedCategory
        )

        // If we saved an image, attach the path
        var finalItem = item
        if let path = savedImagePath {
            finalItem.imageUri = path
        }

        onAdd(finalItem)
        dismiss()
    }

    private func handlePhotoSelection(_ item: PhotosPickerItem?) {
        guard let item else { return }
        isProcessingImage = true

        Task {
            defer { isProcessingImage = false }

            guard let data = try? await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else { return }

            selectedImage = uiImage

            // Save to documents directory
            if let savedPath = saveImageToDocuments(data: data) {
                savedImagePath = savedPath
            }
        }
    }

    private func saveImageToDocuments(data: Data) -> String? {
        let filename = "vision_\(UUID().uuidString).jpg"
        guard let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else { return nil }

        let fileURL = documentsURL.appendingPathComponent(filename)
        do {
            try data.write(to: fileURL)
            return fileURL.path
        } catch {
            return nil
        }
    }
}

// MARK: - Category Tile

private struct CategoryTile: View {
    let category: VisionCategory
    let isSelected: Bool
    var action: () -> Void

    private var tileColor: Color {
        switch category {
        case .love: return Color(red: 1.0, green: 0.88, blue: 0.90)
        case .career: return Color(red: 1.0, green: 0.94, blue: 0.83)
        case .selfCare: return Color(red: 0.94, green: 0.88, blue: 1.0)
        case .travel: return Color(red: 0.87, green: 0.91, blue: 1.0)
        case .lifestyle: return Color(red: 0.87, green: 0.96, blue: 0.88)
        case .other: return Color(red: 0.96, green: 0.93, blue: 0.91)
        }
    }

    private var iconColor: Color {
        switch category {
        case .love: return Color(red: 0.83, green: 0.39, blue: 0.48)
        case .career: return Color(red: 0.77, green: 0.58, blue: 0.19)
        case .selfCare: return Color(red: 0.61, green: 0.42, blue: 0.77)
        case .travel: return Color(red: 0.36, green: 0.51, blue: 0.77)
        case .lifestyle: return Color(red: 0.36, green: 0.69, blue: 0.42)
        case .other: return Color(red: 0.65, green: 0.55, blue: 0.47)
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xxs) {
                ZStack {
                    Circle()
                        .fill(tileColor)
                        .frame(width: 44, height: 44)

                    Image(systemName: category.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(iconColor)
                }

                Text(category.displayName)
                    .font(.chloeCaption)
                    .foregroundColor(isSelected ? .chloePrimary : .chloeTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: Spacing.cornerRadius, style: .continuous)
                    .fill(isSelected ? Color.chloePrimaryLight : Color.chloeSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.cornerRadius, style: .continuous)
                    .stroke(
                        isSelected ? Color.chloePrimary.opacity(0.4) : Color.chloeBorderWarm,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AddVisionSheet { item in
        print("Added: \(item.title)")
    }
}
