import Foundation
import SwiftUI

@MainActor
class GoalsViewModel: ObservableObject {
    @Published var goals: [Goal] = []
    @Published var isLoading = false
    @Published var saveError: String?

    func loadGoals() {
        goals = SyncDataService.shared.loadGoals()
    }

    func addGoal(_ goal: Goal) {
        goals.append(goal)
        persistGoals()
    }

    func deleteGoal(at offsets: IndexSet) {
        goals.remove(atOffsets: offsets)
        persistGoals()
    }

    func toggleGoalStatus(goalId: String) {
        guard let index = goals.firstIndex(where: { $0.id == goalId }) else { return }
        switch goals[index].status {
        case .active:
            goals[index].status = .completed
            goals[index].completedAt = Date()
        case .completed:
            goals[index].status = .active
            goals[index].completedAt = nil
        case .paused:
            goals[index].status = .active
            goals[index].completedAt = nil
        }
        goals[index].updatedAt = Date()  // Track status change for sync
        persistGoals()
    }

    private func persistGoals() {
        do {
            try SyncDataService.shared.saveGoals(goals)
            saveError = nil
        } catch {
            saveError = "Failed to save goals: \(error.localizedDescription)"
        }
    }
}
