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

    /// Convenience init using all production singletons.
    /// Avoids referencing @MainActor-isolated `AuthService.shared` in a default parameter
    /// expression (which is evaluated in the caller's nonisolated context in Swift 6).
    convenience init() {
        self.init(
            storage: StorageService.shared,
            gemini: GeminiService.shared,
            safety: SafetyService.shared,
            sync: SyncDataService.shared,
            archetype: ArchetypeService.shared,
            auth: AuthService.shared
        )
    }

    init(
        storage: StorageServiceProtocol,
        gemini: GeminiServiceProtocol,
        safety: SafetyServiceProtocol,
        sync: SyncDataServiceProtocol,
        archetype: ArchetypeServiceProtocol,
        auth: AuthServiceProtocol
    ) {
        self.storage = storage
        self.gemini = gemini
        self.safety = safety
        self.sync = sync
        self.archetype = archetype
        self.auth = auth
    }
}
