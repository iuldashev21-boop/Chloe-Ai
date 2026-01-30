import Foundation
import SwiftUI

@MainActor
class JournalViewModel: ObservableObject {
    @Published var entries: [JournalEntry] = []
    @Published var isLoading = false

    func loadEntries() {
        entries = StorageService.shared.loadJournalEntries()
    }

    func addEntry(_ entry: JournalEntry) {
        entries.insert(entry, at: 0)
        try? StorageService.shared.saveJournalEntries(entries)
    }

    func deleteEntry(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        try? StorageService.shared.saveJournalEntries(entries)
    }
}
