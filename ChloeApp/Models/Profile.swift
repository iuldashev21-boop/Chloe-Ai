import Foundation

struct Profile: Codable, Identifiable {
    let id: String
    var email: String
    var displayName: String
    var onboardingComplete: Bool
    var preferences: OnboardingPreferences?
    var subscriptionTier: SubscriptionTier
    var subscriptionExpiresAt: Date?
    var profileImageUri: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        email: String = "",
        displayName: String = "",
        onboardingComplete: Bool = false,
        preferences: OnboardingPreferences? = nil,
        subscriptionTier: SubscriptionTier = .free,
        subscriptionExpiresAt: Date? = nil,
        profileImageUri: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.onboardingComplete = onboardingComplete
        self.preferences = preferences
        self.subscriptionTier = subscriptionTier
        self.subscriptionExpiresAt = subscriptionExpiresAt
        self.profileImageUri = profileImageUri
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum SubscriptionTier: String, Codable {
    case free
    case premium
}

struct UserFact: Codable, Identifiable {
    let id: String
    var userId: String?
    var fact: String
    var category: FactCategory
    var sourceMessageId: String?
    var isActive: Bool
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String? = nil,
        fact: String,
        category: FactCategory,
        sourceMessageId: String? = nil,
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.fact = fact
        self.category = category
        self.sourceMessageId = sourceMessageId
        self.isActive = isActive
        self.createdAt = createdAt
    }
}

enum FactCategory: String, Codable {
    case relationship
    case preference
    case lifeEvent = "life_event"
    case personality
    case goal
}
