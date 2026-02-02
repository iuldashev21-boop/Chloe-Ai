import Foundation
import SwiftUI

@MainActor
class AffirmationsViewModel: ObservableObject {
    @Published var affirmations: [Affirmation] = []
    @Published var isLoading = false

    func loadAffirmations() {
        affirmations = SyncDataService.shared.loadAffirmations()
    }

    func toggleSaved(id: String) {
        guard let index = affirmations.firstIndex(where: { $0.id == id }) else { return }
        affirmations[index].isSaved.toggle()
        try? SyncDataService.shared.saveAffirmations(affirmations)
    }
}
