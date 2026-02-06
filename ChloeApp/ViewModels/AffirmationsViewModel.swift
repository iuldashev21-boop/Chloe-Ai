import Foundation
import SwiftUI

@MainActor
class AffirmationsViewModel: ObservableObject {
    @Published var affirmations: [Affirmation] = []
    @Published var isLoading = false

    private let syncDataService: SyncDataServiceProtocol

    init(syncDataService: SyncDataServiceProtocol = SyncDataService.shared) {
        self.syncDataService = syncDataService
    }

    func loadAffirmations() {
        affirmations = syncDataService.loadAffirmations()
    }

    func toggleSaved(id: String) {
        guard let index = affirmations.firstIndex(where: { $0.id == id }) else { return }
        affirmations[index].isSaved.toggle()
        try? syncDataService.saveAffirmations(affirmations)
        let action = affirmations[index].isSaved ? "saved" : "unsaved"
        trackSignal("affirmations.toggled", parameters: ["action": action])
    }
}
