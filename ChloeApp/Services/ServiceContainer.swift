import SwiftUI

/// Centralized dependency injection container for all app services.
/// Defaults to production singletons; pass mock implementations for testing.
@MainActor
class ServiceContainer: ObservableObject {
    let storage: StorageServiceProtocol
    let gemini: GeminiServiceProtocol
    let safety: SafetyServiceProtocol
    let sync: SyncDataServiceProtocol
    let archetype: ArchetypeServiceProtocol
    let auth: AuthServiceProtocol

    init(
        storage: StorageServiceProtocol = StorageService.shared,
        gemini: GeminiServiceProtocol = GeminiService.shared,
        safety: SafetyServiceProtocol = SafetyService.shared,
        sync: SyncDataServiceProtocol = SyncDataService.shared,
        archetype: ArchetypeServiceProtocol = ArchetypeService.shared,
        auth: AuthServiceProtocol = AuthService.shared
    ) {
        self.storage = storage
        self.gemini = gemini
        self.safety = safety
        self.sync = sync
        self.archetype = archetype
        self.auth = auth
    }
}
