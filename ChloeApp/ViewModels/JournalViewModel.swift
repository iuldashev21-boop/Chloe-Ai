import Foundation
import SwiftUI

@MainActor
class JournalViewModel: ObservableObject {
    @Published var entries: [JournalEntry] = []
    @Published var isLoading = false
    @Published var saveError: String?

    init() {
        entries = StorageService.shared.loadJournalEntries()
    }

    func loadEntries() {
        entries = StorageService.shared.loadJournalEntries()
    }

    func addEntry(_ entry: JournalEntry) {
        entries.insert(entry, at: 0)
        persistEntries()
        StreakService.shared.recordActivity(source: .journal)
    }

    func deleteEntry(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        persistEntries()
    }

    private func persistEntries() {
        do {
            try StorageService.shared.saveJournalEntries(entries)
            saveError = nil
        } catch {
            saveError = "Failed to save journal: \(error.localizedDescription)"
        }
    }
}
