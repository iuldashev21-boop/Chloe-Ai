# ChloeApp — UI/UX Agent Context

## Project Background

ChloeApp is a native iOS app (Swift/SwiftUI, iOS 17+) — a feminine energy coaching companion powered by Gemini AI. Originally prototyped as an Expo/React Native web app, it was pivoted to native iOS. The backend logic (models, services, prompts, safety, archetype classification, API calls) is fully implemented. The app builds and runs.

**What's left:** 5 of 8 main views are "Coming soon" stubs, plus the ArchetypeQuizView in onboarding needs to be built. The backend is ready — we need UI.

---

## Current State

### Done
- All Models (Profile, Message, Conversation, JournalEntry, VisionItem, Goal, Affirmation, Archetype, OnboardingPreferences, TopicCard, DailyUsage)
- All Services (GeminiService, StorageService, SafetyService, ArchetypeService, AnalystService)
- All ViewModels (Auth, Chat, Onboarding, Journal, Goals, VisionBoard, Affirmations)
- Theme system (Colors, Fonts, Spacing)
- Reusable components (SelectionChip, ChloeAvatar, GradientBackground, ChatBubble, ChatInputBar, TypingIndicator, DisclaimerText)
- Working views: WelcomeView, EmailLoginView, ContentView (root routing), OnboardingContainerView, all onboarding steps except ArchetypeQuizView, ChatView, MainTabView, SettingsView (minimal)
- Constants/Prompts (system prompt, affirmation template, analyst prompt, topic cards, label maps)

### Stubs (need full UI)
1. `ArchetypeQuizView.swift` — onboarding step 6 (has placeholder "Coming soon")
2. `HomeView.swift` — main landing screen (has placeholder)
3. `AffirmationsView.swift` — AI affirmation list (has placeholder)
4. `JournalView.swift` — journal entries list (has placeholder)
5. `GoalsView.swift` — goal tracking (has placeholder)
6. `VisionBoardView.swift` — vision board grid (has placeholder)
7. `ProfileView.swift` — user profile + stats (has placeholder)
8. `SettingsView.swift` — minimal, only has Sign Out button

---

## Design System Reference

### Colors (hex values)
```
chloeBackground     = #FFF5F0   (Soft beige)
chloeSurface        = #FAFAFA   (Off-white)
chloePrimary        = #A25B66   (Dusty rose)
chloePrimaryLight   = #FFF0EB   (Light pink)
chloePrimaryDark    = #8A4A55   (Dark rose)
chloeAccent         = #F4A896   (Peachy rose)
chloeAccentMuted    = #E8B4A8   (Muted peachy)
chloeTextPrimary    = #1A1A1A   (Dark gray)
chloeTextSecondary  = #6B6B6B   (Medium gray)
chloeTextTertiary   = #9A9A9A   (Light gray)
chloeBorder         = #E5E5E5   (Light border)
chloeBorderWarm     = #F0E0DA   (Warm border)
chloeUserBubble     = #F0F0F0   (Chat user bubble)
chloeGradientStart  = #FFF8F5   (Gradient start)
chloeGradientEnd    = #FEEAE2   (Gradient end)
```

### Fonts
```
Heading: PlayfairDisplay-Regular, PlayfairDisplay-Medium
Body:    Inter-Regular, Inter-Medium

Named Styles:
  .chloeLargeTitle    — 28pt PlayfairDisplay-Medium
  .chloeTitle         — 22pt PlayfairDisplay-Medium
  .chloeTitle2        — 20pt PlayfairDisplay-Regular
  .chloeHeadline      — 17pt Inter-Medium
  .chloeSubheadline   — 15pt Inter-Medium
  .chloeBodyDefault   — 16pt Inter-Regular
  .chloeCaption       — 13pt Inter-Regular
```

### Spacing Constants
```swift
enum Spacing {
    static let xxxs: CGFloat = 4
    static let xxs: CGFloat = 8
    static let xs: CGFloat = 12
    static let sm: CGFloat = 16
    static let md: CGFloat = 20
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 40
    static let xxxl: CGFloat = 48
    static let huge: CGFloat = 64
    static let screenHorizontal: CGFloat = 20
    static let cardPadding: CGFloat = 16
    static let cornerRadius: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 20
}
```

---

## Reusable Components Catalog

### SelectionChip
```swift
struct SelectionChip: View {
    let title: String
    let isSelected: Bool
    var action: () -> Void
}
// Selected: chloePrimary bg, white text
// Unselected: chloePrimaryLight bg, chloePrimary text, faint border
// Corner radius: cornerRadiusLarge (20pt)
```

### ChloeAvatar
```swift
struct ChloeAvatar: View {
    var size: CGFloat = 40
}
// Image: "chloe-logo", circular, 2pt chloeBorderWarm border
```

### GradientBackground
```swift
struct GradientBackground: View
// LinearGradient: chloeGradientStart → chloeGradientEnd (top→bottom), ignores safe area
// Also available as: .chloeBackground() view modifier
```

### ChatBubble
```swift
struct ChatBubble: View {
    let message: Message
}
// User: chloeUserBubble bg, right-aligned
// Chloe: chloePrimaryLight bg, left-aligned
```

### ChatInputBar
```swift
struct ChatInputBar: View {
    @Binding var text: String
    var onSend: () -> Void
}
```

### TypingIndicator
```swift
struct TypingIndicator: View
// 3 animated dots, chloeAccentMuted color, chloePrimaryLight bg
```

### DisclaimerText
```swift
struct DisclaimerText: View {
    var text: String = "Chloe is an AI companion, not a licensed therapist..."
}
```

---

## Data Models (field listings)

### Profile
```swift
struct Profile: Codable, Identifiable {
    let id: String                         // UUID
    var email: String
    var displayName: String
    var onboardingComplete: Bool
    var preferences: OnboardingPreferences?
    var subscriptionTier: SubscriptionTier // .free | .premium
    var subscriptionExpiresAt: Date?
    var profileImageUri: String?
    var createdAt: Date
    var updatedAt: Date
}
```

### OnboardingPreferences
```swift
struct OnboardingPreferences: Codable {
    var onboardingCompleted: Bool
    var name: String?
    var relationshipStatus: [RelationshipStatus]?
    var primaryGoal: [PrimaryGoal]?
    var coreDesire: [CoreDesire]?
    var painPoint: [PainPoint]?
    var vibeScore: VibeScore?
    var archetypeAnswers: ArchetypeAnswers?
}

struct ArchetypeAnswers: Codable {
    var energy: ArchetypeChoice?
    var strength: ArchetypeChoice?
    var recharge: ArchetypeChoice?
    var allure: ArchetypeChoice?
}

enum ArchetypeChoice: String, Codable, CaseIterable { case a, b, c, d }
```

### Message
```swift
struct Message: Codable, Identifiable {
    let id: String
    var conversationId: String?
    var role: MessageRole       // .user | .chloe
    var text: String
    var imageUri: String?
    var createdAt: Date
}
```

### JournalEntry
```swift
struct JournalEntry: Codable, Identifiable {
    let id: String
    var userId: String?
    var title: String
    var content: String
    var mood: String            // Free-form string (will add JournalMood enum)
    var createdAt: Date
}
```

### Goal
```swift
struct Goal: Codable, Identifiable {
    let id: String
    var userId: String?
    var title: String
    var description: String?
    var status: GoalStatus      // .active | .completed | .paused
    var createdAt: Date
    var completedAt: Date?
}
```

### VisionItem
```swift
struct VisionItem: Codable, Identifiable {
    let id: String
    var userId: String?
    var imageUri: String?
    var title: String
    var category: VisionCategory // .love | .career | .selfCare | .travel | .lifestyle | .other
    var createdAt: Date
    var updatedAt: Date
}
```

### Affirmation
```swift
struct Affirmation: Codable, Identifiable {
    let id: String
    var userId: String?
    var text: String
    var date: String            // "YYYY-MM-DD"
    var isSaved: Bool
    var createdAt: Date
}
```

### UserArchetype
```swift
struct UserArchetype: Codable {
    var primary: ArchetypeId    // .siren | .queen | .muse | .lover | .sage | .rebel | .warrior
    var secondary: ArchetypeId
    var label: String           // "The Siren"
    var blend: String           // "Siren-Lover"
    var description: String
}
```

### TopicCardConfig
```swift
struct TopicCardConfig: Codable {
    var id: String
    var title: String
    var subtitle: String
    var icon: String            // SF Symbol name
    var color: TopicCardColor   // .pink | .gold | .purple
    var prompt: String
}
```

---

## Navigation Structure

### MainTabView
Uses `NavigationSplitView` with sidebar (`.detailOnly` on phone). Sidebar items defined by `SidebarItem` enum:

```swift
enum SidebarItem: String, CaseIterable, Identifiable {
    case home = "Home"              // icon: "house"
    case chat = "Chat"              // icon: "bubble.left.and.bubble.right"
    case journal = "Journal"        // icon: "book"
    case visionBoard = "Vision Board" // icon: "photo.on.rectangle"
    case affirmations = "Affirmations" // icon: "sparkles"
    case goals = "Goals"            // icon: "target"
    case settings = "Settings"      // icon: "gearshape"
    case profile = "Profile"        // icon: "person.circle"
}
```

The `detailView(for:)` method switches on the item to show the corresponding view.

### ContentView (Root Routing)
```
!isAuthenticated → WelcomeView
isAuthenticated && !onboardingComplete → OnboardingContainerView
Both true → MainTabView
```

### Onboarding Flow (8 steps)
0: NameStepView, 1: RelationshipStatusView, 2: PrimaryGoalView, 3: CoreDesireView, 4: PainPointView, 5: VibeCheckView, 6: ArchetypeQuizView, 7: OnboardingCompleteView

---

## Design Conventions & Patterns

1. **Every view**: `GradientBackground()` as ZStack base
2. **Fonts**: Use `.chloeTitle`, `.chloeHeadline`, `.chloeBodyDefault`, `.chloeCaption` etc.
3. **Colors**: Use `.chloePrimary`, `.chloeTextPrimary/.Secondary/.Tertiary`, `.chloeSurface`, `.chloeBorder`
4. **Spacing**: Use `Spacing.screenHorizontal`, `.cardPadding`, `.cornerRadius`
5. **Cards**: `.chloeSurface` background + `.chloeBorder` stroke + `Spacing.cornerRadius`
6. **Filters/Selection**: Use `SelectionChip` component
7. **ViewModels**: `@MainActor` on all ViewModels
8. **Previews**: `#Preview` blocks on every view
9. **Onboarding views**: `@ObservedObject var viewModel: OnboardingViewModel`, vertical layout, SelectionChip answers, "Continue" button calling `viewModel.nextStep()`

---

## Views to Implement (8 total)

### 1. ArchetypeQuizView (Onboarding Step 6)
- **File:** `ChloeApp/Views/Onboarding/ArchetypeQuizView.swift`
- 4 questions (energy, strength, recharge, allure), each with 4 answer choices (a/b/c/d)
- Step through one at a time with "Continue" button
- Store answers in `viewModel.preferences.archetypeAnswers`
- On final answer, call `viewModel.nextStep()`
- Use card-style vertical answer options (not SelectionChip — use full-width tappable cards)

### 2. HomeView (First screen after onboarding)
- **File:** `ChloeApp/Views/Main/HomeView.swift`
- **New component:** `ChloeApp/Views/Components/TopicCardView.swift`
- Greeting: "Hey, {name}!" with time-of-day subtitle + ChloeAvatar
- Quick chat card: tappable card navigating to ChatView
- Topic cards: horizontal scroll of 3 cards from `topicCards` constant
- Daily affirmation card (generated once per day via GeminiService, cached in UserDefaults by date key)
- Current vibe pill (if available from StorageService)

### 3. AffirmationsView
- **File:** `ChloeApp/Views/Main/AffirmationsView.swift`
- **Modify:** `ChloeApp/ViewModels/AffirmationsViewModel.swift` — add `generateNewAffirmation()` method
- Filter toggle: All / Saved (using SelectionChip)
- List of affirmation cards (text + date + heart toggle for save)
- Toolbar sparkles button to generate new affirmation via Gemini API
- Empty state with prompt to generate first affirmation

### 4. JournalView
- **File:** `ChloeApp/Views/Main/JournalView.swift`
- **New files:** `JournalEntryEditorView.swift` (sheet), `JournalDetailView.swift` (read-only)
- **Modify:** `ChloeApp/Models/JournalEntry.swift` — add `JournalMood` enum
- List of entries with mood emoji, title, date
- Swipe-to-delete
- "+" toolbar button opens editor sheet
- Editor: mood selector (horizontal scroll of mood chips), title field, content TextEditor
- Detail view: full entry display
- 8 moods: Happy 😊, Calm 😌, Anxious 😰, Sad 😢, Angry 😠, Hopeful 🌱, Confident 💪, Grateful 🙏

### 5. GoalsView
- **File:** `ChloeApp/Views/Main/GoalsView.swift`
- **Modify:** `ChloeApp/ViewModels/GoalsViewModel.swift` — add `deleteGoal()` method
- Status filter bar: Active / Completed / Paused / All (SelectionChips)
- Goal rows with status circle (tap to toggle), title, description snippet
- Swipe actions for delete
- "+" toolbar button opens add-goal sheet (title + optional description)
- Status badges with distinct colors

### 6. VisionBoardView
- **File:** `ChloeApp/Views/Main/VisionBoardView.swift`
- **New file:** `ChloeApp/Views/Main/AddVisionSheet.swift`
- **Modify:** `ChloeApp/Models/VisionItem.swift` — add `displayName` and `icon` extensions on VisionCategory
- Category filter: horizontal scroll of chips (All + 6 categories)
- 2-column LazyVGrid of vision cards
- Cards: gradient placeholder, title overlay, category badge
- Context menu to delete
- "+" opens add sheet: title, category picker, optional PhotosPicker

### 7. ProfileView
- **File:** `ChloeApp/Views/Main/ProfileView.swift`
- User avatar (initials circle), display name with inline edit
- Archetype card (label + blend description) if set
- 2x2 stats grid: conversations, journal entries, vision items, goals
- "Member since" date
- All data from StorageService

### 8. SettingsView (expand)
- **File:** `ChloeApp/Views/Main/SettingsView.swift`
- Account section: Sign Out (existing)
- Data section: "Clear All Data" with destructive confirmation alert
- Notifications section: toggle placeholders (Daily Affirmation, Journal Reminder) — store in UserDefaults
- About section: version + build number

---

## All Relevant File Paths

### Models
- `/Users/secondary/ChloeApp/ChloeApp/Models/Profile.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Models/Message.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Models/Conversation.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Models/JournalEntry.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Models/VisionItem.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Models/Goal.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Models/Affirmation.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Models/Archetype.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Models/OnboardingPreferences.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Models/TopicCard.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Models/DailyUsage.swift`

### ViewModels
- `/Users/secondary/ChloeApp/ChloeApp/ViewModels/AuthViewModel.swift`
- `/Users/secondary/ChloeApp/ChloeApp/ViewModels/ChatViewModel.swift`
- `/Users/secondary/ChloeApp/ChloeApp/ViewModels/OnboardingViewModel.swift`
- `/Users/secondary/ChloeApp/ChloeApp/ViewModels/JournalViewModel.swift`
- `/Users/secondary/ChloeApp/ChloeApp/ViewModels/GoalsViewModel.swift`
- `/Users/secondary/ChloeApp/ChloeApp/ViewModels/VisionBoardViewModel.swift`
- `/Users/secondary/ChloeApp/ChloeApp/ViewModels/AffirmationsViewModel.swift`

### Views — Stubs to Rewrite
- `/Users/secondary/ChloeApp/ChloeApp/Views/Onboarding/ArchetypeQuizView.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Main/HomeView.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Main/AffirmationsView.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Main/JournalView.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Main/GoalsView.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Main/VisionBoardView.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Main/ProfileView.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Main/SettingsView.swift`

### Views — New Files Needed
- `/Users/secondary/ChloeApp/ChloeApp/Views/Components/TopicCardView.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Main/JournalEntryEditorView.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Main/JournalDetailView.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Main/AddVisionSheet.swift`

### Views — Working (reference for patterns)
- `/Users/secondary/ChloeApp/ChloeApp/Views/App/ContentView.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Auth/WelcomeView.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Auth/EmailLoginView.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Onboarding/OnboardingContainerView.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Onboarding/NameStepView.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Onboarding/VibeCheckView.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Onboarding/OnboardingCompleteView.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Main/ChatView.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Main/MainTabView.swift`

### Components
- `/Users/secondary/ChloeApp/ChloeApp/Views/Components/SelectionChip.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Components/ChloeAvatar.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Components/GradientBackground.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Components/ChatBubble.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Components/ChatInputBar.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Components/TypingIndicator.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Components/DisclaimerText.swift`

### Services
- `/Users/secondary/ChloeApp/ChloeApp/Services/StorageService.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Services/GeminiService.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Services/SafetyService.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Services/ArchetypeService.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Services/AnalystService.swift`

### Theme
- `/Users/secondary/ChloeApp/ChloeApp/Theme/Colors.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Theme/Fonts.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Theme/Spacing.swift`

### Constants
- `/Users/secondary/ChloeApp/ChloeApp/Constants/Prompts.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Constants/CrisisResponses.swift`

### Extensions
- `/Users/secondary/ChloeApp/ChloeApp/Extensions/Color+Theme.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Extensions/String+Utils.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Extensions/Date+Formatting.swift`

---

## Build Command
```bash
xcodebuild -project /Users/secondary/ChloeApp/ChloeApp.xcodeproj -scheme ChloeApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet build
```

## SPM Dependencies (already added)
- Lottie 4.6.0, Kingfisher 8.6.2, ExyteChat 2.7.6, ConfettiSwiftUI 1.1.0, MarkdownUI 2.4.1, TelemetryDeck 2.11.0
