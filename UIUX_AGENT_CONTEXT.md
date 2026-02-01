# ChloeApp — UI/UX Agent Context

## Project Background

ChloeApp is a native iOS app (Swift/SwiftUI, iOS 17+) — a feminine energy coaching companion powered by Gemini AI. Originally prototyped as an Expo/React Native web app, it was pivoted to native iOS. The backend logic (models, services, prompts, safety, archetype classification, API calls) is fully implemented. The app builds and runs.

**Current state:** Most views are fully built. SanctuaryView is the main hub with working chat, journal, history, vision board, settings. GoalsView and AffirmationsView exist but are orphaned (not reachable from sidebar navigation).

---

## Current State

### Done
- All Models (Profile, Message, Conversation, JournalEntry, VisionItem, Goal, Affirmation, Archetype, OnboardingPreferences, DailyUsage)
- All Services (GeminiService, StorageService, SafetyService, ArchetypeService, AnalystService)
- All ViewModels (Auth, Chat, Onboarding, Journal, Goals, VisionBoard, Affirmations)
- Theme system (Colors, Fonts, Spacing)
- Reusable components (BentoGridCard, BloomTextModifier, CameraPickerView, ChatBubble, ChatInputBar, ChloeAvatar, ChloeButtonLabel, DisclaimerText, EtherealDustParticles, GradientBackground, LuminousOrb, OnboardingCard, OrbStardustEmitter, PlusBloomMenu, PressableButtonStyle, ShimmerTextModifier, TypingIndicator)
- Working views: EmailLoginView, ContentView (root routing), WelcomeIntroView, OnboardingContainerView, NameStepView, ArchetypeQuizView, OnboardingCompleteView, SanctuaryView, SidebarView, JournalView, JournalEntryEditorView, JournalDetailView, HistoryView, VisionBoardView, AddVisionSheet, GoalsView, AffirmationsView, SettingsView
- Constants/Prompts (system prompt, affirmation template, analyst prompt)

### Orphaned (exist but not in sidebar navigation)
- `GoalsView.swift` — Goal tracking (built, but no sidebar entry)
- `AffirmationsView.swift` — AI affirmation list (built, but no sidebar entry)

---

## Design System Reference

### Colors (hex values from Colors.swift)
```
chloeBackground     = #FFF8F0   (Warm cream)
chloeSurface        = #FAFAFA   (Off-white)
chloePrimary        = #B76E79   (Rose gold)
chloePrimaryLight   = #FFF0EB   (Light pink)
chloePrimaryDark    = #8A4A55   (Dark rose)
chloeAccent         = #F4A896   (Peachy rose)
chloeAccentMuted    = #E8B4A8   (Muted peach)
chloeTextPrimary    = #2D2324   (Near-black brown)
chloeTextSecondary  = #6B6B6B   (Medium gray)
chloeTextTertiary   = #9A9A9A   (Light gray)
chloeBorder         = #E5E5E5   (Light border)
chloeBorderWarm     = #F0E0DA   (Warm border)
chloeUserBubble     = #F0F0F0   (Chat user bubble)
chloeGradientStart  = #FFF8F5   (Gradient start)
chloeGradientEnd    = #FEEAE2   (Gradient end)
chloeRosewood       = #8E5A5E   (Muted rose — shadows, dividers)
chloeEtherealGold   = #F3E5AB   (Gold — orb core, particles)
```

### Fonts (from Fonts.swift)

Custom font files: Cinzel-Regular, CormorantGaramond-BoldItalic, TenorSans-Regular

```
Hero/Greeting: CormorantGaramond-BoldItalic (custom)
Buttons/Headers: Cinzel-Regular (custom)
Sidebar Logo: TenorSans-Regular (custom)
Body/UI: SF Pro system font

Named Styles:
  .chloeLargeTitle         — 28pt SF Pro medium
  .chloeTitle              — 22pt SF Pro medium
  .chloeTitle2             — 20pt SF Pro regular
  .chloeHeadline           — 17pt SF Pro medium
  .chloeSubheadline        — 15pt SF Pro medium
  .chloeBodyDefault        — 17pt SF Pro regular
  .chloeBodyLight          — 17pt SF Pro light
  .chloeCaption            — 14pt SF Pro regular
  .chloeCaptionLight       — 14pt SF Pro light
  .chloeButton             — 15pt Cinzel-Regular
  .chloeGreeting           — 38pt CormorantGaramond-BoldItalic
  .chloeOnboardingQuestion — 34pt CormorantGaramond-BoldItalic
  .chloeStatus             — 11pt Cinzel-Regular
  .chloeProgressLabel      — 11pt SF Pro light
  .chloeSidebarSectionHeader — 12pt Cinzel-Regular
  .chloeSidebarMenuItem    — 15pt SF Pro regular
  .chloeSidebarChatItem    — 14pt SF Pro regular
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
    static let orbSize: CGFloat = 80
    static let orbSizeSanctuary: CGFloat = 120
    static let sanctuaryOrbY: CGFloat = 0.25
}
```

---

## Reusable Components Catalog

### ChloeAvatar
```swift
struct ChloeAvatar: View {
    var size: CGFloat = 40
}
// >=80pt: LuminousOrb, <80pt: "chloe-logo" image
```

### GradientBackground
```swift
struct GradientBackground: View
// LinearGradient: chloeGradientStart → chloeGradientEnd, ignores safe area
// Also available as: .chloeBackground() view modifier
```

### ChloeButtonLabel
```swift
// Primary CTA — Cinzel 15pt, ALL-CAPS, tracking 3, capsule shape
// Background: chloePrimary (full / 0.45 disabled)
// Shadow: black 0.15, radius 20, y 10
```

### PressableButtonStyle
```swift
// Press feedback — scale 1.0 → 0.96
// Shadow: chloePrimary 0.3/r8/y4 → 0.15/r4/y2
```

### BentoGridCard
```swift
// Container card — cornerRadius 28, ultraThinMaterial, rosewood shadow
```

### OnboardingCard
```swift
// Card selector — title (15pt medium) + description (14pt light)
// Selected: chloePrimaryLight bg, chloePrimary text
// Unselected: chloeSurface bg
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

### LuminousOrb
```swift
// Canvas-based breathing blob, radial gold → rose gradient
// 5-stop gradient, outer glow, breathing animation
```

### PlusBloomMenu
```swift
// 3-item radial menu, 44pt circles, spring animated
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
    let id: String
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
enum JournalMood: String, CaseIterable, Hashable {
    case happy, calm, grateful, anxious, sad, angry, hopeful, tired
    var emoji: String { ... }
    var label: String { ... }
}

struct JournalEntry: Codable, Identifiable {
    let id: String
    var userId: String?
    var title: String
    var content: String
    var mood: String
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

---

## Navigation Structure

### SanctuaryView + SidebarView
SanctuaryView is the main hub. It includes:
- LuminousOrb with greeting text
- Chat input and messages
- Slide-out SidebarView (custom, not NavigationSplitView)

SidebarView destinations are defined by `SidebarDestination` enum:
```swift
enum SidebarDestination {
    case journal, history, visionBoard, settings
}
```

Navigation items in sidebar:
- New Chat (action, not destination)
- Journal → JournalView
- History → HistoryView
- Vision Board → VisionBoardView
- Settings → SettingsView

### ContentView (Root Routing)
```
!isAuthenticated → EmailLoginView
isAuthenticated && !onboardingComplete → OnboardingContainerView
Both true → SanctuaryView
```

### Onboarding Flow (4 steps)
0: WelcomeIntroView, 1: NameStepView, 2: ArchetypeQuizView (4 sub-questions), 3: OnboardingCompleteView

---

## Design Conventions & Patterns

1. **Every view**: `GradientBackground()` as ZStack base
2. **Fonts**: Use `.chloeTitle`, `.chloeHeadline`, `.chloeBodyDefault`, `.chloeCaption` etc.
3. **Colors**: Use `.chloePrimary`, `.chloeTextPrimary/.Secondary/.Tertiary`, `.chloeSurface`, `.chloeBorder`
4. **Spacing**: Use `Spacing.screenHorizontal`, `.cardPadding`, `.cornerRadius`
5. **Cards**: BentoGridCard or `.chloeSurface` background + `.chloeBorder` stroke + `Spacing.cornerRadius`
6. **Buttons**: ChloeButtonLabel for primary CTAs, PressableButtonStyle for interactive cards
7. **ViewModels**: `@MainActor` on all ViewModels
8. **Previews**: `#Preview` blocks on every view
9. **Onboarding views**: `@ObservedObject var viewModel: OnboardingViewModel`, vertical layout, OnboardingCard answers, "Continue" button calling `viewModel.nextStep()`

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
- `/Users/secondary/ChloeApp/ChloeApp/Models/DailyUsage.swift`

### ViewModels
- `/Users/secondary/ChloeApp/ChloeApp/ViewModels/AuthViewModel.swift`
- `/Users/secondary/ChloeApp/ChloeApp/ViewModels/ChatViewModel.swift`
- `/Users/secondary/ChloeApp/ChloeApp/ViewModels/OnboardingViewModel.swift`
- `/Users/secondary/ChloeApp/ChloeApp/ViewModels/JournalViewModel.swift`
- `/Users/secondary/ChloeApp/ChloeApp/ViewModels/GoalsViewModel.swift`
- `/Users/secondary/ChloeApp/ChloeApp/ViewModels/VisionBoardViewModel.swift`
- `/Users/secondary/ChloeApp/ChloeApp/ViewModels/AffirmationsViewModel.swift`

### Views
- `/Users/secondary/ChloeApp/ChloeApp/Views/App/ContentView.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Auth/EmailLoginView.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Onboarding/WelcomeIntroView.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Onboarding/OnboardingContainerView.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Onboarding/NameStepView.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Onboarding/ArchetypeQuizView.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Onboarding/OnboardingCompleteView.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Main/SanctuaryView.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Main/SidebarView.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Main/JournalView.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Main/JournalEntryEditorView.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Main/JournalDetailView.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Main/HistoryView.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Main/GoalsView.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Main/VisionBoardView.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Main/AddVisionSheet.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Main/AffirmationsView.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Main/SettingsView.swift`

### Components
- `/Users/secondary/ChloeApp/ChloeApp/Views/Components/BentoGridCard.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Components/BloomTextModifier.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Components/CameraPickerView.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Components/ChatBubble.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Components/ChatInputBar.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Components/ChloeAvatar.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Components/ChloeButtonLabel.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Components/DisclaimerText.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Components/EtherealDustParticles.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Components/GradientBackground.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Components/LuminousOrb.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Components/OnboardingCard.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Components/OrbStardustEmitter.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Components/PlusBloomMenu.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Components/PressableButtonStyle.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Components/ShimmerTextModifier.swift`
- `/Users/secondary/ChloeApp/ChloeApp/Views/Components/TypingIndicator.swift`

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
