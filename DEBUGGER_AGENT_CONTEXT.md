# ChloeApp — Debugger Agent Context

## Project Background & Architecture

ChloeApp is a native iOS app (Swift 5, SwiftUI, iOS 17+) following MVVM architecture. It's a feminine energy coaching companion powered by Gemini AI. Persistence uses UserDefaults (no database). Networking uses URLSession + async/await.

---

## Build Command

```bash
xcodebuild -project /Users/secondary/ChloeApp/ChloeApp.xcodeproj -scheme ChloeApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet build
```

## How to Run in Simulator

```bash
# Build and install
xcodebuild -project /Users/secondary/ChloeApp/ChloeApp.xcodeproj -scheme ChloeApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Boot simulator
xcrun simctl boot "iPhone 17 Pro" 2>/dev/null || true

# Install
xcrun simctl install "iPhone 17 Pro" ~/Library/Developer/Xcode/DerivedData/ChloeApp-*/Build/Products/Debug-iphonesimulator/ChloeApp.app

# Launch
xcrun simctl launch "iPhone 17 Pro" com.chloeapp.ChloeApp
```

---

## Complete File Tree with Descriptions

```
/Users/secondary/ChloeApp/ChloeApp/
├── ChloeApp.swift                    — App entry point (@main)
├── Info.plist                        — Bundle config (includes GEMINI_API_KEY reference)
├── Config.xcconfig                   — API keys (GEMINI_API_KEY)
│
├── Models/
│   ├── Profile.swift                 — User profile + UserFact + FactCategory + SubscriptionTier
│   ├── Message.swift                 — Chat message + MessageRole enum
│   ├── Conversation.swift            — Conversation metadata
│   ├── JournalEntry.swift            — Journal entry + JournalMood enum
│   ├── VisionItem.swift              — Vision board item + VisionCategory enum
│   ├── Goal.swift                    — Goal + GoalStatus enum
│   ├── Affirmation.swift             — Daily affirmation
│   ├── Archetype.swift               — ArchetypeId, UserArchetype, AnalystResult, ExtractedFact
│   ├── OnboardingPreferences.swift   — All onboarding enums (RelationshipStatus, PrimaryGoal, CoreDesire, PainPoint, VibeScore, ArchetypeAnswers, ArchetypeChoice)
│   └── DailyUsage.swift              — Rate limiting tracker
│
├── ViewModels/
│   ├── AuthViewModel.swift           — Authentication state (@MainActor)
│   ├── ChatViewModel.swift           — Chat logic, safety, rate limiting, analysis triggers (@MainActor)
│   ├── OnboardingViewModel.swift     — 4-step onboarding flow (@MainActor)
│   ├── JournalViewModel.swift        — CRUD for journal entries (@MainActor)
│   ├── GoalsViewModel.swift          — CRUD for goals + status toggling (@MainActor)
│   ├── VisionBoardViewModel.swift    — CRUD for vision items (@MainActor)
│   └── AffirmationsViewModel.swift   — Load/save/generate affirmations (@MainActor)
│
├── Views/
│   ├── App/
│   │   └── ContentView.swift         — Root routing: auth → onboarding → main
│   ├── Auth/
│   │   └── EmailLoginView.swift      — Email input → signIn
│   ├── Onboarding/
│   │   ├── WelcomeIntroView.swift    — Step 0: Welcome landing with "Begin" button
│   │   ├── OnboardingContainerView.swift — TabView with 4 steps + progress bar
│   │   ├── NameStepView.swift        — Step 1: Name input
│   │   ├── ArchetypeQuizView.swift   — Step 2: 4-question quiz (4 sub-pages)
│   │   └── OnboardingCompleteView.swift — Step 3: Completion + confetti
│   ├── Main/
│   │   ├── SanctuaryView.swift       — Main hub with chat, orb, greeting, sidebar
│   │   ├── SidebarView.swift         — Slide-out sidebar navigation
│   │   ├── JournalView.swift         — Journal entries list
│   │   ├── JournalEntryEditorView.swift — Create/edit journal entry sheet
│   │   ├── JournalDetailView.swift   — Read-only journal detail
│   │   ├── HistoryView.swift         — Chat conversation history
│   │   ├── GoalsView.swift           — Goal tracking
│   │   ├── VisionBoardView.swift     — Vision board grid
│   │   ├── AddVisionSheet.swift      — Add vision item sheet
│   │   ├── AffirmationsView.swift    — AI affirmations list
│   │   └── SettingsView.swift        — Settings + sign out
│   └── Components/
│       ├── BentoGridCard.swift       — Container card with ultraThinMaterial
│       ├── BloomTextModifier.swift   — Left-to-right text reveal animation
│       ├── CameraPickerView.swift    — UIKit camera wrapper
│       ├── ChatBubble.swift          — User/Chloe message bubble
│       ├── ChatInputBar.swift        — Text input + send button
│       ├── ChloeAvatar.swift         — Circular avatar (orb or logo)
│       ├── ChloeButtonLabel.swift    — Primary CTA button (Cinzel, capsule)
│       ├── DisclaimerText.swift      — AI disclaimer text
│       ├── EtherealDustParticles.swift — Atmospheric particle effect
│       ├── GradientBackground.swift  — Background gradient + .chloeBackground() modifier
│       ├── LuminousOrb.swift         — Canvas-based breathing blob orb
│       ├── OnboardingCard.swift      — Card selector for onboarding
│       ├── OrbStardustEmitter.swift  — Particle emitter around orb
│       ├── PlusBloomMenu.swift       — Radial action menu
│       ├── PressableButtonStyle.swift — Press feedback button style
│       ├── ShimmerTextModifier.swift — Shimmer sweep text effect
│       └── TypingIndicator.swift     — Animated typing dots
│
├── Services/
│   ├── StorageService.swift          — UserDefaults persistence (singleton)
│   ├── GeminiService.swift           — Gemini AI REST API (singleton)
│   ├── SafetyService.swift           — Regex crisis detection (singleton)
│   ├── ArchetypeService.swift        — Score-based archetype classification (singleton)
│   └── AnalystService.swift          — Background conversation analysis (singleton)
│
├── Theme/
│   ├── Colors.swift                  — Color extensions (hex values)
│   ├── Fonts.swift                   — Font extensions (Cinzel + CormorantGaramond + SF Pro system)
│   └── Spacing.swift                 — Spacing constants
│
├── Constants/
│   ├── Prompts.swift                 — System prompts, templates, prompt builders
│   └── CrisisResponses.swift         — Crisis hotline responses
│
├── Extensions/
│   ├── Color+Theme.swift             — Color(hex:) initializer
│   ├── String+Utils.swift            — .trimmed, .isBlank, .truncated(to:)
│   └── Date+Formatting.swift         — .shortDate, .timeOnly, .relativeDescription, .journalHeader
│
├── Resources/Fonts/                  — Cinzel, CormorantGaramond-BoldItalic, TenorSans .ttf files
└── Assets.xcassets/                  — App icons, chloe-logo image
```

---

## Services & How They Interact

### StorageService (UserDefaults singleton)
- Central persistence layer. All data stored as JSON-encoded Data in UserDefaults.
- Keys: `profile`, `conversations`, `messages_{conversationId}`, `journal_entries`, `goals`, `affirmations`, `vision_items`, `user_facts`, `latest_vibe`, `daily_usage`, `messages_since_analysis`
- Uses ISO8601 date encoding/decoding.
- `clearAll()` removes all keys.

### GeminiService (REST API singleton)
- Makes POST requests to `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent`
- API key from `Bundle.main.infoDictionary["GEMINI_API_KEY"]` (set via Config.xcconfig → Info.plist)
- Methods:
  - `sendMessage(messages:systemPrompt:userFacts:temperature:)` → chat response
  - `analyzeConversation(messages:)` → `AnalystResult` (JSON parsed)
  - `generateAffirmation(displayName:preferences:archetype:)` → affirmation text
  - `generateTitle(for:)` → short conversation title
- Timeout: 15 seconds
- Safety settings: BLOCK_ONLY_HIGH (harassment, hate, dangerous), BLOCK_MEDIUM (sexual)

### SafetyService (Regex singleton)
- `checkSafety(message:)` → `SafetyCheckResult { blocked: Bool, crisisType: CrisisType? }`
- Detects: self-harm, abuse, severe mental health crisis
- `getCrisisResponse(for:)` → formatted hotline resources text

### ArchetypeService (Classification singleton)
- `classify(answers: ArchetypeAnswers)` → `UserArchetype`
- Scoring table: 4 questions × 4 answers → weighted archetype scores
- Returns primary + secondary archetype with labels and descriptions
- Static `archetypeData` dictionary with 7 archetypes

### AnalystService (Background analysis singleton)
- `analyze(messages:)` → delegates to `GeminiService.analyzeConversation()`
- `mergeNewFacts(existing:from:userId:sourceMessageId:)` → deduplicates and appends new facts

### Interaction Flow (Chat)
1. User types message → ChatViewModel.sendMessage()
2. SafetyService.checkSafety() — if blocked, show crisis response
3. Rate limit check (DailyUsage from StorageService, FREE_DAILY_MESSAGE_LIMIT = 5)
4. Build personalized prompt (Prompts.buildPersonalizedPrompt with user context)
5. GeminiService.sendMessage() with message history
6. Append response to messages array
7. Every 3 messages → background Task: AnalystService.analyze() → merge facts → save to StorageService
8. Save messages to StorageService

---

## Data Flow: StorageService → ViewModel → View

```
StorageService.shared.loadX()
        ↓
ViewModel.loadX() — called in View.onAppear
        ↓
@Published var items: [X]
        ↓
View observes via @StateObject / @ObservedObject
        ↓
User action → ViewModel.mutateX()
        ↓
ViewModel updates @Published + calls StorageService.shared.saveX()
```

**Example (Journal):**
```
JournalView.onAppear → viewModel.loadEntries()
  → StorageService.shared.loadJournalEntries()
  → viewModel.entries = [JournalEntry]
  → View re-renders list

User swipes to delete → viewModel.deleteEntry(at:)
  → entries.remove(atOffsets:)
  → StorageService.shared.saveJournalEntries(entries)
  → View updates
```

---

## Known Areas of Complexity

### 1. API Calls (GeminiService)
- **Timeout handling**: URLError caught and mapped to GeminiError.timeout
- **API key missing**: Check Bundle.main.infoDictionary — key must be in Config.xcconfig AND Info.plist
- **Response parsing**: Manual JSON parsing (not Codable for top-level Gemini response format)
- **Rate limiting**: Free tier = 5 messages/day, tracked in DailyUsage

### 2. Background Analysis Triggers
- ChatViewModel triggers analysis every 3 messages (tracked via `messagesSinceAnalysis` in StorageService)
- Uses `Task.detached` — runs off main actor
- Parses JSON response into AnalystResult
- Merges facts, updates vibe score in StorageService

### 3. Rate Limiting
- `DailyUsage` struct with date string + messageCount
- Resets when day changes (checked in StorageService.loadDailyUsage())
- Checked before every message send in ChatViewModel

### 4. Safety Checks
- Regex patterns checked on every user message before sending to API
- If blocked: message is NOT sent to API, crisis response shown instead
- Three crisis types with different hotline resources

### 5. Prompt Building
- Template variables: `{{user_name}}`, `{{archetype_blend}}`, `{{archetype_label}}`, `{{archetype_description}}`
- Fallbacks: "Not determined yet" (archetype fields), "babe" (empty name)
- System prompt instructs Chloe to never output these fallback strings

---

## Common Swift/SwiftUI Pitfalls to Watch For

### @MainActor
- All ViewModels are `@MainActor` — UI updates must happen on main thread
- `Task.detached` escapes the main actor — be careful accessing @Published properties from detached tasks
- Use `await MainActor.run { }` to bounce back to main actor from detached context

### async/await
- All network calls are async — must be called from `Task { }` or async context
- `Task { }` inherits the actor context (main actor in Views/ViewModels)
- `Task.detached { }` does NOT inherit actor context

### @Published Updates
- Must happen on main thread (guaranteed by @MainActor on ViewModels)
- Avoid publishing changes from background threads — will crash at runtime
- `defer { }` is useful for resetting loading states

### View Lifecycle
- `.onAppear` can be called multiple times (NavigationSplitView sidebar selection changes)
- Don't duplicate network calls — use flags or check if data already loaded
- `@StateObject` creates once, `@ObservedObject` expects external ownership

### NavigationSplitView
- Sidebar selection uses `$selectedItem` binding
- `.detailOnly` visibility on iPhone — sidebar is hidden
- Navigation values need to match expected types

### UserDefaults Limits
- No hard limit but practical limit ~512KB per key
- Large arrays of messages could hit performance issues
- Messages stored per-conversation to keep sizes manageable

### Codable + Dates
- StorageService uses ISO8601 date strategy — all Date fields must be ISO8601-compatible
- If adding new Codable types, ensure Date fields work with this strategy
- Missing keys in JSON will cause decoding failures — use optionals or default values

### SwiftUI Preview
- Previews need mock data — ViewModels with empty init work for most cases
- Services use singletons — previews may trigger real UserDefaults reads
- Use `#Preview { }` macro (iOS 17+)

---

## How to Verify Fixes

### Build Check
```bash
xcodebuild -project /Users/secondary/ChloeApp/ChloeApp.xcodeproj -scheme ChloeApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet build
```

### Simulator Run
```bash
# Build + run in one step
xcodebuild -project /Users/secondary/ChloeApp/ChloeApp.xcodeproj -scheme ChloeApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
xcrun simctl boot "iPhone 17 Pro" 2>/dev/null || true
# Find the app bundle in DerivedData and install
```

### Key Flows to Test
1. **Auth**: Launch → Email login → authenticated
2. **Onboarding**: 4 steps (welcome intro → name → archetype quiz → complete)
3. **Chat**: Send message in Sanctuary → get response → check safety → check rate limit
4. **Journal**: Create entry → view list → open detail → delete
5. **Vision Board**: Add item → view grid → filter by category → delete
6. **History**: View conversation list → select conversation
7. **Settings**: Clear data → sign out

---

## All Model Shapes

### Profile
```swift
id: String, email: String, displayName: String, onboardingComplete: Bool,
preferences: OnboardingPreferences?, subscriptionTier: SubscriptionTier,
subscriptionExpiresAt: Date?, profileImageUri: String?, createdAt: Date, updatedAt: Date
```

### Message
```swift
id: String, conversationId: String?, role: MessageRole(.user|.chloe),
text: String, imageUri: String?, createdAt: Date
```

### Conversation
```swift
id: String, userId: String?, title: String, starred: Bool, createdAt: Date, updatedAt: Date
```

### JournalEntry
```swift
id: String, userId: String?, title: String, content: String, mood: String, createdAt: Date
```

### Goal
```swift
id: String, userId: String?, title: String, description: String?,
status: GoalStatus(.active|.completed|.paused), createdAt: Date, completedAt: Date?
```

### VisionItem
```swift
id: String, userId: String?, imageUri: String?, title: String,
category: VisionCategory(.love|.career|.selfCare|.travel|.lifestyle|.other),
createdAt: Date, updatedAt: Date
```

### Affirmation
```swift
id: String, userId: String?, text: String, date: String, isSaved: Bool, createdAt: Date
```

### UserArchetype
```swift
primary: ArchetypeId, secondary: ArchetypeId, label: String, blend: String, description: String
```

### AnalystResult
```swift
facts: [ExtractedFact], vibeScore: VibeScore, vibeReason: String, summary: String
```

### DailyUsage
```swift
date: String, messageCount: Int
static func todayKey() -> String  // "YYYY-MM-DD"
```

---

## Service Method Signatures

### StorageService.shared
```swift
func saveProfile(_ profile: Profile) throws
func loadProfile() -> Profile?
func saveConversations(_ conversations: [Conversation]) throws
func loadConversations() -> [Conversation]
func saveConversation(_ conversation: Conversation) throws
func loadConversation(id: String) -> Conversation?
func saveMessages(_ messages: [Message], forConversation conversationId: String) throws
func loadMessages(forConversation conversationId: String) -> [Message]
func saveJournalEntries(_ entries: [JournalEntry]) throws
func loadJournalEntries() -> [JournalEntry]
func saveGoals(_ goals: [Goal]) throws
func loadGoals() -> [Goal]
func saveAffirmations(_ affirmations: [Affirmation]) throws
func loadAffirmations() -> [Affirmation]
func saveVisionItems(_ items: [VisionItem]) throws
func loadVisionItems() -> [VisionItem]
func saveUserFacts(_ facts: [UserFact]) throws
func loadUserFacts() -> [UserFact]
func saveLatestVibe(_ vibe: VibeScore)
func loadLatestVibe() -> VibeScore?
func saveDailyUsage(_ usage: DailyUsage) throws
func loadDailyUsage() -> DailyUsage
func saveMessagesSinceAnalysis(_ count: Int)
func loadMessagesSinceAnalysis() -> Int
func clearAll()
```

### GeminiService.shared
```swift
func sendMessage(messages: [Message], systemPrompt: String, userFacts: [String], temperature: Double) async throws -> String
func analyzeConversation(messages: [Message]) async throws -> AnalystResult
func generateAffirmation(displayName: String, preferences: OnboardingPreferences?, archetype: UserArchetype?) async throws -> String
func generateTitle(for messageText: String) async throws -> String
```

### SafetyService.shared
```swift
func checkSafety(message: String) -> SafetyCheckResult
func getCrisisResponse(for crisisType: CrisisType) -> String
```

### ArchetypeService.shared
```swift
func classify(answers: ArchetypeAnswers) -> UserArchetype
static let archetypeData: [ArchetypeId: (label: String, briefForChloe: String)]
```

### AnalystService.shared
```swift
func analyze(messages: [Message]) async throws -> AnalystResult
func mergeNewFacts(existing: [UserFact], from result: AnalystResult, userId: String?, sourceMessageId: String?) -> [UserFact]
```

### Prompt Builders (free functions in Prompts.swift)
```swift
func buildPersonalizedPrompt(displayName: String, preferences: OnboardingPreferences?, archetype: UserArchetype?) -> String
func buildAffirmationPrompt(displayName: String, preferences: OnboardingPreferences?, archetype: UserArchetype?) -> String
```
