import Foundation
import SwiftUI

@MainActor
class VisionBoardViewModel: ObservableObject {
    @Published var items: [VisionItem] = []
    @Published var isLoading = false
    @Published var saveError: String?

    func loadItems() {
        items = SyncDataService.shared.loadVisionItems()
    }

    func addItem(_ item: VisionItem) {
        items.append(item)
        persistItems()
    }

    func deleteItem(at offsets: IndexSet) {
        for index in offsets {
            cleanupImageFile(for: items[index])
        }
        items.remove(atOffsets: offsets)
        persistItems()
    }

    func deleteItem(id: String) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        cleanupImageFile(for: items[index])
        items.remove(at: index)
        persistItems()
    }

    func updateItem(_ updated: VisionItem) {
        guard let index = items.firstIndex(where: { $0.id == updated.id }) else { return }
        // Clean up old image if it changed
        if items[index].imageUri != updated.imageUri {
            cleanupImageFile(for: items[index])
        }
        items[index] = updated
        persistItems()
    }

    private func cleanupImageFile(for item: VisionItem) {
        guard let imagePath = item.imageUri else { return }
        let url = URL(fileURLWithPath: imagePath)
        try? FileManager.default.removeItem(at: url)
    }

    private func persistItems() {
        do {
            try SyncDataService.shared.saveVisionItems(items)
            saveError = nil
        } catch {
            saveError = "Failed to save vision items: \(error.localizedDescription)"
        }
    }
}
