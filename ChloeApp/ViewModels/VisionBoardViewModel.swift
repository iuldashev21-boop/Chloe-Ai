import Foundation
import SwiftUI

@MainActor
class VisionBoardViewModel: ObservableObject {
    @Published var items: [VisionItem] = []
    @Published var isLoading = false

    func loadItems() {
        items = StorageService.shared.loadVisionItems()
    }

    func addItem(_ item: VisionItem) {
        items.append(item)
        try? StorageService.shared.saveVisionItems(items)
    }

    func deleteItem(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        try? StorageService.shared.saveVisionItems(items)
    }
}
