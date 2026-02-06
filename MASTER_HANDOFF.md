# MASTER HANDOFF — ChloeApp iOS

> **Generated:** 2026-02-05
> **Scope:** Complete technical blueprint for the ChloeApp iOS native project.
> **Purpose:** Sole source of truth for future agent swarms with ZERO access to the original codebase.
> **Reading this document IS reading the codebase.**

---

## TABLE OF CONTENTS

1. [Project Overview](#1-project-overview)
2. [Complete File Map](#2-complete-file-map)
3. [Supabase Backend Schema](#3-supabase-backend-schema)
4. [Gemini AI Pipeline](#4-gemini-ai-pipeline)
5. [Auth & User Lifecycle](#5-auth--user-lifecycle)
6. [Data Sync System](#6-data-sync-system)
7. [UI & Design System](#7-ui--design-system)
8. [Chloe's Personality System](#8-chloes-personality-system)
9. [Test Coverage Map](#9-test-coverage-map)
10. [Known Remaining Issues](#10-known-remaining-issues)
11. [Monetization State](#11-monetization-state)
12. [Environment & Config](#12-environment--config)
13. [Mission Briefs](#13-mission-briefs)

---

## 1. PROJECT OVERVIEW

### What Is ChloeApp?

ChloeApp ("Chloe in Your Pocket") is a native iOS app built with Swift/SwiftUI that serves as an AI-powered "big sister" and high-value dating strategist for women. The AI persona, Chloe, uses a custom prompt framework to provide relationship advice, self-improvement coaching, and emotional support through a chat interface.

**This is NOT a web app.** It is strictly an iOS-native project. A separate Expo/React Native web app exists at `/chloe-in-your-pocket/` but is completely ignored by this project.

### Tech Stack

| Layer | Technology |
|---|---|
| **Language** | Swift 5 |
| **UI Framework** | SwiftUI (iOS 17+ deployment target) |
| **Architecture** | MVVM (Model-View-ViewModel) |
| **Local Storage** | UserDefaults + JSON encoding (via `StorageService`) |
| **File Storage** | Documents directory (images) |
| **Cloud Backend** | Supabase (Auth + PostgreSQL + Storage) |
| **AI Model** | Google Gemini 2.0 Flash (REST API) |
| **AI Gateway** | Portkey (logging/analytics proxy, optional) |
| **Package Manager** | Swift Package Manager (SPM) |
| **Auth Flow** | Supabase PKCE (email + password, magic link confirmation) |
| **Deep Links** | `chloeapp://auth-callback` (email confirmation + password recovery) |

### SPM Dependencies (Package.resolved)

| Package | Version | Purpose |
|---|---|---|
| supabase-swift | 2.41.0 | Auth, database, storage |
| Lottie | 4.6.0 | Animations |
| Kingfisher | 8.6.2 | Image loading/caching |
| ExyteChat | 2.7.6 | Chat UI (currently unused — custom chat built) |
| ConfettiSwiftUI | 1.1.0 | Celebration effects |
| MarkdownUI | 2.4.1 | Markdown rendering |
| TelemetryDeck | 2.11.0 | Analytics (not yet wired) |

**Transitive Supabase dependencies (auto-resolved):**
- swift-concurrency-extras, swift-http-types, swift-crypto
- get (for HTTP), keyed-decoding-container
- multipart-form-data, xctest-dynamic-overlay

### Core Architectural Principles

1. **Local-first:** All reads come from local storage (instant). Writes go local first, then async push to Supabase.
2. **Singleton services:** `GeminiService.shared`, `StorageService.shared`, `SyncDataService.shared`, `SafetyService.shared`, etc.
3. **Two AI pipelines:** V1 (single prompt) and V2 (Router→Strategist agentic pipeline). V2 is active (`V2_AGENTIC_MODE = true`).
4. **Safety first:** Crisis detection runs client-side BEFORE any AI call. Hard-coded crisis responses with hotline numbers.
5. **Offline resilience:** `NetworkMonitor` tracks connectivity. Writes queue locally when offline; push to cloud on reconnect.

---

## 2. COMPLETE FILE MAP

### Directory Structure

```
/Users/secondary/ChloeApp/
├── ChloeApp.xcodeproj/
│   ├── project.pbxproj                    (Xcode project config)
│   ├── project.xcworkspace/
│   │   └── xcshareddata/swiftpm/
│   │       └── Package.resolved           (SPM lock file — 19 packages)
│   └── xcshareddata/xcschemes/
│       └── ChloeApp.xcscheme              (Build scheme)
├── ChloeApp/
│   ├── ChloeApp.swift                     (App entry point — @main)
│   ├── ChloeApp.entitlements              (App entitlements)
│   ├── Config.xcconfig                    (API keys: GEMINI_API_KEY, SUPABASE_URL, etc.)
│   ├── Info.plist                         (Bundle config, custom fonts, URL schemes)
│   ├── Assets.xcassets/                   (App icon, accent color, chloe-logo)
│   ├── Constants/
│   │   ├── Prompts.swift                  (649 lines — ALL system prompts, the brain)
│   │   └── CrisisResponses.swift          (43 lines — hardcoded crisis responses)
│   ├── Extensions/
│   │   ├── Color+Theme.swift              (UIColor hex initializer)
│   │   ├── Date+Formatting.swift          (Date formatting helpers)
│   │   ├── String+Utils.swift             (String utilities)
│   │   └── UIImage+Downsampling.swift     (Image resize for upload)
│   ├── Models/                            (13 Codable structs)
│   │   ├── Affirmation.swift              (AI-generated daily affirmation)
│   │   ├── Archetype.swift                (7 archetypes + quiz scoring)
│   │   ├── Conversation.swift             (Chat session metadata)
│   │   ├── DailyUsage.swift               (Rate limiting counter)
│   │   ├── Feedback.swift                 (Thumbs up/down + report)
│   │   ├── GlowUpStreak.swift             (Streak tracking)
│   │   ├── Goal.swift                     (User goals with milestones)
│   │   ├── JournalEntry.swift             (Private journal entries)
│   │   ├── Message.swift                  (Chat messages with V2 fields)
│   │   ├── OnboardingPreferences.swift    (Quiz answers, name, preferences)
│   │   ├── Profile.swift                  (User profile, subscription, behavioral loops)
│   │   ├── RouterModels.swift             (199 lines — V2 agentic types)
│   │   └── VisionItem.swift               (Vision board items with images)
│   ├── Services/                          (14 service singletons)
│   │   ├── AnalystService.swift           (Background analysis wrapper)
│   │   ├── ArchetypeService.swift         (Archetype quiz classification)
│   │   ├── FeedbackService.swift          (Submit feedback to Supabase + Portkey)
│   │   ├── GeminiService.swift            (575 lines — ALL Gemini API calls)
│   │   ├── NetworkMonitor.swift           (NWPathMonitor wrapper)
│   │   ├── NotificationService.swift      (Push notifications — affirmations, engagement, fallback)
│   │   ├── PortkeyService.swift           (189 lines — Portkey gateway for logging)
│   │   ├── SafetyService.swift            (119 lines — crisis + soft spiral detection)
│   │   ├── StorageService.swift           (392 lines — UserDefaults persistence layer)
│   │   ├── StreakService.swift             (GlowUp streak logic)
│   │   ├── SupabaseClient.swift           (Supabase client initialization)
│   │   ├── SupabaseDataService.swift      (All Supabase CRUD operations)
│   │   ├── SyncDataService.swift          (775 lines — offline-first sync orchestrator)
│   │   └── UITestSupport.swift            (Debug-only test environment setup)
│   ├── Theme/
│   │   ├── Colors.swift                   (151 lines — 16 semantic colors, light/dark)
│   │   ├── Fonts.swift                    (148 lines — custom fonts + Dynamic Type)
│   │   └── Spacing.swift                  (43 lines — spacing scale, orb sizes, spring)
│   ├── ViewModels/                        (7 ViewModels)
│   │   ├── AffirmationsViewModel.swift    (Generate + save affirmations)
│   │   ├── AuthViewModel.swift            (520 lines — auth state machine)
│   │   ├── ChatViewModel.swift            (448 lines — dual pipeline chat logic)
│   │   ├── GoalsViewModel.swift           (Goal CRUD)
│   │   ├── JournalViewModel.swift         (Journal CRUD)
│   │   ├── OnboardingViewModel.swift      (4-step onboarding flow)
│   │   └── VisionBoardViewModel.swift     (Vision board CRUD)
│   ├── Views/
│   │   ├── App/
│   │   │   └── ContentView.swift          (Root routing: auth → onboarding → sanctuary)
│   │   ├── Auth/
│   │   │   ├── EmailLoginView.swift       (Sign in / sign up form)
│   │   │   ├── EmailConfirmationView.swift (Awaiting email confirmation)
│   │   │   ├── NewPasswordView.swift      (Set new password after recovery)
│   │   │   └── PasswordResetView.swift    (Request password reset)
│   │   ├── Components/                    (20 reusable components)
│   │   │   ├── BentoGridCard.swift        (Grid layout card)
│   │   │   ├── BloomTextModifier.swift    (Luminous text effect)
│   │   │   ├── CameraPickerView.swift     (UIKit camera wrapper)
│   │   │   ├── ChatBubble.swift           (Message bubble with feedback)
│   │   │   ├── ChatInputBar.swift         (Text input + image upload)
│   │   │   ├── ChloeAvatar.swift          (Animated orb/avatar)
│   │   │   ├── ChloeButtonLabel.swift     (Styled button)
│   │   │   ├── DisclaimerText.swift       (AI disclaimer)
│   │   │   ├── EtherealDustParticles.swift (Particle effect)
│   │   │   ├── FlowLayout.swift           (Flow/wrap layout)
│   │   │   ├── GradientBackground.swift   (App background gradient)
│   │   │   ├── LuminousOrb.swift          (Animated glowing orb)
│   │   │   ├── NotificationPrimingView.swift (Permission priming sheet)
│   │   │   ├── OnboardingCard.swift       (Onboarding step card)
│   │   │   ├── OrbStardustEmitter.swift   (Particle emitter for orb)
│   │   │   ├── PlusBloomMenu.swift        (Expandable action menu)
│   │   │   ├── PressableButtonStyle.swift (Pressable button style)
│   │   │   ├── ReportSheet.swift          (Report message form)
│   │   │   ├── ShimmerTextModifier.swift  (Shimmer text effect)
│   │   │   ├── StrategyOptionsView.swift  (V2 strategy option cards)
│   │   │   └── TypingIndicator.swift      (Animated typing dots)
│   │   ├── Main/                          (10 main screens)
│   │   │   ├── AddVisionSheet.swift       (Add vision board item)
│   │   │   ├── AffirmationsView.swift     (Daily affirmations list)
│   │   │   ├── GoalsView.swift            (Goals with milestones)
│   │   │   ├── HistoryView.swift          (Conversation history list)
│   │   │   ├── JournalDetailView.swift    (Read journal entry)
│   │   │   ├── JournalEntryEditorView.swift (Create/edit journal)
│   │   │   ├── JournalView.swift          (Journal entries list)
│   │   │   ├── SanctuaryView.swift        (802 lines — main screen)
│   │   │   ├── SettingsView.swift         (App settings + account)
│   │   │   ├── SidebarView.swift          (Navigation sidebar)
│   │   │   └── VisionBoardView.swift      (Vision board grid)
│   │   └── Onboarding/                    (5 onboarding steps)
│   │       ├── ArchetypeQuizView.swift    (7-question archetype quiz)
│   │       ├── NameStepView.swift         (Enter name)
│   │       ├── OnboardingCompleteView.swift (Reveal archetype result)
│   │       ├── OnboardingContainerView.swift (Step container)
│   │       └── WelcomeIntroView.swift     (Welcome screen)
│   └── Resources/Fonts/                   (4 custom font files)
│       ├── Cinzel-Regular.ttf             (Header/button font)
│       ├── CormorantGaramond-BoldItalic.ttf (Hero/greeting font)
│       ├── PlayfairDisplay-Italic-VF.ttf  (Editorial font)
│       └── TenorSans-Regular.ttf          (Body font — registered but unused)
├── ChloeAppTests/                         (14 unit test files)
│   ├── AnalystServiceTests.swift
│   ├── AuthViewModelTests.swift
│   ├── ChatViewModelTests.swift
│   ├── CrisisResponseTests.swift
│   ├── DailyUsageTests.swift
│   ├── GeminiServiceTests.swift
│   ├── InsightQueueTests.swift
│   ├── MessageModelTests.swift
│   ├── PromptBuilderTests.swift
│   ├── SafetyServiceTests.swift
│   ├── StorageServiceTests.swift
│   ├── StreakServiceTests.swift
│   ├── SyncDataServiceTests.swift
│   └── V2AgenticTests.swift
├── ChloeAppUITests/                       (17 UI test files)
│   ├── AffirmationsTests.swift
│   ├── AuthenticationTests.swift
│   ├── ConversationHistoryTests.swift
│   ├── DynamicTypeTests.swift
│   ├── EdgeCaseTests.swift
│   ├── GoalsTests.swift
│   ├── ImageUploadTests.swift
│   ├── JournalTests.swift
│   ├── OnboardingTests.swift
│   ├── RateLimitTests.swift
│   ├── SafetyTests.swift
│   ├── SanctuaryTests.swift
│   ├── SettingsTests.swift
│   ├── SidebarTests.swift
│   ├── StreakUITests.swift
│   ├── TestHelpers.swift
│   └── VisionBoardTests.swift
├── auth-redirect/                         (Vercel-hosted email redirect)
│   ├── index.html                         (197 lines — deep link redirect page)
│   └── vercel.json                        (Routing config)
├── CLAUDE.md                              (Project context for Claude)
├── Chloe Design.md                        (Design documentation)
├── DEBUGGER_AGENT_CONTEXT.md              (Debug agent context)
├── UIUX_AGENT_CONTEXT.md                  (UI/UX agent context)
└── UIUX_DESIGN_AGENT.md                   (Design agent spec)
```

### File Counts

| Category | Count |
|---|---|
| Models | 13 |
| Services | 14 |
| ViewModels | 7 |
| Views (App/Auth/Main/Onboarding) | 20 |
| Components | 20 |
| Theme | 3 |
| Constants | 2 |
| Extensions | 4 |
| Unit Tests | 14 |
| UI Tests | 17 |
| **Total Swift files** | **114** |

---

## 3. SUPABASE BACKEND SCHEMA

### Project Details

- **Project ID:** `xyzgolauwqaxugrphfbz`
- **API URL:** `https://xyzgolauwqaxugrphfbz.supabase.co`
- **Auth:** Supabase Auth with PKCE flow, email+password
- **Redirect URL:** `chloeapp://auth-callback` (via Vercel-hosted `auth-redirect/index.html`)

### Public Tables

#### `profiles`
Primary user profile — one row per user.

| Column | Type | Nullable | Default | Notes |
|---|---|---|---|---|
| id | uuid | NOT NULL | — | PK, matches `auth.users.id` |
| email | text | YES | — | |
| display_name | text | YES | — | |
| onboarding_complete | boolean | YES | false | |
| preferences | jsonb | YES | — | `OnboardingPreferences` JSON |
| subscription_tier | text | YES | 'free' | 'free' or 'premium' |
| subscription_expires_at | timestamptz | YES | — | |
| profile_image_uri | text | YES | — | |
| is_blocked | boolean | YES | false | Admin ban flag |
| blocked_at | timestamptz | YES | — | |
| blocked_reason | text | YES | — | |
| behavioral_loops | jsonb | YES | — | Array of detected pattern strings |
| created_at | timestamptz | YES | now() | |
| updated_at | timestamptz | YES | now() | |

**RLS Policies:**
- `Users can view own profile` — SELECT: `(SELECT auth.uid()) = id`
- `Users can insert own profile` — INSERT: `(SELECT auth.uid()) = id`
- `Users can update own profile` — UPDATE: `(SELECT auth.uid()) = id`

#### `conversations`
Chat session metadata.

| Column | Type | Nullable | Default |
|---|---|---|---|
| id | text | NOT NULL | — |
| user_id | uuid | YES | — |
| title | text | YES | 'New Conversation' |
| starred | boolean | YES | false |
| created_at | timestamptz | YES | now() |
| updated_at | timestamptz | YES | now() |

**RLS:** SELECT/INSERT/UPDATE/DELETE — `(SELECT auth.uid()) = user_id`

#### `messages`
Individual chat messages within conversations.

| Column | Type | Nullable | Default |
|---|---|---|---|
| id | text | NOT NULL | — |
| user_id | uuid | YES | — |
| conversation_id | text | YES | — |
| role | text | YES | — |
| text | text | YES | — |
| image_uri | text | YES | — |
| router_metadata | jsonb | YES | — |
| content_type | text | YES | — |
| options | jsonb | YES | — |
| created_at | timestamptz | YES | now() |

**RLS:** SELECT/INSERT — `(SELECT auth.uid()) = user_id`

#### `user_facts`
AI-extracted facts about the user (long-term memory).

| Column | Type | Nullable | Default |
|---|---|---|---|
| id | text | NOT NULL | — |
| user_id | uuid | YES | — |
| fact | text | YES | — |
| category | text | YES | — |
| source_message_id | text | YES | — |
| is_active | boolean | YES | true |
| created_at | timestamptz | YES | now() |

**Categories:** `RELATIONSHIP_HISTORY`, `GOAL`, `TRIGGER`
**RLS:** SELECT/INSERT — `(SELECT auth.uid()) = user_id`

#### `journal_entries`
Private journal entries.

| Column | Type | Nullable | Default |
|---|---|---|---|
| id | text | NOT NULL | — |
| user_id | uuid | YES | — |
| title | text | YES | — |
| body | text | YES | — |
| mood | text | YES | — |
| tags | jsonb | YES | — |
| created_at | timestamptz | YES | now() |
| updated_at | timestamptz | YES | now() |

**RLS:** SELECT/INSERT/UPDATE/DELETE — `(SELECT auth.uid()) = user_id`

#### `vision_board_items`
Vision board items with optional images.

| Column | Type | Nullable | Default |
|---|---|---|---|
| id | text | NOT NULL | — |
| user_id | uuid | YES | — |
| title | text | YES | — |
| image_uri | text | YES | — |
| category | text | YES | — |
| sort_order | integer | YES | 0 |
| created_at | timestamptz | YES | now() |

**RLS:** SELECT/INSERT/UPDATE/DELETE — `(SELECT auth.uid()) = user_id`

#### `goals`
User goals with milestones and completion tracking.

| Column | Type | Nullable | Default |
|---|---|---|---|
| id | text | NOT NULL | — |
| user_id | uuid | YES | — |
| title | text | YES | — |
| description | text | YES | — |
| category | text | YES | — |
| is_completed | boolean | YES | false |
| target_date | timestamptz | YES | — |
| milestones | jsonb | YES | — |
| created_at | timestamptz | YES | now() |
| updated_at | timestamptz | YES | now() |

**RLS:** SELECT/INSERT/UPDATE/DELETE — `(SELECT auth.uid()) = user_id`

#### `affirmations`
AI-generated daily affirmations.

| Column | Type | Nullable | Default |
|---|---|---|---|
| id | text | NOT NULL | — |
| user_id | uuid | YES | — |
| text | text | YES | — |
| archetype | text | YES | — |
| vibe | text | YES | — |
| is_favorite | boolean | YES | false |
| created_at | timestamptz | YES | now() |

**RLS:** SELECT/INSERT/DELETE — `(SELECT auth.uid()) = user_id`

#### `user_state`
Ephemeral state synced to cloud (usage, streak, vibe, insights).

| Column | Type | Nullable | Default |
|---|---|---|---|
| user_id | uuid | NOT NULL | — |
| message_count | integer | YES | 0 |
| usage_date | text | YES | — |
| current_streak | integer | YES | 0 |
| longest_streak | integer | YES | 0 |
| last_active_date | text | YES | — |
| latest_vibe | text | YES | — |
| latest_summary | text | YES | — |
| messages_since_analysis | integer | YES | 0 |
| insight_queue | jsonb | YES | — |
| updated_at | timestamptz | YES | now() |

**RLS:** SELECT/INSERT/UPDATE — `(SELECT auth.uid()) = user_id`

#### `feedback`
Thumbs up/down and report data on AI responses.

| Column | Type | Nullable | Default |
|---|---|---|---|
| id | uuid | NOT NULL | gen_random_uuid() |
| user_id | uuid | YES | — |
| message_id | text | YES | — |
| conversation_id | text | YES | — |
| user_message | text | YES | — |
| ai_response | text | YES | — |
| rating | text | YES | — |
| report_reason | text | YES | — |
| report_details | text | YES | — |
| created_at | timestamptz | YES | now() |

**RLS:**
- `Users can insert own feedback` — INSERT: `auth.uid() = user_id` (**NOTE: Missing `(SELECT ...)` wrapper — performance issue**)
- `Users can view own feedback` — SELECT: `auth.uid() = user_id` (**Same issue**)

### Storage

**Bucket:** `chloe-images`
- **Public:** No (private)
- **File size limit:** None set
- **MIME type restriction:** None set
- **Path convention:** `{user_id}/vision/{item_id}.jpg`, `{user_id}/profile/profile_image.jpg`, `{user_id}/chat/{message_id}.jpg`

**Storage RLS Policies:**
- Users can upload to own folder: `INSERT ON objects` — bucket_id = 'chloe-images' AND `(SELECT auth.uid())::text = (storage.foldername(name))[1]`
- Users can view own images: `SELECT ON objects` — same pattern
- Users can delete own images: `DELETE ON objects` — same pattern

### Edge Functions

**`auth-redirect`** (Deno/TypeScript)
- Serves `auth-redirect/index.html` for email confirmation and password recovery
- Redirects to `chloeapp://auth-callback` with query parameters
- Hosted on Vercel (not Supabase Edge Functions)

### Indexes (20 total)

| Table | Index | Columns |
|---|---|---|
| profiles | profiles_pkey | id |
| conversations | conversations_pkey | id |
| conversations | idx_conversations_user_id | user_id |
| conversations | idx_conversations_updated_at | updated_at |
| messages | messages_pkey | id |
| messages | idx_messages_conversation_id | conversation_id |
| messages | idx_messages_user_id | user_id |
| messages | idx_messages_created_at | created_at |
| user_facts | user_facts_pkey | id |
| user_facts | idx_user_facts_user_id | user_id |
| journal_entries | journal_entries_pkey | id |
| journal_entries | idx_journal_entries_user_id | user_id |
| vision_board_items | vision_board_items_pkey | id |
| vision_board_items | idx_vision_board_items_user_id | user_id |
| goals | goals_pkey | id |
| goals | idx_goals_user_id | user_id |
| affirmations | affirmations_pkey | id |
| affirmations | idx_affirmations_user_id | user_id |
| user_state | user_state_pkey | user_id |
| feedback | feedback_pkey | id |

### Migrations (16 total, in order)

1. `create_profiles` — Initial profiles table
2. `create_conversations` — Conversations table
3. `create_messages` — Messages table
4. `create_user_facts` — User facts table
5. `create_journal_entries` — Journal entries table
6. `create_vision_board_items` — Vision board table
7. `create_goals` — Goals table
8. `create_affirmations` — Affirmations table
9. `create_user_state` — User state table
10. `add_indexes` — Performance indexes on all tables
11. `create_feedback` — Feedback table
12. `add_vision_sort_order` — Added sort_order to vision_board_items
13. `add_message_v2_fields` — Added router_metadata, content_type, options to messages
14. `add_goal_milestones` — Added milestones JSONB to goals
15. `add_user_blocking` — Added is_blocked, blocked_at, blocked_reason to profiles
16. `add_behavioral_loops_to_profiles` — Added behavioral_loops JSONB to profiles

### Security & Performance Advisories

**Security:**
- Leaked password protection is **DISABLED** (Supabase advisory)

**Performance:**
- `feedback` table: Foreign key `user_id` is not indexed (missing index)
- `feedback` RLS policies use `auth.uid()` without `(SELECT ...)` wrapper — causes `auth_rls_initplan` performance issue (function called per-row instead of once)
- `user_facts` table has unused indexes (Supabase advisor flagged)

---

## 4. GEMINI AI PIPELINE

### Overview

ChloeApp uses Google Gemini 2.0 Flash as its AI backend. All AI calls go through `GeminiService.swift` (singleton). There are two pipelines:

- **V1 (Legacy):** Single system prompt → plain text response
- **V2 (Agentic, ACTIVE):** Router → Strategist → structured JSON response with options

The active pipeline is controlled by `V2_AGENTIC_MODE = true` in `ChatViewModel.swift:5`.

### API Configuration

```
Base URL: https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent
Auth: x-goog-api-key header (from Config.xcconfig → Info.plist → Bundle.main)
Timeout: 15 seconds
```

### Safety Settings (Applied to ALL calls)

```
HARM_CATEGORY_HARASSMENT:        BLOCK_ONLY_HIGH
HARM_CATEGORY_HATE_SPEECH:       BLOCK_ONLY_HIGH
HARM_CATEGORY_SEXUALLY_EXPLICIT: BLOCK_MEDIUM_AND_ABOVE
HARM_CATEGORY_DANGEROUS_CONTENT: BLOCK_ONLY_HIGH
```

### V2 Agentic Pipeline (Active)

The V2 pipeline processes each user message through three phases:

#### Phase 1: Router (Classification/Triage)

**Service method:** `GeminiService.classifyMessage()`
**System prompt:** `Prompts.router`
**Temperature:** 0.1 (low — deterministic classification)
**Max tokens:** 256
**Output format:** `application/json` (forced)
**Retry:** 2 attempts with 0.5s delay

**Categories:**
| Category | Description |
|---|---|
| `CRISIS_BREAKUP` | Active breakup, no contact, blocking |
| `DATING_EARLY` | Talking stage, first dates, uncertainty, ghosting |
| `RELATIONSHIP_ESTABLISHED` | Boyfriend, conflict, stagnation |
| `SELF_IMPROVEMENT` | Glow up, career, general anxiety |
| `SAFETY_RISK` | Self-harm, abuse — triggers immediate override |

**Urgency levels:** `LOW` (casual), `MEDIUM` (asking advice), `HIGH` (panic/spiraling)

**Output JSON:**
```json
{
  "category": "DATING_EARLY",
  "urgency": "MEDIUM",
  "reasoning": "User is in the talking stage, asking about texting patterns."
}
```

**KNOWN ISSUE:** There is no `CASUAL` category in `RouterCategory` enum. General chat/greetings get classified under `SELF_IMPROVEMENT` or `DATING_EARLY`.

#### Phase 2: Strategist (Response Generation)

**Service method:** `GeminiService.sendStrategistMessage()`
**System prompt:** `Prompts.strategist` (with template variables replaced)
**Temperature:** 0.7
**Max tokens:** 2048
**Output format:** `application/json` (forced)
**Retry:** 2 attempts with 0.5s delay, then raw text fallback

**Context injected into strategist prompt:**
1. `<router_context>` — Category, urgency, reasoning from Phase 1
2. `<soft_spiral_override>` — If user shows emotional numbness (detected by SafetyService)
3. `<known_patterns>` — Behavioral loops from profile (permanent patterns from past sessions)
4. `<user_facts>` — Extracted facts about the user
5. `<last_session_summary>` — Context from previous conversation
6. `<insight_to_mention>` — Popped from insight queue

**Output JSON:**
```json
{
  "internal_thought": {
    "user_vibe": "LOW",
    "man_behavior_analysis": "He is in Efficiency mode - comfortable, not chasing.",
    "strategy_selection": "Scarcity Principle"
  },
  "response": {
    "text": "He is testing your access. If you text him now, you confirm you are waiting.",
    "options": [
      {
        "label": "Option A: Strategic Silence",
        "action": "Do nothing. Let him come to you.",
        "predicted_outcome": "He wonders where you went. Biology kicks in."
      },
      {
        "label": "Option B: Break the Silence",
        "action": "Text him something casual.",
        "predicted_outcome": "He knows he has you. Stays in Efficiency."
      }
    ]
  }
}
```

**Options rules:** Default is empty `[]`. Only populated when user explicitly asks for a decision AND there are exactly two clear actions.

**Flexible decoding (v2.2 stability fixes):**
- `internal_thought`: Can be Object (expected) or String (fallback)
- `response`: Can be Object (expected) or String (fallback)
- `response.text`: Tries `"text"` key, falls back to `"advice"` key
- `options[].outcome`: Tries `"outcome"` key, falls back to `"predicted_outcome"` key
- Markdown wrapper stripping (`\`\`\`json ... \`\`\``)

#### Phase 3: Render

The `ChatViewModel` creates a `Message` with:
- `text`: The strategist's `response.text`
- `routerMetadata`: Stringified internal thought + router mode
- `contentType`: `.text` or `.optionPair` (if options present)
- `options`: The strategy options array (if present)

### V1 Legacy Pipeline (Fallback)

**Service method:** `GeminiService.sendMessage()`
**System prompt:** `buildPersonalizedPrompt()` output (Prompts.chloeSystem with template vars)
**Temperature:** 0.8
**Max tokens:** 1024
**Output:** Plain text (no JSON parsing)

**Context injection:**
- `userFacts` appended to system instruction
- `lastSummary` injected as `<session_context>` on first message
- `insight` injected as `<internal_insight>` on subsequent messages
- Behavioral loops injected as `<known_patterns>`

### Background Analysis (The Analyst)

**Triggered:** Every 3 user messages (counter in `messages_since_analysis`) OR when app enters background
**Service method:** `GeminiService.analyzeConversation()`
**System prompt:** `Prompts.analyst`
**Temperature:** 0.2 (deterministic)
**Output format:** `application/json` (forced)

**Input:** Full conversation text + context dossier (user name, current vibe, known facts, last summary)

**Output JSON:**
```json
{
  "vibe_score": "LOW",
  "vibe_reasoning": "User is in Efficiency Mode, over-functioning",
  "new_facts": [{ "fact": "Target name is Brad", "category": "RELATIONSHIP_HISTORY" }],
  "behavioral_loops_detected": ["She rewards low effort with high attention"],
  "session_summary": "User is spiraling about a man who hasn't texted in 3 days.",
  "engagement_opportunity": {
    "trigger_notification": true,
    "notification_text": "Hey - did he ever text back? I'm curious.",
    "pattern_detected": "Tends to over-analyze silence"
  }
}
```

**What happens with analysis results:**
1. `vibe_score` → saved to `latestVibe` (used for mode gating)
2. `session_summary` → saved to `latestSummary` (used for session handover)
3. `new_facts` → merged into `user_facts` (deduplicated by fact text)
4. `behavioral_loops_detected` → pushed to insight queue (short-term) AND persisted to `profile.behavioralLoops` (long-term, capped at 20)
5. `engagement_opportunity` → schedules push notification if `trigger_notification` is true

### Affirmation Generation

**Service method:** `GeminiService.generateAffirmation()`
**System prompt:** `Prompts.affirmationTemplate` (with template vars)
**Temperature:** 0.9 (creative)
**Max tokens:** 256
**Triggered:** On app open (scheduled as next-day push notification)

### Title Generation

**Service method:** `GeminiService.generateTitle()`
**Prompt:** `Prompts.titleGeneration` — "Summarize this message in 3-5 words"
**Temperature:** 0.3 (deterministic)
**Max tokens:** 32
**Triggered:** After first user message in a new conversation

### Portkey Gateway (Optional)

When `PORTKEY_API_KEY` and `PORTKEY_VIRTUAL_KEY` are configured:
- V1 chat calls route through `PortkeyService.chat()` instead of direct Gemini
- Uses OpenAI-compatible format (`/v1/chat/completions`)
- Model format: `@{virtualKey}/gemini-2.0-flash`
- Captures `x-portkey-trace-id` for feedback correlation
- **Limitation:** Images are NOT supported via Portkey gateway (text-only fallback)
- Feedback (thumbs up/down) sent to Portkey's `/v1/feedback` endpoint

### Image Handling

- Images are resized to max 1024px dimension before upload
- JPEG compression at 0.8 quality
- Only the LATEST message's image is sent as inline base64 to Gemini
- Previous messages' images are replaced with `[User shared an image]` text

---

## 5. AUTH & USER LIFECYCLE

### Auth State Machine

`AuthViewModel` manages authentication through a clean state machine:

```
AuthState:
  .unauthenticated     → Sign in/sign up screen
  .authenticating      → Loading spinner
  .awaitingEmailConfirmation(email) → Check email screen
  .settingNewPassword  → New password form
  .authenticated       → Main app (Sanctuary)
```

### Auth Flow Diagram

```
App Launch
    │
    ├─ restoreSession()
    │   ├─ Valid session found?
    │   │   ├─ YES: Check pendingPasswordRecovery flag
    │   │   │   ├─ YES → .settingNewPassword
    │   │   │   └─ NO → fetchProfile from cloud → .authenticated → syncFromCloud()
    │   │   └─ NO: Check local profile exists?
    │   │       ├─ YES (with email) → .authenticated (local fallback)
    │   │       └─ NO → .unauthenticated
    │
Sign In (email + password)
    │
    ├─ .authenticating
    ├─ supabase.auth.signIn()
    ├─ Fetch remote profile (preserves onboardingComplete)
    ├─ Check isBlocked → if true, .unauthenticated + error
    ├─ .authenticated
    └─ Background: syncFromCloud()

Sign Up (email + password)
    │
    ├─ .authenticating
    ├─ supabase.auth.signUp(redirectTo: chloeapp://auth-callback)
    ├─ Session returned? (no email confirmation needed)
    │   ├─ YES → .authenticated
    │   └─ NO → .awaitingEmailConfirmation(email)
    │       └─ User clicks email link → auth-redirect → deep link → .authenticated

Password Reset
    │
    ├─ Set awaitingPasswordReset flag in UserDefaults
    ├─ supabase.auth.resetPasswordForEmail(redirectTo: chloeapp://auth-callback)
    ├─ User clicks email link → deep link received
    ├─ awaitingPasswordReset flag detected → transfer to pendingPasswordRecovery
    ├─ restoreSession() sees pendingPasswordRecovery → .settingNewPassword
    ├─ User enters new password → supabase.auth.update()
    └─ .authenticated → syncFromCloud()

Sign Out
    │
    ├─ supabase.auth.signOut()
    ├─ SyncDataService.clearAll() (local only — cloud preserved)
    ├─ Clear UserDefaults flags
    └─ .unauthenticated
```

### Deep Link Handling

**URL scheme:** `chloeapp://auth-callback`

`ChloeApp.swift` handles `onOpenURL`:
1. Checks `awaitingPasswordReset` flag in UserDefaults
2. If true: sets `pendingPasswordRecovery` flag, clears `awaitingPasswordReset`
3. Calls `supabase.auth.session(from: url)` to establish session
4. Posts `.authDeepLinkReceived` notification

**auth-redirect flow:**
- Supabase sends email with link to Vercel-hosted `auth-redirect/index.html`
- Page extracts `token_hash` and `type` from URL params
- Exchanges token via Supabase verify endpoint
- Redirects to `chloeapp://auth-callback` with access/refresh tokens

### Auth State Listener

`AuthViewModel` subscribes to `supabase.auth.authStateChanges`:
- `.passwordRecovery` → `.settingNewPassword`
- `.signedIn` (while `.awaitingEmailConfirmation`) → `.authenticated`
- `.signedOut` → `.unauthenticated`

### Profile Sync on Auth

On sign in / session restore:
1. Fetch remote profile from Supabase FIRST
2. If found: save to local (preserves `onboardingComplete` for returning users)
3. If not found: create local placeholder with `updatedAt = .distantPast` (so cloud wins during sync)
4. Check `isBlocked` — if true, sign out and show error

### User Blocking

Profile has `isBlocked`, `blockedAt`, `blockedReason` fields.
- Checked on sign in, session restore, and after background sync
- If blocked: `authState = .unauthenticated`, error = "Your account has been suspended. Contact support@chloe.app"

### Onboarding Flow

4 steps managed by `OnboardingViewModel`:

1. **Welcome** (`WelcomeIntroView`) — App introduction
2. **Name** (`NameStepView`) — Enter display name
3. **Archetype Quiz** (`ArchetypeQuizView`) — 7 questions to classify archetype
4. **Complete** (`OnboardingCompleteView`) — Reveal archetype result + confetti

On completion:
- `profile.onboardingComplete = true`
- `profile.preferences` = quiz answers + name
- Profile saved via `SyncDataService` (pushes to cloud)
- Posts `.onboardingDidComplete` notification
- ContentView transitions to SanctuaryView
- Shows `NotificationPrimingView` sheet (if not shown before)

---

## 6. DATA SYNC SYSTEM

### Architecture

```
┌──────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  UI / VMs    │ ──> │ SyncDataService  │ ──> │ StorageService   │ (UserDefaults)
│              │     │ (Orchestrator)   │ ──> │ SupabaseDataSvc  │ (Cloud)
│              │ <── │                  │     │ NetworkMonitor   │
└──────────────┘     └──────────────────┘     └─────────────────┘
```

**Principle:** All reads are LOCAL (instant). All writes go local FIRST, then async push to cloud.

### SyncDataService (775 lines)

The central orchestrator. Wraps `StorageService` (local) + `SupabaseDataService` (remote).

**Key behaviors:**

1. **Write path:** `save*(item)` → local save → fire-and-forget cloud push
2. **Read path:** `load*()` → returns from local only
3. **Delete path:** `delete*(id)` → requires network (returns `false` if offline to prevent orphaned cloud data)
4. **Offline queue:** `hasPendingChanges` flag. On reconnect (`NetworkMonitor.didReconnect`), calls `pushAllToCloud()`
5. **Thread safety:**
   - `SyncLock` actor prevents concurrent `syncFromCloud()` calls
   - `NSLock` protects `hasPendingChanges` flag
   - `inflightTasks` array tracks fire-and-forget cloud tasks, cancelled on sign-out

### syncFromCloud() — Full Sync on App Launch

Called on sign in and session restore. Runs as background task.

**Merge strategies by table:**

| Data | Strategy | Details |
|---|---|---|
| Profile | Server wins if newer | Compare `updatedAt` timestamps |
| Conversations | Server wins if newer + union by ID | New convos from cloud added, existing updated if remote newer |
| Messages | Union by ID | New messages from cloud appended, sorted by `createdAt` |
| User state | Server wins if newer | Compare usage date, last active date |
| Journal entries | Union by ID | New entries from cloud added |
| Goals | Server wins if newer | Compare `updatedAt` timestamps per goal |
| Affirmations | Union by ID | New affirmations from cloud added |
| Vision items | Union by ID + download images | Remote storage paths downloaded to local file |
| User facts | Union by ID | New facts from cloud added |

**Post-sync:** Posts `.profileDidSyncFromCloud` notification (ContentView re-checks onboarding status).

### StorageService (392 lines)

Local persistence layer using `UserDefaults` with JSON encoding.

**Storage keys:**
| Key | Type | Content |
|---|---|---|
| `profile` | Data (JSON) | Profile struct |
| `conversations` | Data (JSON) | [Conversation] array |
| `messages_{conversationId}` | Data (JSON) | [Message] array per conversation |
| `journal_entries` | Data (JSON) | [JournalEntry] array |
| `goals` | Data (JSON) | [Goal] array |
| `affirmations` | Data (JSON) | [Affirmation] array |
| `vision_items` | Data (JSON) | [VisionItem] array |
| `user_facts` | Data (JSON) | [UserFact] array |
| `latest_vibe` | String | VibeScore raw value |
| `daily_usage` | Data (JSON) | DailyUsage struct |
| `messages_since_analysis` | Int | Counter (0-3) |
| `glow_up_streak` | Data (JSON) | GlowUpStreak struct |
| `latest_summary` | String | Session summary text |
| `insight_queue` | Data (JSON) | [InsightEntry] array (FIFO) |
| `generic_notif_count` | Int | Weekly notification counter |
| `notif_week_start` | Date | Week start for reset |
| `notification_priming_shown` | Bool | One-time flag |
| `notification_denied_after_priming` | Bool | User declined notifications |

**Insight Queue (FIFO):**
- `pushInsight()` — Deduplicates by case-insensitive substring match
- `popInsight()` — Returns oldest non-expired entry (14-day expiry)
- Used for behavioral patterns and analyst insights that Chloe surfaces later

**Date encoding:** ISO 8601 (`encoder.dateEncodingStrategy = .iso8601`)

### File Storage

Images are saved to the Documents directory:
- Chat images: `chat_{uuid}.jpg` (JPEG 0.7 quality, downsampled)
- Profile images: `profile_image.jpg`
- Vision images: `vision_{itemId}.jpg`

### clearAll() vs deleteAccount()

| Method | Local | Cloud | When |
|---|---|---|---|
| `clearAll()` | Clears all UserDefaults + message keys | Preserved | Sign out |
| `deleteAccount()` | Clears all | Deletes via `SupabaseDataService.deleteAllUserData()` | Explicit delete account |

### Behavioral Loops

Permanent storage of AI-detected behavioral patterns:
- Stored in `profile.behavioralLoops: [String]?`
- Added via `addBehavioralLoops()` with:
  - Case-insensitive deduplication (exact + substring match)
  - Cap at 20 entries (oldest dropped)
- Injected into Strategist prompt as `<known_patterns>` for long-term strategy

---

## 7. UI & DESIGN SYSTEM

### Color Palette

All colors are adaptive (light/dark mode) defined in `Colors.swift`:

| Token | Light | Dark | Usage |
|---|---|---|---|
| `chloeBackground` | #FFF8F0 | #1A1517 | App background |
| `chloeSurface` | #FAFAFA | #241E20 | Card/surface |
| `chloePrimary` | #B76E79 | #C4848D | Rose gold accent |
| `chloePrimaryLight` | #FFF0EB | #2D2226 | Light primary tint |
| `chloePrimaryDark` | #8A4A55 | #A66E72 | Dark primary |
| `chloeAccent` | #F4A896 | #D4907E | Warm accent |
| `chloeAccentMuted` | #E8B4A8 | #8E6E66 | Muted accent |
| `chloeTextPrimary` | #2D2324 | #F5F0EB | Primary text |
| `chloeTextSecondary` | #6B6B6B | #B8A5A7 | Secondary text |
| `chloeTextTertiary` | #9A9A9A | #7A6E70 | Tertiary/hint text |
| `chloeBorder` | #E5E5E5 | #3A3234 | Borders |
| `chloeBorderWarm` | #F0E0DA | #3D2E30 | Warm borders |
| `chloeUserBubble` | #F0F0F0 | #2A2325 | User message bubble |
| `chloeGradientStart` | #FFF8F5 | #1A1517 | Background gradient top |
| `chloeGradientEnd` | #FEEAE2 | #221A1C | Background gradient bottom |
| `chloeRosewood` | #8E5A5E | #A66E72 | Deep rose accent |
| `chloeEtherealGold` | #F3E5AB | #8B7B4A | Gold accent |

**Gradient:** `chloeHeadingGradient` — Primary → Accent (leading → trailing)

### Typography

**Custom Fonts (registered in Info.plist):**
| Font Name | File | Usage |
|---|---|---|
| CormorantGaramond-BoldItalic | CormorantGaramond-BoldItalic.ttf | Hero/greeting text |
| Cinzel-Regular | Cinzel-Regular.ttf | Headers, buttons, section labels |
| PlayfairDisplay-Italic | PlayfairDisplay-Italic-VF.ttf | Editorial headings |
| TenorSans-Regular | TenorSans-Regular.ttf | Registered but unused |

**Semantic Font Tokens (Dynamic Type aware):**

| Token | Definition | Usage |
|---|---|---|
| `.chloeLargeTitle` | System .largeTitle, medium | Large titles |
| `.chloeTitle` | System .title, medium | Titles |
| `.chloeTitle2` | System .title2 | Subtitles |
| `.chloeHeadline` | System .headline, medium | Headlines |
| `.chloeSubheadline` | System .subheadline, medium | Subheadlines |
| `.chloeBodyDefault` | System .body | Body text |
| `.chloeBodyLight` | System .body, light | Light body |
| `.chloeCaption` | System .footnote | Captions |
| `.chloeCaptionLight` | System .footnote, light | Light captions |
| `.chloeProgressLabel` | System .caption2, light | Progress labels |
| `.chloeButton` | Cinzel 15pt, relativeTo .subheadline | Buttons |
| `.chloeGreeting` | Cormorant 38pt, relativeTo .largeTitle | Greeting text |
| `.chloeStatus` | Cinzel 11pt, relativeTo .caption2 | Status labels |
| `.chloeSidebarAppName` | Cormorant 24pt, relativeTo .title | Sidebar app name |
| `.chloeSidebarSectionHeader` | Cinzel 11pt, relativeTo .caption2 | Sidebar headers |
| `.chloeSidebarMenuItem` | Cinzel 14pt, relativeTo .footnote | Sidebar items |
| `.chloeSidebarChatItem` | System .footnote | Sidebar chat items |
| `.chloeOnboardingQuestion` | Cormorant 40pt, relativeTo .largeTitle | Quiz questions |

**Typography Modifiers:**

| Modifier | Effect |
|---|---|
| `.chloeEditorialHeading()` | Cormorant 40pt + gradient foreground (rose-to-dark) + shadow |
| `.chloeHeroStyle()` | Cormorant 38pt + negative tracking (-2%) |
| `.chloeSecondaryHeaderStyle()` | Cinzel 11pt + tracking(3) + uppercase |
| `.chloeBodyStyle()` | System body + 50% line spacing |
| `.chloeCaptionStyle()` | System footnote + 50% line spacing |
| `.chloeButtonTextStyle()` | Cinzel 15pt + tracking(3) |

### Spacing System

Defined in `Spacing.swift`:

| Token | Value | Usage |
|---|---|---|
| `xxxs` | 4pt | Micro spacing |
| `xxs` | 8pt | Base unit |
| `xs` | 12pt | Small spacing |
| `sm` | 16pt | Standard padding |
| `md` | 20pt | Medium spacing |
| `lg` | 24pt | Large spacing |
| `xl` | 32pt | Extra large |
| `xxl` | 40pt | Section gaps |
| `xxxl` | 48pt | Major sections |
| `huge` | 64pt | Hero spacing |
| `screenHorizontal` | 20pt | Screen edge padding |
| `cardPadding` | 16pt | Card internal padding |
| `cornerRadius` | 12pt | Standard corners |
| `cornerRadiusLarge` | 20pt | Large corners |
| `orbSize` | 80pt | Default orb diameter |
| `orbSizeSanctuary` | 160pt | Sanctuary orb diameter |
| `sanctuaryOrbY` | 0.25 | Orb vertical position (screen fraction) |

**Animation:**
```swift
Spacing.chloeSpring = Animation.spring(response: 0.45, dampingFraction: 0.8)
```

### Key UI Components

**ChloeAvatar / LuminousOrb:** Animated glowing orb that serves as Chloe's visual representation. Pulsates when "thinking" (isTyping). Uses `OrbStardustEmitter` for particle effects and `EtherealDustParticles` for ambient dust.

**ChatBubble:** Message bubble with:
- User messages: right-aligned, `chloeUserBubble` background
- Chloe messages: left-aligned, `chloePrimaryLight` background
- Feedback buttons (thumbs up/down) on Chloe messages
- Report button
- Strategy options (V2) via `StrategyOptionsView`
- Image display support

**ChatInputBar:** Text field with:
- Plus menu (PlusBloomMenu): Camera, photo picker, file import
- Recents button (recent conversations sheet)
- Send button (visible when text entered)

**SanctuaryView (802 lines):** The main screen with two states:
1. **Idle layout:** Orb + greeting + status text + ghost messages (last 2 messages from recent convo) + input bar
2. **Chat layout:** ScrollView of ChatBubbles + typing indicator + input bar + error bar

Also includes:
- Sidebar (slide-in from left, edge swipe gesture)
- Navigation to: Settings, Journal, History, Vision Board, Goals, Affirmations
- Photo picker, camera, file importer for image upload
- Recents sheet (recent conversations)
- Report sheet (report AI message)
- Recharging card (shown when rate limit reached)

**SidebarView:** Navigation drawer with:
- Profile image + name
- App name (Cinzel font)
- Menu items: Sanctuary, Journal, History, Vision Board, Goals, Affirmations, Settings
- Recent conversations list
- Vibe indicator + streak display
- New chat button

### Screen Flow

```
ContentView (Root Router)
├── EmailLoginView (unauthenticated)
│   ├── PasswordResetView (forgot password)
│   └── EmailConfirmationView (awaiting confirmation)
├── NewPasswordView (setting new password)
├── OnboardingContainerView (authenticated, !onboardingComplete)
│   ├── WelcomeIntroView (step 0)
│   ├── NameStepView (step 1)
│   ├── ArchetypeQuizView (step 2)
│   └── OnboardingCompleteView (step 3)
└── SanctuaryView (authenticated + onboardingComplete)
    ├── SidebarView (slide-in drawer)
    ├── JournalView → JournalDetailView / JournalEntryEditorView
    ├── HistoryView
    ├── VisionBoardView → AddVisionSheet
    ├── GoalsView
    ├── AffirmationsView
    └── SettingsView
```

---

## 8. CHLOE'S PERSONALITY SYSTEM

### Identity

Chloe is a "Big Sister" and High-Value Dating Strategist. She is NOT a therapist — she is a MIRROR. Her goal is not to make the user feel "better" in the moment but to make her MAGNETIC in the long run.

### The Chloe Framework (Core Philosophy)

Three immutable laws that govern all romantic relationship advice:

**1. The Biology vs Efficiency Rule**
- Men have two modes:
  - **EFFICIENCY:** Comfortable, autopilot. User is useful (cooking, planning). She is a "Placeholder."
  - **BIOLOGY:** Anxious, hunting. User is out of reach. She is the "Prize."
- Chloe's job: Push the man from Efficiency → Biology
- Trigger: If user is "doing the work" (texting first, planning), she's in Efficiency

**2. The Decentering Principle**
- Men are not the sun; they are the weather. The user is the sun.
- If she's spiraling: "Why is he the main character in your movie right now?"

**3. The Multiplier Effect**
- Women multiply what they receive. If he gives nothing, multiply it by doing nothing ("The Rot").

### Contextual Application Logic

The framework is NOT applied uniformly:

| Context | Application |
|---|---|
| **Romantic/Dating** | Full framework (Biology, Efficiency, Decentering, Multiplier) |
| **Career/Self** | Boss/Hype mode — drop dating frameworks entirely |
| **Friendship/Family** | Light Decentering only — HARD BAN on Biology, Efficiency, Rot, Placeholder |
| **Ambiguous** | Ask one clarifying question first |

### Archetype System

7 archetypes classified via a quiz during onboarding:

| Archetype | Strategy | Key Concept |
|---|---|---|
| **The Siren** | "The Pull" | "Absence creates obsession" — mystery, silence, visual cues |
| **The Queen** | "The Standard" | "The price of access went up" — firm boundaries, walk away |
| **The Muse** | "The Inspiration" | "Be the main character" — joy, creativity, happiness first |
| **The Lover** | "The Warmth" | "Soft heart, strong back" — vulnerability only after commitment |
| **The Sage** | "The Truth" | "Observe him like a science experiment" — analytical, pattern-watching |
| **The Rebel** | "The Disruption" | "Do the opposite" — breaking rules, unpredictability |
| **The Warrior** | "The Mission" | "Eyes on the prize, not the guy" — goals, self-improvement |

Archetype classification is done client-side by `ArchetypeService` based on 7 quiz answers stored in `OnboardingPreferences.archetypeAnswers`.

### Vibe Scoring & Mode Gating

The Analyst assigns a vibe score: `LOW`, `MEDIUM`, `HIGH`

**Deterministic mode selection (Swift code, not LLM):**

| Vibe Score | Mode | Behavior |
|---|---|---|
| `LOW` | THE BIG SISTER (100%) | Warmth, validation, supportive, no tough love |
| `MEDIUM` | THE BIG SISTER (70%) / THE SIREN (30%) | Balanced — mostly supportive with occasional challenge |
| `HIGH` | THE SIREN (70%) / THE GIRL (30%) | Tough love + chaotic bestie energy |

**Mode behaviors:**
- **THE BIG SISTER:** Prioritize warmth and validation. Be supportive. No tough love.
- **THE SIREN:** Tough love. Challenge scarcity mindset. Be direct.
- **THE GIRL:** Unhinged, funny, chaotic-bestie. Memes-in-text, dramatic reactions, ALL CAPS, gen-z slang. "Bestie who is three glasses of wine deep." NO serious coaching.
- **GENTLE SUPPORT:** Soft spiral override. DROP all frameworks. Be "The Anchor." Validate without fixing. End with ONE gentle micro-task.

### Vocabulary Control

**Hard rule:** At most ONE "Chloe-ism" per message.

Chloe-isms: Rot, Placeholder, Decenter, Efficiency, Biology, Triple Threat, Rebrand in Silence, The Bar is Hell

**Rotation required:**
- "Rot" → "pull back", "go silent", "starve him out"
- "Placeholder" → "backup option", "convenience", "Plan B girl"
- "Decenter" → "stop making him the main character"
- If forced, drop it. Vibe > vocabulary.

### Engagement Hooks

**Open Loop (70% of conversations):**
End with a micro-task or teaser: "Go drink some water. And update me the SECOND he texts back."
Skip if conversation is very short (<3 exchanges) or user says goodbye.

**Memory Drops:**
Casually reference known user facts: "This is just like that time you were stressing about the job interview."
Only reference still-relevant facts.

### Privacy Protocol (The Glass Wall)

Chloe CANNOT see the user's Journal or Vision Board unless they explicitly paste content in chat.
Response if referenced: "I can't see your journal, babe. Share it here if you want the tea."

### Safety System

**Three-tier safety:**

1. **Crisis Detection (client-side, BEFORE AI call)**
   - Regex patterns in `SafetyService.swift`
   - Self-harm: 13 patterns (suicide, self-harm, overdose, etc.)
   - Abuse: 8 patterns (domestic violence, sexual assault, etc.)
   - Severe mental health: 6 patterns (psychosis, hearing voices, etc.)
   - If matched: AI call BLOCKED, hardcoded crisis response returned immediately

2. **Soft Spiral Detection (client-side)**
   - 19 patterns for emotional numbness/shutdown (feeling numb, can't get out of bed, etc.)
   - Does NOT block AI call — instead overrides mode to GENTLE SUPPORT
   - Injected as `<soft_spiral_override>` into Strategist prompt

3. **Router Safety Override (V2 only)**
   - If Router classifies message as `SAFETY_RISK`, crisis response returned
   - Backup to client-side detection for messages that evade regex

**Crisis Responses (hardcoded, never AI-generated):**

| Crisis Type | Hotlines Provided |
|---|---|
| Self-harm | 988 Suicide & Crisis Lifeline, Crisis Text Line (741741) |
| Abuse | National DV Hotline (1-800-799-7233), Crisis Text Line |
| Severe mental health | 988, Crisis Text Line, SAMHSA (1-800-662-4357) |

### Output Rules

- NEVER expose internal labels (Open Loop, Memory Drop, mode_instruction, etc.)
- NEVER start with "As a [Archetype]..."
- NEVER use therapy-speak ("I validate you", "I understand that you are feeling...")
- DO use direct, punchy language: "He left you on read because he knows you're waiting. Put the phone down."

---

## 9. TEST COVERAGE MAP

### Unit Tests (14 files)

| Test File | Tests | What It Covers |
|---|---|---|
| `AnalystServiceTests.swift` | Analyst result parsing, fact merging | AnalystService, fact dedup |
| `AuthViewModelTests.swift` | Auth state transitions, sign in/out | AuthViewModel state machine |
| `ChatViewModelTests.swift` | Message sending, rate limiting, pipeline | ChatViewModel dual pipeline |
| `CrisisResponseTests.swift` | Crisis response lookup | CrisisResponses enum |
| `DailyUsageTests.swift` | Day reset, counter increment | DailyUsage model |
| `GeminiServiceTests.swift` | API request construction | GeminiService methods |
| `InsightQueueTests.swift` | FIFO push/pop, dedup, expiry | StorageService insight queue |
| `MessageModelTests.swift` | Message encoding/decoding, V2 fields | Message Codable conformance |
| `PromptBuilderTests.swift` | Template variable injection | buildPersonalizedPrompt() |
| `SafetyServiceTests.swift` | Crisis pattern matching, soft spiral | SafetyService regex patterns |
| `StorageServiceTests.swift` | Save/load round-trips | StorageService persistence |
| `StreakServiceTests.swift` | Streak increment, break, longest | StreakService logic |
| `SyncDataServiceTests.swift` | Sync merge strategies | SyncDataService merge |
| `V2AgenticTests.swift` | Router/Strategist JSON parsing | RouterModels decoding |

### UI Tests (17 files)

| Test File | Tests | What It Covers |
|---|---|---|
| `AffirmationsTests.swift` | Generate, view, favorite affirmation | AffirmationsView flow |
| `AuthenticationTests.swift` | Sign in, sign up, error states | EmailLoginView |
| `ConversationHistoryTests.swift` | View, star, rename, delete convos | HistoryView |
| `DynamicTypeTests.swift` | Text scaling at all accessibility sizes | Dynamic Type support |
| `EdgeCaseTests.swift` | Empty states, long text, rapid taps | Edge case handling |
| `GoalsTests.swift` | Create, complete, delete goals | GoalsView flow |
| `ImageUploadTests.swift` | Photo picker, camera, file import | Image upload flow |
| `JournalTests.swift` | Create, edit, delete journal entries | JournalView flow |
| `OnboardingTests.swift` | 4-step onboarding completion | Onboarding flow |
| `RateLimitTests.swift` | Message count, recharging card | Rate limiting UI |
| `SafetyTests.swift` | Crisis message detection + response | Safety pipeline |
| `SanctuaryTests.swift` | Idle/chat layout, orb, greeting | SanctuaryView |
| `SettingsTests.swift` | Theme toggle, sign out, delete account | SettingsView |
| `SidebarTests.swift` | Open/close, navigation, edge swipe | SidebarView |
| `StreakUITests.swift` | Streak display, increment | Streak UI |
| `TestHelpers.swift` | Shared test utilities | Helper functions |
| `VisionBoardTests.swift` | Add, view, delete vision items | VisionBoardView |

### Test Infrastructure

- **UITestSupport.swift:** Debug-only setup that checks `ProcessInfo.processInfo.arguments` for UI test flags
- **Test scheme:** `ChloeApp.xcscheme` with testable targets for both unit and UI tests
- **Build command:** `xcodebuild -project ChloeApp.xcodeproj -scheme ChloeApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet build`

### Coverage Gaps

1. **SupabaseDataService** — No unit tests (requires live Supabase connection)
2. **NetworkMonitor** — No unit tests (requires NWPathMonitor mocking)
3. **NotificationService** — No unit tests (requires UNUserNotificationCenter mocking)
4. **PortkeyService** — No unit tests
5. **FeedbackService** — No unit tests
6. **Image upload end-to-end** — UI tests exist but don't verify actual upload
7. **Offline sync flow** — No integration tests for reconnect → push behavior
8. **V2 Strategy Options** — No UI tests for option card rendering/selection

---

## 10. KNOWN REMAINING ISSUES

### Critical

| # | Issue | Location | Impact |
|---|---|---|---|
| 1 | **TOCTOU on StorageService** | `StorageService.swift` | Time-of-check-time-of-use race condition on concurrent reads/writes to UserDefaults. Two ViewModels could load stale data. |
| 2 | **Missing CASUAL router category** | `RouterModels.swift:6-12` | `RouterCategory` enum has no `CASUAL` case. General chat gets misclassified as `SELF_IMPROVEMENT` or `DATING_EARLY`, causing inappropriate framework application. |
| 3 | **Feedback RLS performance** | Supabase `feedback` table | RLS policies use `auth.uid()` without `(SELECT ...)` wrapper — function called per-row instead of once. Also missing index on `user_id` FK. |
| 4 | **Leaked password protection disabled** | Supabase Auth config | Supabase security advisor flagged this. Users can sign up with known-leaked passwords. |

### High Priority

| # | Issue | Location | Impact |
|---|---|---|---|
| 5 | **Vision item file path leak** | `SyncDataService.swift:273-289` | Local file paths stored in `imageUri` may leak to cloud if synced before download completes. Cloud sync downloads by checking if path exists locally. |
| 6 | **iPad target missing** | `ChloeApp.xcodeproj` | No iPad-specific layout. App runs in compatibility mode on iPad. |
| 7 | **Keychain migration needed** | `StorageService.swift` | All data in UserDefaults, which is not encrypted at rest. Sensitive data (API state, tokens) should use Keychain. |
| 8 | **Portkey images not supported** | `GeminiService.swift:170-176` | When Portkey is configured, images are converted to `[Image]` text. Users lose image analysis when Portkey is active. |

### Medium Priority

| # | Issue | Location | Impact |
|---|---|---|---|
| 9 | **Dynamic Type incomplete** | `DynamicTypeTests.swift` | Some custom font sizes don't fully scale at extreme accessibility sizes. `relativeTo:` helps but fixed sizes in components may clip. |
| 10 | **Canvas animation optimization** | `LuminousOrb.swift`, `EtherealDustParticles.swift` | Particle emitters run continuously. No mechanism to pause when off-screen or app backgrounded. |
| 11 | **TelemetryDeck not wired** | `GeminiService.swift:356` | TelemetryDeck SPM dependency added but signal calls are commented out. No analytics being collected. |
| 12 | **ExyteChat unused** | `Package.resolved` | SPM dependency exists but entire chat UI is custom-built. Dead dependency increasing bundle size. |
| 13 | **Feedback with_check missing** | Supabase RLS | Feedback INSERT policy has with_check but other table policies have null with_check clauses. |
| 14 | **Paywall not implemented** | `SanctuaryView.swift:574` | "Unlock Unlimited" button has `// TODO: Navigate to paywall / premium purchase` |
| 15 | **UserDefaults data limits** | `StorageService.swift` | UserDefaults not designed for large datasets. Heavy users with many conversations may hit performance issues. Consider migrating to SwiftData or SQLite. |

---

## 11. MONETIZATION STATE

### Current State: PRE-MONETIZATION

**All users get premium access in DEBUG builds.** In Release builds, rate limiting is active but there is no paywall.

### Rate Limiting

```swift
// Prompts.swift:6-10
#if DEBUG
let V1_PREMIUM_FOR_ALL = true   // All users are premium in DEBUG
#else
let V1_PREMIUM_FOR_ALL = false  // Rate limiting active in Release
#endif

let FREE_DAILY_MESSAGE_LIMIT = 5   // 5 messages per day for free users
```

**Flow:**
1. Each message increments `DailyUsage.messageCount`
2. At message 5 (the last free message): Chloe sends a warm goodbye message after 1.5s delay
3. At message 6 attempt: `isLimitReached = true`, input bar replaced with "Recharging Card"
4. Recharging Card shows "Chloe is recharging" + "Unlock Unlimited" button (TODO: no action)
5. Counter resets daily (checked by comparing `DailyUsage.date` to today)

### Subscription Model

```swift
// Profile.swift:52-55
enum SubscriptionTier: String, Codable {
    case free
    case premium
}
```

Profile has `subscriptionTier` (default: `.free`) and `subscriptionExpiresAt` fields.
Currently, no code checks `subscriptionExpiresAt` or manages subscription lifecycle.

### What's Missing for Monetization

1. **No paywall UI** — "Unlock Unlimited" button is a no-op
2. **No StoreKit integration** — No in-app purchase flow
3. **No subscription management** — No restore, cancel, or expiration handling
4. **No server-side receipt validation** — `subscription_tier` is client-settable (security risk)
5. **No tiered features** — No feature gating beyond message limit
6. **No analytics** — TelemetryDeck is added but not wired
7. **No conversion funnel** — No tracking of free→premium journey

### Revenue Opportunities Identified

1. **Message limit upsell** — Already built (recharging card). Just needs StoreKit.
2. **Daily affirmation premium** — Could limit free users to 1/week
3. **Vision board images** — Could limit free users to 3 items
4. **Advanced analysis** — Could gate behavioral loops / deep insights to premium
5. **Custom archetype coaching** — Premium users get archetype-specific deep dives

---

## 12. ENVIRONMENT & CONFIG

### Config.xcconfig

API keys are stored in `Config.xcconfig` and read via `Info.plist` → `Bundle.main.infoDictionary`:

```
GEMINI_API_KEY = {your-gemini-api-key}
SUPABASE_URL = https://xyzgolauwqaxugrphfbz.supabase.co
SUPABASE_ANON_KEY = {your-anon-key}
PORTKEY_API_KEY = {optional-portkey-key}
PORTKEY_VIRTUAL_KEY = {optional-portkey-virtual-key}
DEV_PASSWORD = {optional-dev-account-password}
```

### Info.plist Key Configuration

| Key | Value | Purpose |
|---|---|---|
| `GEMINI_API_KEY` | `$(GEMINI_API_KEY)` | Gemini REST API auth |
| `SUPABASE_URL` | `$(SUPABASE_URL)` | Supabase project URL |
| `SUPABASE_ANON_KEY` | `$(SUPABASE_ANON_KEY)` | Supabase anonymous key (for client) |
| `PORTKEY_API_KEY` | `$(PORTKEY_API_KEY)` | Portkey gateway API key |
| `PORTKEY_VIRTUAL_KEY` | `$(PORTKEY_VIRTUAL_KEY)` | Portkey virtual key for model routing |
| `DEV_PASSWORD` | `$(DEV_PASSWORD)` | Debug-only dev account password |
| `UIAppFonts` | Array of .ttf files | Custom font registration |
| `CFBundleURLTypes` | `chloeapp` scheme | Deep link URL scheme |

### SupabaseClient.swift

```swift
let supabase = SupabaseClient(
    supabaseURL: URL(string: Bundle.main.infoDictionary?["SUPABASE_URL"] as? String ?? "")!,
    supabaseKey: Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String ?? ""
)
```

### Build Verification

```bash
xcodebuild -project ChloeApp.xcodeproj -scheme ChloeApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -quiet build
```

### Debug Flags

| Flag | Location | Purpose |
|---|---|---|
| `V1_PREMIUM_FOR_ALL` | `Prompts.swift:7` | true in DEBUG, false in Release |
| `V2_AGENTIC_MODE` | `ChatViewModel.swift:5` | true — enables V2 agentic pipeline |
| `debugSkipToMain` | `ContentView.swift:10` | false — set true to bypass auth for UI testing |
| `UITestSupport` | `ChloeApp.swift:18` | Sets up test environment from launch arguments |

### Notification Categories

| Category | Trigger | Content |
|---|---|---|
| Affirmation | Scheduled next morning on app open | AI-generated daily affirmation |
| Engagement | After analyst detects unresolved thread | Contextual follow-up in Chloe's voice |
| Fallback vibe check | On app background | Generic "How are you doing?" with session context |
| Streak reminder | Managed by StreakService | "Don't break your streak!" |

**Rate limiting:** Max 3 generic notifications per week. Engagement notifications are separate.

### App Lifecycle (ChloeApp.swift)

| Phase | Action |
|---|---|
| `.active` | Cancel generic notifications; schedule affirmation if needed |
| `.background` | Schedule fallback vibe check; trigger pending analysis |
| `.inactive` | No action |
| `onOpenURL` | Handle deep link (auth callback) |

---

## 13. MISSION BRIEFS

### Mission Brief A: Web App Agent Swarm

**Objective:** Build a cross-platform web companion for ChloeApp using the Expo/React Native web app at `/chloe-in-your-pocket/`.

**Context the web agent MUST know:**

1. **Supabase is shared.** The web app uses the SAME Supabase backend (same tables, same RLS policies, same auth). Do NOT create new tables — extend existing ones if needed.

2. **Auth must be compatible.** The iOS app uses Supabase PKCE auth with `chloeapp://` deep links. The web app needs its own auth flow (likely standard Supabase email/password with web redirects). Same user account must work on both platforms.

3. **Data schema is the source of truth.** All 10 public tables (profiles, conversations, messages, user_facts, journal_entries, vision_board_items, goals, affirmations, user_state, feedback) are documented in Section 3. The web app reads/writes the same data.

4. **AI pipeline is server-side.** The web app should NOT call Gemini directly from the client. Set up a Supabase Edge Function or API route that mirrors `GeminiService.swift` logic (system prompts, safety checks, response parsing). Prompts are documented in Section 8.

5. **Rate limiting must be server-enforced.** iOS currently does client-side rate limiting (easily bypassed). The web app is the opportunity to move rate limiting to `user_state.message_count` checked server-side.

6. **V2 agentic pipeline is active.** The web app should implement the Router→Strategist→Analyst pipeline, not V1. JSON response parsing logic is in `RouterModels.swift` (Section 4).

7. **Safety is NON-NEGOTIABLE.** Port `SafetyService.swift` regex patterns to server-side. Crisis responses must be hardcoded (Section 8), never AI-generated.

8. **Design tokens are documented.** Colors, fonts, and spacing are in Section 7. The web app should use the same visual language.

### Mission Brief B: Analytics Agent Swarm

**Objective:** Wire up analytics and build a dashboard for user behavior insights.

**Context the analytics agent MUST know:**

1. **TelemetryDeck is added but not wired.** SPM dependency exists (v2.11.0). The `GeminiService.swift:356` has a commented-out `TelemetryDeck.signal()` call. Start there.

2. **Portkey is the AI analytics layer.** `PortkeyService.swift` captures `x-portkey-trace-id` for every AI call. Feedback (thumbs up/down) is already sent to Portkey's `/v1/feedback` endpoint. Build dashboards on Portkey's analytics.

3. **Key metrics to track:**
   - Daily/weekly active users
   - Messages per session
   - V2 pipeline success rate (JSON parse failures are retried — track retry rate)
   - Safety triggers (crisis type, frequency)
   - Vibe score distribution over time
   - Archetype distribution
   - Conversion: free message limit hits → premium (when paywall exists)
   - Feature usage: journal, vision board, goals, affirmations
   - Retention: streak lengths, return rate

4. **Feedback data is already in Supabase.** The `feedback` table captures message-level thumbs up/down and reports. Query this for response quality metrics.

5. **Analyst results contain rich data.** Every 3 messages, the Analyst extracts vibe scores, behavioral loops, and engagement opportunities. This data flows through `user_state` and `user_facts` tables.

6. **Privacy requirements:** Analytics must be GDPR-compliant. TelemetryDeck is privacy-focused by design. Do NOT send PII (names, message content) to analytics. Use hashed user IDs.

### Mission Brief C: Knowledge Base Agent Swarm

**Objective:** Build a content/knowledge system that enriches Chloe's responses with curated advice content.

**Context the knowledge agent MUST know:**

1. **Current state: Chloe relies entirely on prompts.** There is no RAG, no vector database, no content library. All knowledge comes from the system prompts in `Prompts.swift` (Section 8).

2. **The prompt framework is sacred.** The Biology/Efficiency/Decentering/Multiplier framework, archetype profiles, vocabulary control rules, and mode gating are the product's core IP. Any knowledge base must COMPLEMENT, not replace, these prompts.

3. **Opportunity areas:**
   - Curated article/tip library (organized by archetype + topic)
   - Scenario playbooks (what to text after being ghosted, first date prep, etc.)
   - Chloe-ism glossary with examples
   - Red flag / green flag pattern library
   - Book/podcast recommendations by archetype

4. **Integration point:** The Strategist prompt accepts injected context via XML tags. A knowledge base could inject relevant snippets as `<knowledge_context>` before the Strategist generates a response. Follow the pattern of `<router_context>`, `<known_patterns>`, etc.

5. **User facts are the personalization layer.** The `user_facts` table stores extracted facts categorized as `RELATIONSHIP_HISTORY`, `GOAL`, or `TRIGGER`. Knowledge base queries should use these facts for relevance ranking.

6. **Safety filter applies to knowledge too.** Any content served to users must pass the same safety checks. No content that normalizes abuse, self-harm, or toxic behavior.

### Mission Brief D: Monetization Agent Swarm

**Objective:** Implement the premium subscription system and paywall.

**Context the monetization agent MUST know:**

1. **Rate limiting is already built.** 5 free messages/day, recharging card shown on limit, "Unlock Unlimited" button is a no-op (Section 11).

2. **Subscription model exists in Profile.** `SubscriptionTier` enum (`.free` / `.premium`) and `subscriptionExpiresAt` date field are already in the Profile model and Supabase profiles table.

3. **The `V1_PREMIUM_FOR_ALL` flag is the kill switch.** Set to `true` in DEBUG, `false` in Release. When false, `ChatViewModel.swift:102` checks `profile?.subscriptionTier != .premium` before enforcing rate limits.

4. **StoreKit 2 integration needed:**
   - Auto-renewable subscription (monthly/annual)
   - Server-side receipt validation (Supabase Edge Function)
   - Restore purchases
   - Grace period handling
   - Subscription expiration check (currently `subscriptionExpiresAt` is unused)

5. **Server-side validation is critical.** Currently `subscription_tier` is client-writable (a user could set themselves to premium via Supabase client). Need server-side receipt validation that sets the tier.

6. **Paywall placement candidates:**
   - After 5th message (recharging card — already built)
   - After onboarding (archetype reveal → "Want deeper archetype coaching?")
   - Vision board (3 free items, then paywall)
   - Journal entries (limit to 5 free entries)
   - Behavioral loops / deep analysis (premium-only feature)

7. **Pricing research needed:** Competitive analysis of similar apps (Lovewick, Paired, Relish). Recommended starting point: $9.99/month or $59.99/year.

8. **A/B testing infrastructure:** Consider multiple paywall designs. Need analytics (Mission Brief B) before launching to measure conversion.

9. **Design the paywall to match the brand.** Use the design system from Section 7. Rose gold primary, Cinzel headers, Cormorant editorial text. The paywall should feel like a natural extension of the app, not a generic subscription screen.

10. **Apple App Store guidelines:** Ensure compliance with:
    - Auto-renewable subscription requirements
    - Restore purchases button requirement
    - Subscription management deep link
    - Clear pricing display
    - Free trial disclosure (if offering)

---

## APPENDIX A: MODEL DEFINITIONS

### Profile (Profile.swift)

```swift
struct Profile: Codable, Identifiable {
    let id: String                          // UUID, matches auth.users.id
    var email: String
    var displayName: String
    var onboardingComplete: Bool            // Gate for main app access
    var preferences: OnboardingPreferences? // Quiz answers
    var subscriptionTier: SubscriptionTier  // .free or .premium
    var subscriptionExpiresAt: Date?
    var profileImageUri: String?            // Local file path
    var isBlocked: Bool                     // Admin ban
    var blockedAt: Date?
    var blockedReason: String?
    var behavioralLoops: [String]?          // Permanent AI-detected patterns (cap: 20)
    var createdAt: Date
    var updatedAt: Date
}
```

### Message (Message.swift)

```swift
struct Message: Codable, Identifiable {
    let id: String                          // UUID
    var conversationId: String?
    var role: MessageRole                   // .user or .chloe
    var text: String
    var imageUri: String?                   // Local file path
    var createdAt: Date
    // V2 Agentic fields
    var routerMetadata: RouterMetadata?     // Internal thought + router mode
    var contentType: MessageContentType?    // .text or .optionPair
    var options: [StrategyOption]?          // V2 strategy options
}
```

### Conversation (Conversation.swift)

```swift
struct Conversation: Codable, Identifiable {
    let id: String                          // UUID
    var userId: String?
    var title: String                       // AI-generated (3-5 words)
    var starred: Bool
    var createdAt: Date
    var updatedAt: Date
}
```

### UserFact (Profile.swift)

```swift
struct UserFact: Codable, Identifiable {
    let id: String
    var userId: String?
    var fact: String                        // e.g. "Target name is Brad"
    var category: FactCategory             // RELATIONSHIP_HISTORY, GOAL, TRIGGER
    var sourceMessageId: String?
    var isActive: Bool                      // Soft delete
    var createdAt: Date
}
```

### DailyUsage (DailyUsage.swift)

```swift
struct DailyUsage: Codable {
    var date: String                        // "yyyy-MM-dd" format
    var messageCount: Int                   // Resets daily

    static func todayKey() -> String        // Returns today's date string
}
```

### GlowUpStreak (GlowUpStreak.swift)

```swift
struct GlowUpStreak: Codable {
    var currentStreak: Int                  // Days in a row
    var longestStreak: Int                  // All-time best
    var lastActiveDate: String              // "yyyy-MM-dd" format
}
```

### VibeScore

```swift
enum VibeScore: String, Codable {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
}
```

### RouterClassification (RouterModels.swift)

```swift
struct RouterClassification: Codable {
    var category: RouterCategory            // CRISIS_BREAKUP, DATING_EARLY, etc.
    var urgency: RouterUrgency              // LOW, MEDIUM, HIGH
    var reasoning: String
}
```

### StrategistResponse (RouterModels.swift)

```swift
struct StrategistResponse: Codable {
    var internalThought: InternalThought    // user_vibe, analysis, strategy
    var response: ResponseContent           // text + optional options
}

struct InternalThought: Codable {
    var userVibe: String
    var manBehaviorAnalysis: String
    var strategySelection: String
}

struct ResponseContent: Codable {
    var text: String                        // Chloe's visible response
    var options: [StrategyOption]?          // 0-2 strategy options
}

struct StrategyOption: Codable, Identifiable {
    var label: String                       // "Option A: Strategic Silence"
    var action: String                      // "Do nothing. Let him come to you."
    var outcome: String                     // "He wonders where you went."
}
```

### AnalystResult

```swift
struct AnalystResult: Codable {
    var vibeScore: VibeScore
    var vibeReasoning: String
    var facts: [ExtractedFact]
    var behavioralLoops: [String]
    var summary: String
    var engagementOpportunity: EngagementOpportunity?
}

struct ExtractedFact: Codable {
    var fact: String
    var category: FactCategory
}

struct EngagementOpportunity: Codable {
    var triggerNotification: Bool
    var notificationText: String?
    var patternDetected: String?
}
```

### Feedback (Feedback.swift)

```swift
struct Feedback: Codable {
    var id: String
    var userId: String?
    var messageId: String
    var conversationId: String
    var userMessage: String
    var aiResponse: String
    var rating: FeedbackRating             // .helpful, .notHelpful
    var reportReason: String?
    var reportDetails: String?
    var createdAt: Date
}

enum FeedbackRating: String, Codable {
    case helpful
    case notHelpful = "not_helpful"
}
```

---

## APPENDIX B: COMPLETE SYSTEM PROMPTS

### V1 System Prompt (Prompts.chloeSystem)

The full V1 system prompt is 168 lines. Key sections:
1. **ROLE & PERSONA** — "Big Sister" and High-Value Dating Strategist
2. **THE CHLOE FRAMEWORK** — Biology vs Efficiency, Decentering, Multiplier Effect
3. **Contextual Application Logic** — When to apply/skip framework
4. **USER CONTEXT** — Template variables ({{user_name}}, {{archetype_label}}, etc.)
5. **ARCHETYPE-SPECIFIC COACHING** — 7 archetype profiles
6. **VOICE & TONE** — Direct, punchy, no therapy-speak
7. **Vocabulary Control** — Max 1 Chloe-ism per message
8. **Mode Instruction** — BIG SISTER, SIREN, GIRL, or GENTLE SUPPORT
9. **Output Rules** — Never expose internal labels
10. **Engagement Hooks** — Open loops, memory drops
11. **Privacy Protocol** — Glass Wall (can't see journal/vision board)
12. **Safety Protocol** — Override on crisis
13. **Few-Shot Examples** — 3 example exchanges

### V2 Strategist Prompt (Prompts.strategist)

The full V2 strategist prompt is 219 lines. Key sections:
1. **ROLE** — Same identity as V1
2. **User Context** — Template variables
3. **Core Philosophy** — Biology/Efficiency, Game Theory, No-Cringe Policy
4. **Archetype Profiles** — 7 archetype strategies
5. **Output Protocol** — STRICT JSON format with internal_thought + response
6. **Options Rules** — When to return strategy options (default: empty)
7. **Few-Shot Examples** — 6 examples covering strategic fork, venting, info gathering, casual greeting, sharing, onboarding

### V2 Router Prompt (Prompts.router)

16 lines. Classifies into 5 categories + 3 urgency levels. Returns JSON only.

### Analyst Prompt (Prompts.analyst)

74 lines. Extracts vibe score, facts, behavioral loops, session summary, engagement opportunities. Returns JSON only.

### Affirmation Prompt (Prompts.affirmationTemplate)

56 lines. Generates 1-2 sentence affirmation based on archetype + vibe. Template variables for user name, archetype, current vibe.

### Title Generation Prompt (Prompts.titleGeneration)

1 line: "Summarize this message in 3-5 words as a short conversation title. Return only the title, nothing else."

### Template Variables

All prompts use `{{variable}}` syntax, replaced by `injectUserContext()`:

| Variable | Source | Fallback |
|---|---|---|
| `{{user_name}}` | `profile.displayName` | "babe" |
| `{{archetype_label}}` | `ArchetypeService.classify()` | "Not determined yet" |
| `{{archetype_blend}}` | `archetype.blend` | "Not determined yet" |
| `{{archetype_description}}` | `archetype.description` | "Not determined yet" |
| `{{relationship_status}}` | — | "Not shared yet" (always) |
| `{{current_vibe}}` | `latestVibe.rawValue` | "MEDIUM" |
| `{{vibe_mode}}` | Computed from vibe score | Deterministic (see Section 8) |

---

## APPENDIX C: SERVICE SINGLETON REGISTRY

All services are singletons accessed via `.shared`:

| Service | File | Lines | Responsibility |
|---|---|---|---|
| `GeminiService.shared` | GeminiService.swift | 575 | All Gemini API calls |
| `PortkeyService.shared` | PortkeyService.swift | 189 | Portkey gateway proxy |
| `StorageService.shared` | StorageService.swift | 392 | UserDefaults persistence |
| `SyncDataService.shared` | SyncDataService.swift | 775 | Offline-first sync orchestrator |
| `SupabaseDataService.shared` | SupabaseDataService.swift | ~400 | Supabase CRUD operations |
| `SafetyService.shared` | SafetyService.swift | 119 | Crisis + soft spiral detection |
| `AnalystService.shared` | AnalystService.swift | 49 | Background analysis wrapper |
| `ArchetypeService.shared` | ArchetypeService.swift | ~150 | Archetype quiz classification |
| `NotificationService.shared` | NotificationService.swift | ~200 | Push notification scheduling |
| `StreakService.shared` | StreakService.swift | ~100 | GlowUp streak logic |
| `FeedbackService.shared` | FeedbackService.swift | ~80 | Submit feedback to Supabase + Portkey |
| `NetworkMonitor.shared` | NetworkMonitor.swift | ~50 | NWPathMonitor connectivity |

---

## APPENDIX D: NOTIFICATION CENTER EVENTS

| Notification | Posted By | Consumed By | Purpose |
|---|---|---|---|
| `.appDidEnterBackground` | `ChloeApp.swift` | `ChatViewModel` | Trigger pending analysis |
| `.authDeepLinkReceived` | `ChloeApp.swift` | `AuthViewModel` | Re-check session after deep link |
| `.profileDidSyncFromCloud` | `SyncDataService` | `ContentView` | Re-check onboarding status |
| `.onboardingDidComplete` | `OnboardingViewModel` | `ContentView` | Transition to main app |

---

## APPENDIX E: USERDEFAULTS KEY REGISTRY

| Key | Type | Managed By | Purpose |
|---|---|---|---|
| `profile` | Data | StorageService | User profile JSON |
| `conversations` | Data | StorageService | Conversation list JSON |
| `messages_{id}` | Data | StorageService | Messages per conversation |
| `journal_entries` | Data | StorageService | Journal entries JSON |
| `goals` | Data | StorageService | Goals JSON |
| `affirmations` | Data | StorageService | Affirmations JSON |
| `vision_items` | Data | StorageService | Vision items JSON |
| `user_facts` | Data | StorageService | User facts JSON |
| `latest_vibe` | String | StorageService | VibeScore raw value |
| `daily_usage` | Data | StorageService | DailyUsage JSON |
| `messages_since_analysis` | Int | StorageService | Analysis trigger counter |
| `glow_up_streak` | Data | StorageService | GlowUpStreak JSON |
| `latest_summary` | String | StorageService | Session summary |
| `insight_queue` | Data | StorageService | InsightEntry FIFO queue |
| `generic_notif_count` | Int | StorageService | Weekly notification counter |
| `notif_week_start` | Date | StorageService | Week start for notification reset |
| `notification_priming_shown` | Bool | StorageService | One-time priming flag |
| `notification_denied_after_priming` | Bool | StorageService | User declined notifications |
| `isDarkMode` | Bool | @AppStorage | Dark mode toggle |
| `awaitingPasswordReset` | Bool | AuthViewModel | Password reset flow flag |
| `pendingPasswordRecovery` | Bool | ChloeApp/AuthVM | Recovery deep link flag |

---

# SECTION 14: VERBATIM MODEL DEFINITIONS

> Every struct, class, and enum used as a data model — exact Swift code.

## 14.1 Profile.swift

```swift
struct Profile: Codable, Identifiable {
    let id: String
    var email: String
    var displayName: String
    var onboardingComplete: Bool
    var preferences: OnboardingPreferences?
    var subscriptionTier: SubscriptionTier
    var subscriptionExpiresAt: Date?
    var profileImageUri: String?
    var isBlocked: Bool
    var blockedAt: Date?
    var blockedReason: String?
    var behavioralLoops: [String]?  // Permanent storage of detected behavioral patterns
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
        isBlocked: Bool = false,
        blockedAt: Date? = nil,
        blockedReason: String? = nil,
        behavioralLoops: [String]? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id.lowercased()
        self.email = email
        self.displayName = displayName
        self.onboardingComplete = onboardingComplete
        self.preferences = preferences
        self.subscriptionTier = subscriptionTier
        self.subscriptionExpiresAt = subscriptionExpiresAt
        self.profileImageUri = profileImageUri
        self.isBlocked = isBlocked
        self.blockedAt = blockedAt
        self.blockedReason = blockedReason
        self.behavioralLoops = behavioralLoops
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
        self.id = id.lowercased()
        self.userId = userId
        self.fact = fact
        self.category = category
        self.sourceMessageId = sourceMessageId
        self.isActive = isActive
        self.createdAt = createdAt
    }
}

enum FactCategory: String, Codable {
    case relationshipHistory = "RELATIONSHIP_HISTORY"
    case goal = "GOAL"
    case trigger = "TRIGGER"
}
```

## 14.2 Message.swift

```swift
struct Message: Codable, Identifiable {
    let id: String
    var conversationId: String?
    var role: MessageRole
    var text: String
    var imageUri: String?
    var createdAt: Date

    // v2 Agentic fields (nullable for backward compatibility)
    var routerMetadata: RouterMetadata?
    var contentType: MessageContentType?
    var options: [StrategyOption]?

    init(
        id: String = UUID().uuidString,
        conversationId: String? = nil,
        role: MessageRole,
        text: String,
        imageUri: String? = nil,
        createdAt: Date = Date(),
        routerMetadata: RouterMetadata? = nil,
        contentType: MessageContentType? = nil,
        options: [StrategyOption]? = nil
    ) {
        self.id = id.lowercased()
        self.conversationId = conversationId?.lowercased()
        self.role = role
        self.text = text
        self.imageUri = imageUri
        self.createdAt = createdAt
        self.routerMetadata = routerMetadata
        self.contentType = contentType
        self.options = options
    }
}

enum MessageRole: String, Codable {
    case user
    case chloe
}
```

## 14.3 Conversation.swift

```swift
struct Conversation: Codable, Identifiable {
    let id: String
    var userId: String?
    var title: String
    var starred: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String? = nil,
        title: String = "New Conversation",
        starred: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id.lowercased()
        self.userId = userId
        self.title = title
        self.starred = starred
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
```

## 14.4 OnboardingPreferences.swift

```swift
struct OnboardingPreferences: Codable {
    var onboardingCompleted: Bool
    var name: String?
    var archetypeAnswers: ArchetypeAnswers?

    init(
        onboardingCompleted: Bool = false,
        name: String? = nil,
        archetypeAnswers: ArchetypeAnswers? = nil
    ) {
        self.onboardingCompleted = onboardingCompleted
        self.name = name
        self.archetypeAnswers = archetypeAnswers
    }
}

enum VibeScore: String, Codable, CaseIterable {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
}

struct ArchetypeAnswers: Codable {
    var energy: ArchetypeChoice?
    var strength: ArchetypeChoice?
    var recharge: ArchetypeChoice?
    var allure: ArchetypeChoice?
}

enum ArchetypeChoice: String, Codable, CaseIterable {
    case a, b, c, d
}
```

## 14.5 Archetype.swift

```swift
enum ArchetypeId: String, Codable, CaseIterable {
    case siren
    case queen
    case muse
    case lover
    case sage
    case rebel
    case warrior
}

struct UserArchetype: Codable {
    var primary: ArchetypeId
    var secondary: ArchetypeId
    var label: String
    var blend: String
    var description: String
}

struct AnalystResult: Codable {
    var facts: [ExtractedFact]
    var vibeScore: VibeScore
    var vibeReason: String
    var behavioralLoops: [String]
    var summary: String
    var engagementOpportunity: EngagementOpportunity?

    enum CodingKeys: String, CodingKey {
        case facts = "new_facts"
        case vibeScore = "vibe_score"
        case vibeReason = "vibe_reasoning"
        case behavioralLoops = "behavioral_loops_detected"
        case summary = "session_summary"
        case engagementOpportunity = "engagement_opportunity"
    }

    init(
        facts: [ExtractedFact] = [],
        vibeScore: VibeScore = .medium,
        vibeReason: String = "",
        behavioralLoops: [String] = [],
        summary: String = "",
        engagementOpportunity: EngagementOpportunity? = nil
    ) {
        self.facts = facts
        self.vibeScore = vibeScore
        self.vibeReason = vibeReason
        self.behavioralLoops = behavioralLoops
        self.summary = summary
        self.engagementOpportunity = engagementOpportunity
    }
}

struct EngagementOpportunity: Codable {
    var triggerNotification: Bool
    var notificationText: String?
    var patternDetected: String?

    enum CodingKeys: String, CodingKey {
        case triggerNotification = "trigger_notification"
        case notificationText = "notification_text"
        case patternDetected = "pattern_detected"
    }
}

struct ExtractedFact: Codable {
    var fact: String
    var category: FactCategory
}
```

## 14.6 RouterModels.swift

```swift
enum RouterCategory: String, Codable {
    case crisisBreakup = "CRISIS_BREAKUP"
    case datingEarly = "DATING_EARLY"
    case relationshipEstablished = "RELATIONSHIP_ESTABLISHED"
    case selfImprovement = "SELF_IMPROVEMENT"
    case safetyRisk = "SAFETY_RISK"
}

enum RouterUrgency: String, Codable {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
}

struct RouterClassification: Codable {
    var category: RouterCategory
    var urgency: RouterUrgency
    var reasoning: String
}

struct StrategistResponse: Codable {
    var internalThought: InternalThought
    var response: ResponseContent

    enum CodingKeys: String, CodingKey {
        case internalThought = "internal_thought"
        case response
    }

    // Flexible decoder - handles internal_thought as Object OR String
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.response = try container.decode(ResponseContent.self, forKey: .response)
        if let objectThought = try? container.decode(InternalThought.self, forKey: .internalThought) {
            self.internalThought = objectThought
        } else if let stringThought = try? container.decode(String.self, forKey: .internalThought) {
            self.internalThought = InternalThought(
                userVibe: "UNKNOWN", manBehaviorAnalysis: "N/A", strategySelection: stringThought
            )
        } else {
            self.internalThought = InternalThought(
                userVibe: "UNKNOWN", manBehaviorAnalysis: "N/A", strategySelection: "Parsing Error"
            )
        }
    }

    init(internalThought: InternalThought, response: ResponseContent) {
        self.internalThought = internalThought
        self.response = response
    }
}

struct InternalThought: Codable {
    var userVibe: String
    var manBehaviorAnalysis: String
    var strategySelection: String

    enum CodingKeys: String, CodingKey {
        case userVibe = "user_vibe"
        case manBehaviorAnalysis = "man_behavior_analysis"
        case strategySelection = "strategy_selection"
    }
}

struct ResponseContent: Codable {
    var text: String
    var options: [StrategyOption]?

    enum CodingKeys: String, CodingKey {
        case text
        case advice  // LLM sometimes uses "advice" instead of "text"
        case options
    }

    init(from decoder: Decoder) throws {
        if let stringValue = try? decoder.singleValueContainer().decode(String.self) {
            self.text = stringValue
            self.options = nil
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let textValue = try? container.decode(String.self, forKey: .text) {
            self.text = textValue
        } else if let adviceValue = try? container.decode(String.self, forKey: .advice) {
            self.text = adviceValue
        } else {
            self.text = "I'm here for you."
        }
        self.options = try container.decodeIfPresent([StrategyOption].self, forKey: .options)
    }

    init(text: String, options: [StrategyOption]? = nil) {
        self.text = text
        self.options = options
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        try container.encodeIfPresent(options, forKey: .options)
    }
}

struct StrategyOption: Codable, Identifiable {
    var id: String { label }
    var label: String
    var action: String
    var outcome: String

    enum CodingKeys: String, CodingKey {
        case label
        case action
        case outcome
        case predictedOutcome = "predicted_outcome"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        label = try container.decode(String.self, forKey: .label)
        action = try container.decode(String.self, forKey: .action)
        outcome = try container.decodeIfPresent(String.self, forKey: .outcome)
            ?? container.decodeIfPresent(String.self, forKey: .predictedOutcome)
            ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(label, forKey: .label)
        try container.encode(action, forKey: .action)
        try container.encode(outcome, forKey: .predictedOutcome)
    }

    init(label: String, action: String, outcome: String) {
        self.label = label
        self.action = action
        self.outcome = outcome
    }
}

struct RouterMetadata: Codable {
    var internalThought: String?
    var routerMode: String?
    var selectedOption: String?

    enum CodingKeys: String, CodingKey {
        case internalThought = "internal_thought"
        case routerMode = "router_mode"
        case selectedOption = "selected_option"
    }
}

enum MessageContentType: String, Codable {
    case text
    case optionPair = "option_pair"
}
```

## 14.7 Goal.swift

```swift
struct Goal: Codable, Identifiable {
    let id: String
    var userId: String?
    var title: String
    var description: String?
    var status: GoalStatus
    var createdAt: Date
    var completedAt: Date?
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String? = nil,
        title: String,
        description: String? = nil,
        status: GoalStatus = .active,
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id.lowercased()
        self.userId = userId
        self.title = title
        self.description = description
        self.status = status
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.updatedAt = updatedAt
    }
}

enum GoalStatus: String, Codable {
    case active
    case completed
    case paused
}
```

## 14.8 JournalEntry.swift

```swift
enum JournalMood: String, CaseIterable, Hashable {
    case happy, calm, grateful, anxious, sad, angry, hopeful, tired

    var emoji: String {
        switch self {
        case .happy:    return "😊"
        case .calm:     return "😌"
        case .grateful: return "🙏"
        case .anxious:  return "😰"
        case .sad:      return "😢"
        case .angry:    return "😤"
        case .hopeful:  return "🌱"
        case .tired:    return "😴"
        }
    }

    var label: String {
        rawValue.capitalized
    }
}

struct JournalEntry: Codable, Identifiable {
    let id: String
    var userId: String?
    var title: String
    var content: String
    var mood: String
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String? = nil,
        title: String = "",
        content: String = "",
        mood: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id.lowercased()
        self.userId = userId
        self.title = title
        self.content = content
        self.mood = mood
        self.createdAt = createdAt
    }
}
```

## 14.9 Affirmation.swift

```swift
struct Affirmation: Codable, Identifiable {
    let id: String
    var userId: String?
    var text: String
    var date: String
    var isSaved: Bool
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String? = nil,
        text: String,
        date: String = "",
        isSaved: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id.lowercased()
        self.userId = userId
        self.text = text
        self.date = date
        self.isSaved = isSaved
        self.createdAt = createdAt
    }
}
```

## 14.10 VisionItem.swift

```swift
enum VisionCategory: String, Codable, CaseIterable {
    case love
    case career
    case selfCare = "self_care"
    case travel
    case lifestyle
    case other

    var displayName: String {
        switch self {
        case .selfCare: return "Self Care"
        default:        return rawValue.capitalized
        }
    }

    var icon: String {
        switch self {
        case .love:      return "heart.fill"
        case .career:    return "briefcase.fill"
        case .selfCare:  return "sparkles"
        case .travel:    return "airplane"
        case .lifestyle: return "leaf.fill"
        case .other:     return "star.fill"
        }
    }
}

struct VisionItem: Codable, Identifiable {
    let id: String
    var userId: String?
    var imageUri: String?
    var title: String
    var category: VisionCategory
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String? = nil,
        imageUri: String? = nil,
        title: String,
        category: VisionCategory = .other,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id.lowercased()
        self.userId = userId
        self.imageUri = imageUri
        self.title = title
        self.category = category
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
```

## 14.11 DailyUsage.swift

```swift
struct DailyUsage: Codable {
    var date: String
    var messageCount: Int

    init(date: String = "", messageCount: Int = 0) {
        self.date = date
        self.messageCount = messageCount
    }

    static func todayKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
```

## 14.12 GlowUpStreak.swift

```swift
struct GlowUpStreak: Codable {
    var currentStreak: Int
    var longestStreak: Int
    var lastActiveDate: String  // "yyyy-MM-dd"

    init(currentStreak: Int = 0, longestStreak: Int = 0, lastActiveDate: String = "") {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastActiveDate = lastActiveDate
    }

    static func todayKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
```

## 14.13 Feedback.swift

```swift
enum FeedbackRating: String, Codable {
    case helpful
    case notHelpful = "not_helpful"
}

enum ReportType: String, Codable, CaseIterable {
    case harmful
    case incorrect
    case unhelpful
    case other

    var displayName: String {
        switch self {
        case .harmful: return "Harmful"
        case .incorrect: return "Incorrect"
        case .unhelpful: return "Unhelpful"
        case .other: return "Other"
        }
    }

    var description: String {
        switch self {
        case .harmful: return "Could cause harm or is unsafe"
        case .incorrect: return "Information is factually wrong"
        case .unhelpful: return "Doesn't address my question"
        case .other: return "Something else is wrong"
        }
    }
}

struct Feedback: Codable, Identifiable {
    var id: String = UUID().uuidString
    let messageId: String
    let conversationId: String
    let userMessage: String
    let aiResponse: String
    let rating: FeedbackRating
    var reportType: ReportType?
    var reportText: String?
    var createdAt: Date = Date()
}

enum MessageFeedbackState: Equatable {
    case none
    case helpful
    case notHelpful
    case reported
}
```

## 14.14 InsightEntry (defined in StorageService.swift)

```swift
struct InsightEntry: Codable {
    let text: String
    let createdAt: Date
}
```

## 14.15 CrisisType & CrisisResponses (Constants/CrisisResponses.swift)

```swift
enum CrisisType: String {
    case selfHarm = "self_harm"
    case abuse = "abuse"
    case severeMentalHealth = "severe_mental_health"
}

enum CrisisResponses {
    static let responses: [CrisisType: String] = [
        .selfHarm: """
            I hear you, and I need to step out of my usual role for a moment. What you're feeling is real, and you deserve support from someone trained to help. Please reach out:

            988 Suicide & Crisis Lifeline: Call or text 988
            Crisis Text Line: Text HOME to 741741

            You are not alone. Please talk to someone right now.
            """,

        .abuse: """
            I need to pause and be real with you. If you're in danger or being hurt, that goes beyond what I can help with — and you deserve real, immediate support.

            National Domestic Violence Hotline: 1-800-799-7233 (or text START to 88788)
            Crisis Text Line: Text HOME to 741741

            Your safety comes first. Always.
            """,

        .severeMentalHealth: """
            I care about you, and what you're describing sounds like something that needs more than a chat with me. Please reach out to someone who can really help:

            988 Suicide & Crisis Lifeline: Call or text 988
            Crisis Text Line: Text HOME to 741741
            SAMHSA Helpline: 1-800-662-4357

            There's no shame in asking for help. It's the strongest thing you can do.
            """,
    ]

    static func response(for type: CrisisType) -> String {
        return responses[type] ?? responses[.selfHarm]!
    }
}
```

---

# SECTION 15: COMPLETE COLOR PALETTE

> Every semantic color with exact hex values for both light and dark modes.

| Token | Light Mode Hex | Dark Mode Hex | Usage |
|-------|---------------|---------------|-------|
| `chloeBackground` | `#FFF8F0` | `#1A1517` | Root app background |
| `chloeSurface` | `#FAFAFA` | `#241E20` | Cards, input backgrounds |
| `chloePrimary` | `#B76E79` | `#C4848D` | Primary brand (buttons, accents) |
| `chloePrimaryLight` | `#FFF0EB` | `#2D2226` | Chloe bubble BG, subtle fills |
| `chloePrimaryDark` | `#8A4A55` | `#A66E72` | Pressed/deep accent |
| `chloeAccent` | `#F4A896` | `#D4907E` | Secondary accent, warm highlights |
| `chloeAccentMuted` | `#E8B4A8` | `#8E6E66` | Typing indicator dots |
| `chloeTextPrimary` | `#2D2324` | `#F5F0EB` | Main text color |
| `chloeTextSecondary` | `#6B6B6B` | `#B8A5A7` | Secondary labels |
| `chloeTextTertiary` | `#9A9A9A` | `#7A6E70` | Placeholders, captions |
| `chloeBorder` | `#E5E5E5` | `#3A3234` | Standard dividers |
| `chloeBorderWarm` | `#F0E0DA` | `#3D2E30` | Input borders, warm dividers |
| `chloeUserBubble` | `#F0F0F0` | `#2A2325` | User chat bubble BG |
| `chloeGradientStart` | `#FFF8F5` | `#1A1517` | Top of page gradient |
| `chloeGradientEnd` | `#FEEAE2` | `#221A1C` | Bottom of page gradient |
| `chloeRosewood` | `#8E5A5E` | `#A66E72` | Destructive actions, Chloe-isms |
| `chloeEtherealGold` | `#F3E5AB` | `#8B7B4A` | Orb stardust, special accents |

### Additional Hardcoded Hex Values

| Context | Hex | Where Used |
|---------|-----|------------|
| Editorial heading gradient (light, top) | `#2D2324` | `ChloeEditorialHeadingStyle` |
| Editorial heading gradient (light, bottom) | `#8E5A5E` | `ChloeEditorialHeadingStyle` |
| Editorial heading gradient (dark, top) | `#D4A0A8` | `ChloeEditorialHeadingStyle` |
| Editorial heading gradient (dark, bottom) | `#8E5A5E` | `ChloeEditorialHeadingStyle` |
| OnboardingCard accent | `#B76E79` | `OnboardingCard` |
| Input line glow | `#B76E79` | `EmailLoginView`, `NameStepView` |
| Orb halo / shadow | `#B76E79` | `LuminousOrb`, `PressableButtonStyle` |
| Fluid nebula warm | `#FFF8F0`, `#FFE5D9`, `#B76E79` | `FluidNebula` inside `LuminousOrb` |
| Welcome intro glow | `#FAD6A5` (0.05 opacity) | `WelcomeIntroView`, `ArchetypeQuizView`, `NameStepView` |
| Success green | `#4A7C59` | `EmailConfirmationView`, `PasswordResetView` |

### Gradient Definitions

```swift
// chloeHeadingGradient (used for greeting text)
LinearGradient(
    colors: [Color.chloePrimary, Color.chloeAccent],
    startPoint: .leading,
    endPoint: .trailing
)

// Page background gradient (used everywhere)
LinearGradient(
    colors: [.chloeGradientStart, .chloeGradientEnd],
    startPoint: .top,
    endPoint: .bottom
)
```

### Color+Theme Extension (hex initializer)

Both `Color` and `UIColor` have `init(hex: String)` extensions that handle 3, 6, and 8-character hex strings. Defined in `Extensions/Color+Theme.swift`.

---

# SECTION 16: COMPLETE TYPOGRAPHY SYSTEM

## 16.1 Custom Font Families

| Font File | Font Name Constant | PostScript Name |
|-----------|--------------------|-----------------|
| `CormorantGaramond-BoldItalic.ttf` | `ChloeFont.heroBoldItalic` | `"CormorantGaramond-BoldItalic"` |
| `Cinzel-Regular.ttf` | `ChloeFont.headerDisplay` | `"Cinzel-Regular"` |
| `PlayfairDisplay-Italic-VF.ttf` | `ChloeFont.editorialBoldItalic` | `"PlayfairDisplay-Italic"` |
| `TenorSans-Regular.ttf` | *(registered but not referenced in code)* | `"TenorSans-Regular"` |

All four are registered in `Info.plist` under `UIAppFonts`.

## 16.2 Dynamic Type Semantic Fonts

| Token | Definition | Maps To |
|-------|-----------|---------|
| `chloeLargeTitle` | `.system(.largeTitle, weight: .medium)` | Large titles |
| `chloeTitle` | `.system(.title, weight: .medium)` | Screen titles |
| `chloeTitle2` | `.system(.title2)` | Subtitles |
| `chloeHeadline` | `.system(.headline, weight: .medium)` | Card titles, section headers |
| `chloeSubheadline` | `.system(.subheadline, weight: .medium)` | OnboardingCard title |
| `chloeBodyDefault` | `.system(.body)` | Default body text |
| `chloeBodyLight` | `.system(.body, weight: .light)` | Chloe bubble text |
| `chloeCaption` | `.system(.footnote)` | Timestamps, metadata |
| `chloeCaptionLight` | `.system(.footnote, weight: .light)` | OnboardingCard description |
| `chloeProgressLabel` | `.system(.caption2, weight: .light)` | Progress indicators |

## 16.3 Custom Font Tokens (scale with Dynamic Type)

| Token | Font | Size | relativeTo |
|-------|------|------|------------|
| `chloeButton` | `Cinzel-Regular` | 15 | `.subheadline` |
| `chloeGreeting` | `CormorantGaramond-BoldItalic` | 38 | `.largeTitle` |
| `chloeStatus` | `Cinzel-Regular` | 11 | `.caption2` |
| `chloeSidebarAppName` | `CormorantGaramond-BoldItalic` | 24 | `.title` |
| `chloeSidebarSectionHeader` | `Cinzel-Regular` | 11 | `.caption2` |
| `chloeSidebarMenuItem` | `Cinzel-Regular` | 14 | `.footnote` |
| `chloeSidebarChatItem` | `.system(.footnote)` | System | `.footnote` |
| `chloeOnboardingQuestion` | `CormorantGaramond-BoldItalic` | 40 | `.largeTitle` |

## 16.4 Typography Style Modifiers

| Modifier | Font | Tracking | Other |
|----------|------|----------|-------|
| `chloeEditorialHeading()` | `.chloeOnboardingQuestion` | 1 | Gradient foreground + shadow |
| `chloeHeroStyle()` | `.chloeGreeting` | `34 * -0.02` (-0.68) | — |
| `chloeSecondaryHeaderStyle()` | `.chloeSidebarSectionHeader` | 3 | `.textCase(.uppercase)` |
| `chloeBodyStyle()` | `.chloeBodyDefault` | — | `.lineSpacing(17 * 0.5)` = 8.5 |
| `chloeCaptionStyle()` | `.chloeCaption` | — | `.lineSpacing(14 * 0.5)` = 7 |
| `chloeButtonTextStyle()` | `.chloeButton` | 3 | — |

## 16.5 Function Fonts

```swift
static func chloeHeading(_ size: CGFloat) -> Font       // .system(size:, weight: .regular)
static func chloeHeadingMedium(_ size: CGFloat) -> Font  // .system(size:, weight: .medium)
static func chloeBody(_ size: CGFloat) -> Font           // .system(size:, weight: .regular)
static func chloeBodyMedium(_ size: CGFloat) -> Font     // .system(size:, weight: .medium)
static func chloeInputPlaceholder(_ size: CGFloat) -> Font // .system(size:, weight: .regular)
```

---

# SECTION 17: EVERY SCREEN DOCUMENTED

> Every screen in the app with interactive elements, colors, fonts, animations, and navigation.

## 17.1 EmailLoginView (Auth)

**File:** `Views/Auth/EmailLoginView.swift`

| Element | Type | Font | Color | Behavior |
|---------|------|------|-------|----------|
| "Chloe" title | Text | `.chloeGreeting` | `.chloePrimary` | Static |
| "YOUR POCKET CONFIDANTE" | Text | `Cinzel-Regular` 11pt, tracking 3 | `.chloeTextSecondary.opacity(0.8)` | Uppercase |
| Email field | TextField | `.system(size: 20, weight: .light)` | `.chloeTextPrimary` | Focused: glowing underline (`#B76E79` 0.9 opacity, 1pt) |
| Password field | SecureField | `.system(size: 20, weight: .light)` | `.chloeTextPrimary` | Same glow underline as email |
| "Continue" button | ChloeButtonLabel | `Cinzel-Regular` 15pt, tracking 3 | White on `.chloePrimary` fill | `PressableButtonStyle` (scale 0.96→1.0 spring) |
| "Forgot Password?" | Button/Text | `.chloeCaption` | `.chloeTextTertiary` | Triggers password reset email |
| Error banner | Text | `.chloeCaption` | `.red` | Appears below fields when auth fails |
| Background | GradientBackground | — | `chloeGradientStart → chloeGradientEnd` | Full screen |
| Dust particles | EtherealDustParticles | — | 0.05 opacity | Ambient background layer |

**Animations:** `.easeInOut(duration: 0.3)` on glow underline focus; spring on button press.

## 17.2 OnboardingContainerView (Onboarding)

**File:** `Views/Onboarding/OnboardingContainerView.swift`

- **Layout:** `TabView` with `.page(indexDisplayMode: .never)` — 4 steps: Welcome(0), Name(1), Quiz(2), Complete(3)
- **Progress bar:** Capsule, 3pt height, `Color.chloeBorder.opacity(0.4)` track, `Color.chloePrimary` fill; animates with `.easeInOut(0.3)`
- **Step counter:** "N of 5" in `.chloeCaption` / `.chloeTextSecondary`
- **Back button:** `chevron.left` SF Symbol, 16pt medium, `.chloeTextPrimary`; goes back a quiz page first, then previous step
- **Skip button:** "Skip" in `.chloeCaption` / `.chloeTextTertiary`; calls `completeOnboarding()`
- **Persistent Guide Orb:** `ChloeAvatar(size: 80)` overlay positioned at `y: geo.size.height * 0.14`; starts at scale 0.5, springs to 0.8; shadow `#B76E79` 0.4 opacity, radius pulses 10→30→10 on step transitions
- **Orb name pulse:** On `nameText` change, scale 1.0→1.08→1.0 (0.15s)

## 17.3 WelcomeIntroView (Step 0)

**File:** `Views/Onboarding/WelcomeIntroView.swift`

| Element | Details |
|---------|---------|
| Kinetic text | "I'm Chloe. Let's unlock your most magnetic self." — words reveal one-by-one (0.3s per word, 0.8s initial delay) |
| Font | `.chloeOnboardingQuestion` with tracking 1, gradient `#2D2324 → #8E5A5E` |
| Button | "Begin My Journey" — `ChloeButtonLabel` + `PressableButtonStyle`; fades in with spring after text reveals |
| Dissolve | On tap: text fades out (0.5s `.easeIn`), scale 0.8, offset -80; 15 particles fly from center to orb position (0.6s); then `onContinue()` |
| Background glow | RadialGradient `#FAD6A5` at 0.05 opacity, blur 30 |

## 17.4 NameStepView (Step 1)

**File:** `Views/Onboarding/NameStepView.swift`

| Element | Details |
|---------|---------|
| Question | "What shall I call you, beautiful?" — `chloeEditorialHeading()` modifier |
| Input | TextField, `CormorantGaramond-BoldItalic` 24pt, center-aligned |
| Placeholder | "Your name" in system 20pt light italic, `chloeRosewood.opacity(0.6)` |
| Underline | `#B76E79`, 0.5pt → 1pt when focused, shadow radius 0→6 |
| Continue | `ChloeButtonLabel`, disabled when name is blank |
| Keyboard | `.scrollDismissesKeyboard(.interactively)`, tap-to-dismiss |

## 17.5 ArchetypeQuizView (Step 2)

**File:** `Views/Onboarding/ArchetypeQuizView.swift`

- **4 quiz pages** (tracked by `viewModel.quizPage` 0-3), each with 4 options (a, b, c, d)
- **Question text:** `StaggeredWordReveal` — words fade in one-by-one (0.08s delay per word, 0.8s duration), uses `chloeEditorialHeading()` modifier
- **Option cards:** `OnboardingCard` in `LazyVGrid(2 columns, spacing: Spacing.xs)` — staggered scale entrance 0.85→1.0 with spring (0.8 response, 0.7 damping, 0.15s delay per card)
- **Selection:** OnboardingCard border `chloePrimary` with glow; unselected cards dim to 0.6 opacity
- **Continue button:** Enabled only when an answer is selected; advances quiz page or calls `nextStep()`
- **Haptics:** `UIImpactFeedbackGenerator(style: .light)` on option tap

**Quiz Questions:**
1. "When you imagine your most powerful self, she is..." (Magnetic/Commanding/Inspiring/Electric)
2. "Your secret weapon is..." (Warmth/Intuition/Drive/Mystery)
3. "When life gets heavy, you reset by..." (Reflecting/Moving/Creating/Escaping)
4. "In your dream relationship, he's drawn to your..." (Sensuality/Standards/Depth/Wildness)

## 17.6 OnboardingCompleteView (Step 3)

**File:** `Views/Onboarding/OnboardingCompleteView.swift`

| Element | Details |
|---------|---------|
| "You're all set!" | `.chloeGreeting` font, `.chloePrimary` color |
| "YOUR ARCHETYPE" label | `Cinzel-Regular` 13pt, tracking 3, `.chloeTextSecondary.opacity(0.8)` |
| Archetype name | `Cinzel-Regular` 28pt, `.chloePrimary` |
| Description | `Cinzel-Regular` 13pt, tracking 3, uppercase, `.chloeTextSecondary.opacity(0.8)` |
| "Meet Chloe" button | `ChloeButtonLabel` + `PressableButtonStyle` |
| Confetti | `ConfettiSwiftUI` — 50 particles, colors: `chloePrimary, chloeAccent, chloeEtherealGold`, rainHeight 600, radius 400; fires 0.5s after step appears |

## 17.7 SanctuaryView (Main Chat)

**File:** `Views/Main/SanctuaryView.swift` (802 lines)

**Layout Modes:**
1. **Landing (chatActive = false):** LuminousOrb centered at `y: geo.size.height * 0.25`, greeting text below, ghost messages, PlusBloomMenu
2. **Chat (chatActive = true):** ScrollView of ChatBubble messages, ChatInputBar pinned at bottom

| Element | Details |
|---------|---------|
| Top bar left | Hamburger button → opens `SidebarView` |
| Top bar center | "CHLOE" in `Cinzel-Regular` 11pt, tracking 3, `.chloeTextSecondary` (status font) |
| Top bar right | "plus.circle" SF Symbol → `startNewChat()` |
| Greeting | `Text(greeting)` with `.chloeHeroStyle()` (CormorantGaramond-BoldItalic 38pt, tracking -0.68) + `chloeHeadingGradient` |
| Greeting logic | Time-based: "Good morning, {name}" / "Good afternoon, {name}" / "Good evening, {name}" |
| LuminousOrb | Size `Spacing.orbSizeSanctuary` (160pt); appears with spring scale 0→1; positioned at `sanctuaryOrbY` (0.25) |
| Ghost messages | Last 3 messages from most recent conversation; fade in staggered; tappable to load that conversation |
| PlusBloomMenu | Radial bloom of 4 action circles (Journal, Goals, Vision, Affirmations) around plus button |
| Chat messages | `ForEach(chatVM.messages)` → `ChatBubble` with feedback/report callbacks |
| Loading indicators | v2: Shows `TypingIndicator` during `.routing` and `.generating` phases |
| Error retry | "Tap to retry" banner when `chatVM.errorMessage` is set |
| Rate limit sheet | `.sheet(isPresented: $chatVM.isLimitReached)` with upgrade prompt |
| Camera | `.fullScreenCover` with `CameraPickerView` |
| Photo picker | `.photosPicker(isPresented:)` |
| Report sheet | `.sheet(item: $reportingMessage)` with `ReportSheet` |

**Navigation destinations:** `.navigationDestination(isPresented:)` for Journal, History, VisionBoard, Goals, Affirmations, Settings.

**Animations:**
- Chat activation: `.spring(response: 0.5, dampingFraction: 0.85)` on `chatActive` toggle
- Sidebar: same spring on `sidebarOpen`
- Scroll to bottom: `withAnimation(.easeOut(duration: 0.3))` on new messages
- Orb entrance: `.spring(response: 0.6, dampingFraction: 0.7)` + scale `appeared ? 1.0 : 0.3`

## 17.8 SidebarView

**File:** `Views/Main/SidebarView.swift` (318 lines)

- **Width:** `screenWidth * 0.82`
- **Background:** `.chloeSurface` with `RoundedRectangle(cornerRadius: 20)`
- **App name:** "Chloe" in `.chloeSidebarAppName` (CormorantGaramond-BoldItalic 24pt)
- **Section headers:** `.chloeSidebarSectionHeader` (Cinzel-Regular 11pt, tracking 3, uppercase)
- **Menu items:** `.chloeSidebarMenuItem` (Cinzel-Regular 14pt) — Journal, Goals, Vision Board, Affirmations, History, Settings
- **Vibe indicator:** Current vibe label in `.chloeCaption`
- **Streak display:** "{streak.currentStreak} day streak" with flame icon
- **Recent conversations:** List of conversations with `chloeSidebarChatItem` font; starred items show star icon
- **Context menu on conversations:** Rename, Star/Unstar, Delete
- **Profile image:** 50pt circle at top of sidebar, loaded from `profileImageData`
- **New Chat button:** Prominent at top

## 17.9 SettingsView

**File:** `Views/Main/SettingsView.swift` (430 lines)

| Section | Elements |
|---------|----------|
| Profile Image | 100pt circle, tappable to change; camera/photo picker |
| Display Name | Text field, auto-saves on change |
| Account | Email display (non-editable), Sign Out button |
| Archetype | Displays current archetype label |
| Preferences | Notification toggle, theme (system default only) |
| Data | Export data, Delete account (with confirmation alert) |
| About | Version, privacy policy link, terms link |

**Delete Account:** Two-step confirmation → calls `SyncDataService.shared.deleteAccount()` which clears local + cloud.

## 17.10 JournalView

**File:** `Views/Main/JournalView.swift`

- **Layout:** `List` of journal entries sorted by `createdAt` descending
- **Empty state:** Styled message encouraging first entry
- **Entry card:** Title, mood emoji, date, content preview (2 lines)
- **Add button:** Floating `+` button → opens `JournalEntryEditorView`
- **Swipe to delete:** `.onDelete` with offline guard (returns false if offline)
- **Navigation:** Tap entry → `JournalDetailView`

## 17.11 GoalsView

**File:** `Views/Main/GoalsView.swift`

- **Layout:** `List` with active/completed sections
- **Goal card:** Title, description (if present), status badge
- **Add:** Alert with TextField for new goal title
- **Complete/Reactivate:** Swipe action to toggle status
- **Delete:** Swipe to delete with offline guard

## 17.12 VisionBoardView

**File:** `Views/Main/VisionBoardView.swift`

- **Layout:** `LazyVGrid(columns: 2)` masonry-style
- **Vision card:** Image (Kingfisher for URL loading), title overlay, category icon
- **Add:** `AddVisionSheet` — title + category picker + image (camera/photo)
- **Delete:** Long-press context menu with offline guard

## 17.13 AffirmationsView

**File:** `Views/Main/AffirmationsView.swift`

- **Primary element:** Large affirmation card with `.chloeOnboardingQuestion` font styling
- **Generate:** Button triggers `GeminiService.shared.generateAffirmation()` with personalized prompt
- **Save/Unsave:** Heart toggle to bookmark affirmations
- **History:** Scrollable list of saved affirmations

## 17.14 HistoryView

**File:** `Views/Main/HistoryView.swift`

- **Layout:** `List` of conversations sorted by `updatedAt` descending
- **Conversation card:** Title, date, starred indicator
- **Tap:** Loads conversation into ChatViewModel, navigates back to SanctuaryView in chat mode
- **Context menu:** Rename, Star/Unstar, Delete

---

# SECTION 18: EVERY API CALL DOCUMENTED

> Every external API call with URL, method, headers, body shape, and response parsing.

## 18.1 Gemini Direct API — Chat (V1 Legacy)

| Field | Value |
|-------|-------|
| **Method** | `POST` |
| **URL** | `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent` |
| **Headers** | `Content-Type: application/json`, `x-goog-api-key: {GEMINI_API_KEY}` |
| **Timeout** | 15 seconds |
| **Called by** | `GeminiService.sendMessage()` → `ChatViewModel` (V1 pipeline) |

**Request Body:**
```json
{
  "system_instruction": { "parts": [{ "text": "<system_prompt>" }] },
  "contents": [
    { "role": "user|model", "parts": [{ "text": "..." }, { "inlineData": { "mimeType": "image/jpeg", "data": "<base64>" } }] }
  ],
  "generationConfig": { "temperature": 0.8, "topP": 0.9, "maxOutputTokens": 1024 },
  "safetySettings": [
    { "category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_ONLY_HIGH" },
    { "category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_ONLY_HIGH" },
    { "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_MEDIUM_AND_ABOVE" },
    { "category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_ONLY_HIGH" }
  ]
}
```

**Response Parsing:** `json["candidates"][0]["content"]["parts"][0]["text"]`

**Image handling:** Only the latest message in `recentMessages` includes actual `inlineData` (base64 JPEG, max 1024px dimension, 0.8 compression). Older messages with images get `[User shared an image]` text placeholder.

**Message history:** Capped at `MAX_CONVERSATION_HISTORY = 20` most recent messages.

## 18.2 Gemini Direct API — Router Classification (V2)

| Field | Value |
|-------|-------|
| **Method** | `POST` |
| **URL** | Same Gemini endpoint |
| **Called by** | `GeminiService.classifyMessage()` → `ChatViewModel` (V2 pipeline, Phase 1) |
| **Temperature** | `0.1` (low for classification) |
| **maxOutputTokens** | `256` |
| **responseMimeType** | `"application/json"` (forces JSON output) |
| **Retry** | 1 retry with 0.5s delay on decode failure; throws `routerInvalidResponse` after 2 attempts |

**Request:** Single user message, system prompt = `Prompts.router`.

**Expected JSON Response:**
```json
{
  "category": "CRISIS_BREAKUP|DATING_EARLY|RELATIONSHIP_ESTABLISHED|SELF_IMPROVEMENT|SAFETY_RISK",
  "urgency": "LOW|MEDIUM|HIGH",
  "reasoning": "..."
}
```

## 18.3 Gemini Direct API — Strategist Response (V2)

| Field | Value |
|-------|-------|
| **Method** | `POST` |
| **URL** | Same Gemini endpoint |
| **Called by** | `GeminiService.sendStrategistMessage()` → `ChatViewModel` (V2 pipeline, Phase 2) |
| **Temperature** | `0.7` |
| **maxOutputTokens** | `2048` |
| **responseMimeType** | `"application/json"` |
| **Retry** | 1 retry with 0.5s delay; after 2 failures, falls back to raw text wrapped in `StrategistResponse` with "Fallback to raw text" metadata |

**Expected JSON Response:**
```json
{
  "internal_thought": {
    "user_vibe": "LOW|MEDIUM|HIGH",
    "man_behavior_analysis": "...",
    "strategy_selection": "..."
  },
  "response": {
    "text": "Chloe's response text",
    "options": [
      { "label": "...", "action": "...", "predicted_outcome": "..." }
    ]
  }
}
```

**Markdown stripping:** `stripMarkdownWrapper()` removes ` ```json ` / ` ``` ` wrappers before parsing.

**Flexible decoding:** `StrategistResponse.init(from:)` handles `internal_thought` as Object or String. `ResponseContent.init(from:)` handles whole-response as String, or looks for `text` key first, then `advice` key. `StrategyOption` checks both `outcome` and `predicted_outcome` keys.

## 18.4 Gemini Direct API — Analyst (Background)

| Field | Value |
|-------|-------|
| **Method** | `POST` |
| **URL** | Same Gemini endpoint |
| **Called by** | `GeminiService.analyzeConversation()` → `AnalystService.analyze()` → `ChatViewModel.triggerBackgroundAnalysis()` |
| **Temperature** | `0.2` (clinical) |
| **maxOutputTokens** | `1024` |
| **responseMimeType** | `"application/json"` |
| **Trigger** | Every 3 messages (`messagesSinceAnalysis >= 3`) AND on app background |

**Request:** All messages concatenated as "User: ... / Chloe: ..." text block, prepended with `<context_dossier>` XML block. System prompt = `Prompts.analyst`.

**Expected JSON Response:** `AnalystResult` (see Section 14.5 for schema).

## 18.5 Gemini Direct API — Title Generation

| Field | Value |
|-------|-------|
| **Called by** | `GeminiService.generateTitle()` → `ChatViewModel.saveMessages()` |
| **Temperature** | `0.3` |
| **maxOutputTokens** | `32` |
| **Trigger** | First user message when conversation title is "New Conversation" |
| **Prompt** | `"Summarize this message in 3-5 words as a short conversation title. Return only the title, nothing else."` prepended to message text |

## 18.6 Gemini Direct API — Affirmation Generation

| Field | Value |
|-------|-------|
| **Called by** | `GeminiService.generateAffirmation()` → `AffirmationsViewModel` |
| **Temperature** | `0.9` (high creativity) |
| **maxOutputTokens** | `256` |
| **Prompt** | `Prompts.affirmationTemplate` with `{{user_name}}`, `{{archetype_label}}`, `{{current_vibe}}` injected |
| **Fallback** | Returns `"You are the prize. Act accordingly."` on empty response |

## 18.7 Portkey Gateway — Chat (V1 alternative route)

| Field | Value |
|-------|-------|
| **Method** | `POST` |
| **URL** | `https://api.portkey.ai/v1/chat/completions` |
| **Headers** | `Content-Type: application/json`, `x-portkey-api-key: {key}`, `x-portkey-virtual-key: {vkey}`, optional `x-portkey-metadata-*` |
| **Timeout** | 30 seconds |
| **Condition** | `PortkeyService.shared.isConfigured` (both API key AND virtual key present) |
| **Model** | `@{virtualKey}/gemini-2.0-flash` |
| **Format** | OpenAI-compatible chat completions |

**Request Body:**
```json
{
  "model": "@{virtualKey}/gemini-2.0-flash",
  "messages": [
    { "role": "system", "content": "<system_prompt>" },
    { "role": "user|assistant", "content": "..." }
  ],
  "max_tokens": 1024
}
```

**Response Parsing:** `json["choices"][0]["message"]["content"]`
**Trace ID:** Captured from `x-portkey-trace-id` response header → stored in `lastTraceId`.

## 18.8 Portkey Gateway — Feedback

| Field | Value |
|-------|-------|
| **Method** | `POST` |
| **URL** | `https://api.portkey.ai/v1/feedback` |
| **Headers** | `Content-Type: application/json`, `x-portkey-api-key: {key}` |
| **Called by** | `FeedbackService.shared.submitFeedback()` |

**Request Body:**
```json
{ "trace_id": "<trace_id>", "value": 1 | -1 }
```

## 18.9 Supabase Auth — Email Sign Up / Sign In

| Operation | Method | Called by |
|-----------|--------|----------|
| Sign up | `supabase.auth.signUp(email:password:)` | `AuthViewModel.signUp()` |
| Sign in | `supabase.auth.signIn(email:password:)` | `AuthViewModel.signIn()` |
| Sign out | `supabase.auth.signOut()` | `AuthViewModel.signOut()` |
| Password reset | `supabase.auth.resetPasswordForEmail()` | `AuthViewModel.sendPasswordReset()` |
| Update password | `supabase.auth.update(user: .init(password:))` | `AuthViewModel.updatePassword()` |
| Restore session | `supabase.auth.session` | `AuthViewModel.restoreSession()` |

**Redirect URL:** `chloeapp://auth-callback` (deep link handled by `ChloeApp.swift .onOpenURL`)
**PKCE:** Enabled by default in Supabase Swift SDK.

## 18.10 Supabase Database — CRUD Operations

All via `SupabaseDataService` using Supabase Swift SDK's PostgREST client:

| Table | Operations | Called by |
|-------|-----------|----------|
| `profiles` | Upsert (on `id`), Select | `SyncDataService` |
| `conversations` | Upsert (on `id`), Select, Delete | `SyncDataService` |
| `messages` | Upsert (on `id`), Select (filter `conversation_id`) | `SyncDataService` |
| `journal_entries` | Upsert (on `id`), Select, Delete | `SyncDataService` |
| `goals` | Upsert (on `id`), Select, Delete | `SyncDataService` |
| `affirmations` | Upsert (on `id`), Select, Delete | `SyncDataService` |
| `vision_items` | Upsert (on `id`), Select, Delete | `SyncDataService` |
| `user_facts` | Upsert (on `id`), Select | `SyncDataService` |
| `user_state` | Upsert (on `user_id`), Select | `SyncDataService` |
| `feedback` | Insert | `FeedbackService` |

## 18.11 Supabase Storage — File Operations

| Bucket | Operation | Path Pattern |
|--------|-----------|-------------|
| `user-content` (private) | Upload profile image | `{userId}/profile/profile_image.jpg` |
| `user-content` (private) | Upload chat image | `{userId}/chat/{messageId}.jpg` |
| `user-content` (private) | Upload vision image | `{userId}/vision/{itemId}.jpg` |
| `user-content` (private) | Delete image | Same paths as above |

All storage operations are fire-and-forget async Tasks from `SyncDataService`.

---

# SECTION 19: PROMPT VARIABLES AND INJECTION

> Every template variable in every prompt and how it gets injected.

## 19.1 Template Variables

| Variable | Replaced With | Used In |
|----------|--------------|---------|
| `{{user_name}}` | `profile.displayName` (fallback: `"babe"`) | `chloeSystem`, `affirmationTemplate`, `strategist` |
| `{{archetype_label}}` | `archetype.label` (fallback: `"Not determined yet"`) | `chloeSystem`, `affirmationTemplate`, `strategist` |
| `{{archetype_blend}}` | `archetype.blend` (fallback: `"Not determined yet"`) | `chloeSystem` |
| `{{archetype_description}}` | `archetype.description` (fallback: `"Not determined yet"`) | `chloeSystem` |
| `{{archetype}}` | Same as `archetype_label` | `chloeSystem` |
| `{{relationship_status}}` | Hardcoded `"Not shared yet"` | `chloeSystem`, `strategist` |
| `{{current_vibe}}` | `vibeScore.rawValue` (fallback: `"MEDIUM"`) | `affirmationTemplate`, `strategist` |
| `{{vibe_mode}}` | Deterministic computation (see below) | `chloeSystem` |

## 19.2 Vibe Mode Computation (Swift-side, not LLM)

```
VibeScore.low    → "THE BIG SISTER"
VibeScore.high   → 70% "THE SIREN", 30% "THE GIRL"
VibeScore.medium → 70% "THE BIG SISTER", 30% "THE SIREN"
nil              → Same as medium
```

Computed in `injectUserContext()` in `Prompts.swift:634-644`.

## 19.3 Dynamic Context Injection (appended to system prompt at runtime)

### V1 Pipeline (in `GeminiService.sendMessage()`):

| Injection | Condition | Format |
|-----------|-----------|--------|
| User facts | `!userFacts.isEmpty` | `"\n\nWhat you know about this user:\n{facts joined by newline}"` |
| Session handover | New conversation + `lastSummary` exists | `<session_context>...</session_context>` XML block |
| Pattern insight | NOT new conversation + `insight` popped | `<internal_insight>...</internal_insight>` XML block |

### V2 Pipeline (in `ChatViewModel.sendMessage()` + `GeminiService.sendStrategistMessage()`):

| Injection | Where | Format |
|-----------|-------|--------|
| Router context | Appended to strategist system prompt | `<router_context>Category: X\nUrgency: X\nReasoning: X</router_context>` |
| Soft spiral override | If `safetyService.checkSoftSpiral()` returns true | `<soft_spiral_override>...</soft_spiral_override>` block |
| Behavioral loops | If `profile.behavioralLoops` not empty | `<known_patterns>- loop1\n- loop2</known_patterns>` |
| User facts | In `sendStrategistMessage()` | `<user_facts>fact1\nfact2</user_facts>` |
| Last session summary | If present | `<last_session_summary>...</last_session_summary>` |
| Insight to mention | If popped | `<insight_to_mention>...</insight_to_mention>` |

### Analyst Pipeline (in `GeminiService.analyzeConversation()`):

```xml
<context_dossier>
  USER NAME: {displayName}
  CURRENT VIBE SCORE: {currentVibe}
  KNOWN FACTS: {facts joined by "; "}
  LAST SESSION SUMMARY: {lastSummary}
</context_dossier>
```

Followed by `--- CURRENT CONVERSATION ---` and all messages as `"User: {text}"` / `"Chloe: {text}"`.

## 19.4 Prompt Constants Summary

| Prompt | Var Name | Length | Temperature | Used For |
|--------|----------|--------|-------------|----------|
| Chloe System (V1) | `Prompts.chloeSystem` | ~168 lines | 0.8 | V1 chat pipeline |
| Strategist (V2) | `Prompts.strategist` | ~219 lines | 0.7 | V2 agentic chat |
| Router (V2) | `Prompts.router` | ~35 lines | 0.1 | V2 message classification |
| Analyst | `Prompts.analyst` | ~74 lines | 0.2 | Background analysis |
| Affirmation | `Prompts.affirmationTemplate` | ~56 lines | 0.9 | Daily affirmation generation |
| Title | `Prompts.titleGeneration` | 1 line | 0.3 | Conversation title |

---

# SECTION 20: NAVIGATION MAP

> Complete routing tree from app entry to every reachable screen.

```
ChloeApp.swift (@main)
  └── ContentView
        ├── [authState == .unauthenticated/.authenticating]
        │     └── NavigationStack
        │           └── EmailLoginView
        │                 ├── "Forgot Password?" → triggers resetPasswordForEmail()
        │                 └── Sign Up / Sign In → authState changes
        │
        ├── [authState == .awaitingEmailConfirmation]
        │     └── NavigationStack
        │           └── EmailLoginView (shows confirmation banner)
        │
        ├── [authState == .settingNewPassword]
        │     └── NavigationStack
        │           └── NewPasswordView
        │
        └── [authState == .authenticated]
              ├── [onboardingComplete == false]
              │     └── NavigationStack
              │           └── OnboardingContainerView (TabView)
              │                 ├── Step 0: WelcomeIntroView
              │                 ├── Step 1: NameStepView
              │                 ├── Step 2: ArchetypeQuizView (4 pages)
              │                 └── Step 3: OnboardingCompleteView
              │                       └── "Meet Chloe" → posts .onboardingDidComplete
              │                             → NotificationPrimingView sheet
              │
              └── [onboardingComplete == true]
                    └── NavigationStack
                          └── SanctuaryView (root)
                                │
                                ├── [Sidebar] SidebarView
                                │     ├── New Chat → startNewChat()
                                │     ├── Conversation → loadConversation()
                                │     ├── Journal → JournalView
                                │     │     ├── + → JournalEntryEditorView
                                │     │     └── Tap entry → JournalDetailView
                                │     ├── Goals → GoalsView
                                │     ├── Vision Board → VisionBoardView
                                │     │     └── + → AddVisionSheet
                                │     ├── Affirmations → AffirmationsView
                                │     ├── History → HistoryView
                                │     │     └── Tap conversation → loads in SanctuaryView
                                │     └── Settings → SettingsView
                                │           ├── Sign Out → clears session
                                │           └── Delete Account → deletes all data
                                │
                                ├── [PlusBloomMenu] (landing mode)
                                │     ├── Journal → JournalView
                                │     ├── Goals → GoalsView
                                │     ├── Vision → VisionBoardView
                                │     └── Affirm → AffirmationsView
                                │
                                ├── [Chat Mode] ChatInputBar
                                │     ├── + menu → AddToChatSheet
                                │     │     ├── Take Photo → CameraPickerView
                                │     │     ├── Upload Image → PhotosPicker
                                │     │     └── Pick File → fileImporter
                                │     └── Send → chatVM.sendMessage()
                                │
                                └── [Deep Link] chloeapp://auth-callback
                                      → handled by ChloeApp.swift .onOpenURL
                                      → routes to AuthViewModel for session/recovery
```

**Notification-triggered entry points:**
- Push notification tap → opens app → `SanctuaryView` (no deep link routing yet)

**Background triggers:**
- `.appDidEnterBackground` → `triggerAnalysisIfPending()`
- `.scenePhase == .active` → `syncFromCloud()` (via `SyncDataService`)

---

# SECTION 21: CHAT BUBBLE RENDERING LOGIC

> Complete specification of how chat messages render, including text, images, options, and feedback.

## 21.1 ChatBubble Component

**File:** `Views/Components/ChatBubble.swift`

### Props

| Prop | Type | Purpose |
|------|------|---------|
| `message` | `Message` | The message to render |
| `conversationId` | `String` | For feedback submission |
| `previousUserMessage` | `String?` | For report context |
| `feedbackState` | `MessageFeedbackState` | Current feedback state (.none/.helpful/.notHelpful/.reported) |
| `onFeedback` | `(FeedbackRating) -> Void` | Thumbs up/down callback |
| `onReport` | `() -> Void` | Flag/report callback |
| `onOptionSelect` | `(StrategyOption) -> Void` | V2 strategy option selection callback |

### Layout Rules

| Rule | User Bubble | Chloe Bubble |
|------|------------|-------------|
| Alignment | Right (trailing) | Left (leading) |
| Spacer | `Spacer(minLength: 60)` on LEFT | `Spacer(minLength: 60)` on RIGHT |
| Background | `Color.chloeUserBubble` (`#F0F0F0` / `#2A2325`) | `Color.chloePrimaryLight` (`#FFF0EB` / `#2D2226`) |
| Border | None (`Color.clear`) | `Color.chloePrimary` at 0.5pt |
| Corner radius | 16pt | 16pt |
| Padding | Horizontal: `Spacing.sm` (16pt), Vertical: `Spacing.xs` (12pt) | Same |
| Text font | `.system(size: 17, weight: .medium)` | `.system(size: 17, weight: .light)` |
| Text color | `.chloeTextPrimary` | `.chloeTextPrimary` |
| Line spacing | 8.5pt | 8.5pt |

### Content Stack (VStack, alignment matches bubble side)

1. **Image** (if `message.imageUri` exists and loads): `UIImage(contentsOfFile:)` → `.resizable().scaledToFit().frame(maxWidth: 240).clipShape(RoundedRectangle(cornerRadius: 12))`
2. **Text** (if `message.text` is non-empty): Rendered with font/color per table above
3. **Strategy Options** (V2 only, Chloe messages only): `StrategyOptionsView` if `message.options` is non-empty
4. **Feedback buttons** (Chloe messages only): Thumbs up, thumbs down, flag

### Feedback Buttons

| Button | Icon (default) | Icon (active) | Active Color |
|--------|---------------|---------------|-------------|
| Thumbs up | `hand.thumbsup` | `hand.thumbsup.fill` | `.chloePrimary` |
| Thumbs down | `hand.thumbsdown` | `hand.thumbsdown.fill` | `.red` |
| Report | `flag` | `flag.fill` | `.orange` |

- Font: `.system(size: 14)`
- Padding top: 4pt
- All buttons disabled after any feedback is given (`feedbackState != .none`)
- Report button disabled after reported (`feedbackState == .reported`)

## 21.2 StrategyOptionsView

**File:** `Views/Components/StrategyOptionsView.swift`

- Renders `ForEach(options)` as `OptionCard` in a `VStack(spacing: Spacing.xs)`
- Only one option can be selected (tracked by `@State selectedOption`)
- Selection is permanent within the message (no deselect)

### OptionCard Layout

| Element | Font | Color |
|---------|------|-------|
| Label | `.system(size: 15, weight: .semibold)` | Selected: `.chloeTextPrimary`, Default: `.chloeTextSecondary` |
| Action | `.system(size: 14, weight: .regular)` | `.chloeTextSecondary` |
| Outcome | `.system(size: 13, weight: .light).italic()` | `.chloeTextTertiary` |

**Card Background:** `.ultraThinMaterial` fill, `RoundedRectangle(cornerRadius: 12)` border:
- Default: `chloePrimary.opacity(0.2)`, 1pt
- Selected: `chloePrimary`, 2pt

**Animation:** Selected card scales 1.02; unselected cards dim to 0.5 opacity. `.easeOut(duration: 0.2)`.

## 21.3 TypingIndicator

**File:** `Views/Components/TypingIndicator.swift`

- Three dots bouncing in sequence
- Dot color: `Color.chloeAccentMuted`
- Container: same style as Chloe bubble (`chloePrimaryLight` background, `chloePrimary` border)
- Animation: Each dot bounces with staggered delay

## 21.4 Message List in SanctuaryView

- `ScrollViewReader` wrapping `ScrollView` wrapping `LazyVStack(spacing: Spacing.xs)`
- Each message: `ChatBubble` with padding `.horizontal(Spacing.screenHorizontal)`
- Auto-scrolls to bottom on new messages via `.scrollTo(lastMessage.id, anchor: .bottom)` with `.easeOut(duration: 0.3)`
- Chloe messages prefixed with `ChloeAvatar(size: 24)` inline (small orb)

## 21.5 Loading State Display (V2)

| State | UI |
|-------|-----|
| `.idle` | Nothing shown |
| `.routing` | `TypingIndicator` visible |
| `.generating` | `TypingIndicator` visible |

Both routing and generating phases show the same typing indicator to the user. The distinction is internal for future UI differentiation.

---

# SECTION 22: RATE LIMITING UX

> Complete user-facing behavior of the free-tier message limit.

## 22.1 Constants

```swift
let FREE_DAILY_MESSAGE_LIMIT = 5  // Max messages per day for free users
let V1_PREMIUM_FOR_ALL = true     // DEBUG only — bypasses limits
```

In Release builds, `V1_PREMIUM_FOR_ALL = false`.

## 22.2 Rate Limit Flow

```
User sends message
  → Load DailyUsage (date + messageCount)
  → If date != today → reset to 0
  → If V1_PREMIUM_FOR_ALL → skip limit check
  → If profile.subscriptionTier == .premium → skip limit check
  → If messageCount >= FREE_DAILY_MESSAGE_LIMIT (5)
      → Set isLimitReached = true
      → Show paywall sheet
      → Block message send
      → RETURN
  → If messageCount == FREE_DAILY_MESSAGE_LIMIT - 1 (4th message, about to be 5th)
      → isLastFreeMessage = true
  → Process message normally
  → Increment messageCount
  → If isLastFreeMessage:
      → Wait 1.5s (Task.sleep)
      → Append warm goodbye message (random from 3 templates)
      → Set isLimitReached = true
```

## 22.3 Goodbye Templates (after 5th message)

1. "Hey — I loved talking to you today. I'm going to recharge, but I'll be right here tomorrow. You've got this tonight. 💜"
2. "That's a wrap for today, babe. Let everything we talked about settle. I'll be back tomorrow with fresh energy for you."
3. "I'm signing off for now, but I'm not going anywhere. Sleep on it, and come find me tomorrow. I'll be waiting."

## 22.4 Paywall Sheet (isLimitReached)

Triggered by `.sheet(isPresented: $chatVM.isLimitReached)` in `SanctuaryView`.
Current behavior: Shows upgrade prompt. Premium purchase flow not yet implemented (placeholder).

## 22.5 Daily Reset

`StorageService.loadDailyUsage()` checks `usage.date != DailyUsage.todayKey()`. If dates differ, returns fresh `DailyUsage(date: todayKey(), messageCount: 0)`.

`todayKey()` format: `"yyyy-MM-dd"` from `DateFormatter`.

## 22.6 Premium Bypass

Premium users (`profile.subscriptionTier == .premium`) skip ALL rate limiting. In DEBUG mode, `V1_PREMIUM_FOR_ALL` gives all users premium access.

---

# SECTION 23: COMPLETE ONBOARDING FLOW

> Step-by-step walkthrough of the entire onboarding experience.

## 23.1 Flow Overview

```
App Launch → ContentView
  → AuthViewModel.restoreSession()
  → If no session → EmailLoginView
  → If session exists but !onboardingComplete → OnboardingContainerView
  → If session exists and onboardingComplete → SanctuaryView
```

## 23.2 Step 0: WelcomeIntroView

**Trigger:** First screen after authentication
**Purpose:** Brand introduction with kinetic typography

1. Container orb appears (spring animation, 0.6 response)
2. 0.8s delay
3. Text "I'm Chloe. Let's unlock your most magnetic self." reveals word-by-word (0.3s per word)
4. 0.3s pause
5. "Begin My Journey" button slides up (spring, 0.45 response, 0.8 damping)
6. On tap: text dissolves (scale 0.8, offset -80, 0.5s), 15 particles fly to orb (0.6s), then advance

**Data saved:** Nothing

## 23.3 Step 1: NameStepView

**Trigger:** After WelcomeIntroView
**Purpose:** Collect user's display name

1. Question: "What shall I call you, beautiful?"
2. Single text field with glowing underline
3. Orb pulses (scale 1.0→1.08) on each keystroke
4. "Continue" button disabled until name is non-blank
5. Submit via button or keyboard return

**Data saved:** `viewModel.preferences.name = nameText`

## 23.4 Step 2: ArchetypeQuizView (4 pages)

**Trigger:** After NameStepView
**Purpose:** Classify user into one of 7 archetypes via 4 questions

**Page 0 (Energy):** "When you imagine your most powerful self, she is..."
- a: Magnetic, b: Commanding, c: Inspiring, d: Electric

**Page 1 (Strength):** "Your secret weapon is..."
- a: Warmth, b: Intuition, c: Drive, d: Mystery

**Page 2 (Recharge):** "When life gets heavy, you reset by..."
- a: Reflecting, b: Moving, c: Creating, d: Escaping

**Page 3 (Allure):** "In your dream relationship, he's drawn to your..."
- a: Sensuality, b: Standards, c: Depth, d: Wildness

Each page: StaggeredWordReveal question + 2-column `OnboardingCard` grid with staggered spring entrance.

**Data saved:** `viewModel.preferences.archetypeAnswers = ArchetypeAnswers(energy:, strength:, recharge:, allure:)`

## 23.5 Step 3: OnboardingCompleteView

**Trigger:** After all 4 quiz questions answered
**Purpose:** Reveal archetype result and celebrate

1. "You're all set!" in greeting font
2. "YOUR ARCHETYPE" label
3. Archetype name (computed by `ArchetypeService.shared.classify(answers:)`)
4. Description text
5. Confetti cannon fires (50 particles, 0.5s delay)
6. "Meet Chloe" button

**On "Meet Chloe":**
1. `viewModel.completeOnboarding()` called
2. Profile updated: `onboardingComplete = true`, preferences saved
3. Profile saved to local + cloud
4. `NotificationCenter.post(.onboardingDidComplete)`
5. ContentView receives notification → sets `onboardingComplete = true`
6. If notification priming not shown → presents `NotificationPrimingView` sheet

## 23.6 Archetype Classification Logic

**File:** `Services/ArchetypeService.swift`

Maps `ArchetypeAnswers` (4 choices: a/b/c/d) to scores across 7 archetypes:

| Choice | Siren | Queen | Muse | Lover | Sage | Rebel | Warrior |
|--------|-------|-------|------|-------|------|-------|---------|
| Energy: a (Magnetic) | +3 | 0 | +1 | +2 | 0 | 0 | 0 |
| Energy: b (Commanding) | 0 | +3 | 0 | 0 | 0 | +1 | +2 |
| Energy: c (Inspiring) | 0 | 0 | +3 | +1 | +2 | 0 | 0 |
| Energy: d (Electric) | +1 | 0 | 0 | 0 | 0 | +3 | +2 |
| Strength: a (Warmth) | 0 | 0 | +1 | +3 | 0 | 0 | 0 |
| Strength: b (Intuition) | +1 | 0 | 0 | 0 | +3 | +1 | 0 |
| Strength: c (Drive) | 0 | +1 | 0 | 0 | 0 | 0 | +3 |
| Strength: d (Mystery) | +3 | +1 | 0 | 0 | 0 | +2 | 0 |
| Recharge: a (Reflecting) | 0 | 0 | 0 | 0 | +3 | 0 | 0 |
| Recharge: b (Moving) | 0 | 0 | 0 | 0 | 0 | +1 | +3 |
| Recharge: c (Creating) | 0 | 0 | +3 | +2 | 0 | 0 | 0 |
| Recharge: d (Escaping) | +2 | 0 | +1 | 0 | 0 | +3 | 0 |
| Allure: a (Sensuality) | +3 | 0 | +1 | +2 | 0 | 0 | 0 |
| Allure: b (Standards) | 0 | +3 | 0 | 0 | +1 | 0 | +2 |
| Allure: c (Depth) | 0 | 0 | +2 | +1 | +3 | 0 | 0 |
| Allure: d (Wildness) | +1 | 0 | 0 | 0 | 0 | +3 | +1 |

**Result:** Primary = highest score, Secondary = second highest. Tie-breaking: first in enum order. Label = `"The {Primary} / {Secondary}"` blend.

## 23.7 NotificationPrimingView (Post-Onboarding)

**File:** `Views/Components/NotificationPrimingView.swift`

**Trigger:** After onboarding completes, if `!hasShownNotificationPriming()`
**Presented as:** `.sheet(isPresented:)` with `.interactiveDismissDisabled()`

| Element | Details |
|---------|---------|
| Title | "Stay Connected with Chloe" |
| Description | Personalized text explaining notification value |
| "Enable Notifications" button | Calls `NotificationService.shared.requestPermission()` |
| "Not Now" button | Skips; sets `notificationPrimingShown` |

Both paths set `notificationPrimingShown = true`. If permission denied after enable, sets `notificationDeniedAfterPriming = true`.

---

# SECTION 24: INFO.PLIST, BUILD CONFIG, AND DEPENDENCIES

## 24.1 Info.plist Permissions

| Key | Value | Purpose |
|-----|-------|---------|
| `NSCameraUsageDescription` | "Chloe needs camera access so you can share photos in chat." | Camera for chat images |
| `NSPhotoLibraryUsageDescription` | "Chloe needs photo library access so you can share images in chat." | Photo picker for chat/vision |

## 24.2 Info.plist Configuration

| Key | Value |
|-----|-------|
| `CFBundleIdentifier` | `$(PRODUCT_BUNDLE_IDENTIFIER)` → `com.chloepocket.app` |
| `CFBundleShortVersionString` | `1.0` |
| `CFBundleVersion` | `1` |
| `LSRequiresIPhoneOS` | `true` |
| `UIApplicationSupportsMultipleScenes` | `true` |
| `UISupportedInterfaceOrientations` | Portrait only |
| `UILaunchScreen` | Empty dict (system default) |
| `UIAppFonts` | `TenorSans-Regular.ttf`, `Cinzel-Regular.ttf`, `CormorantGaramond-BoldItalic.ttf`, `PlayfairDisplay-Italic-VF.ttf` |

## 24.3 URL Scheme (Deep Linking)

| Key | Value |
|-----|-------|
| `CFBundleURLName` | `com.chloepocket.app` |
| `CFBundleURLSchemes` | `["chloeapp"]` |

Deep link format: `chloeapp://auth-callback?type=recovery#access_token=...`

Handled in `ChloeApp.swift`:
```swift
.onOpenURL { url in
    // Parse URL for auth callback tokens
    // Route to AuthViewModel for session restoration or password recovery
}
```

## 24.4 API Key Configuration (Config.xcconfig)

| Key | Purpose |
|-----|---------|
| `GEMINI_API_KEY` | Google Gemini 2.0 Flash API key |
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase anonymous/public key |
| `DEV_SUPABASE_PASSWORD` | Development test account password |
| `PORTKEY_API_KEY` | Portkey gateway API key (optional) |
| `PORTKEY_VIRTUAL_KEY` | Portkey virtual key for model routing (optional) |
| `PRODUCT_BUNDLE_IDENTIFIER` | `com.chloepocket.app` |

**Config.xcconfig is in .gitignore** — never committed. Keys flow: `Config.xcconfig` → build settings → `Info.plist` `$(VAR)` → `Bundle.main.infoDictionary`.

## 24.5 Entitlements

**File:** `ChloeApp.entitlements`

| Entitlement | Value |
|-------------|-------|
| `com.apple.developer.applesignin` | `["Default"]` |

Apple Sign In capability enabled but not yet implemented in auth flow (email/password only currently).

## 24.6 Build Configuration

| Setting | Value |
|---------|-------|
| Deployment Target | iOS 17.0 |
| Swift Version | Swift 5 |
| Scheme | ChloeApp |
| Build Configuration (Run) | Debug |
| Build Configuration (Archive) | Release |
| Package Manager | Swift Package Manager |
| Test Targets | ChloeAppTests, ChloeAppUITests |

**Build command:**
```bash
xcodebuild -project ChloeApp.xcodeproj -scheme ChloeApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet build
```

## 24.7 Third-Party Dependencies (Exact Versions from Package.resolved)

### Direct Dependencies

| Package | Version | Repository | Purpose |
|---------|---------|-----------|---------|
| Lottie | 4.6.0 | `airbnb/lottie-spm` | Animation playback |
| Kingfisher | 8.6.2 | `onevcat/Kingfisher` | Remote image loading/caching |
| ExyteChat | 2.7.6 | `exyte/Chat` | Chat UI components (not directly used for chat, but dependency) |
| ConfettiSwiftUI | 1.1.0 | `simibac/ConfettiSwiftUI` | Onboarding celebration confetti |
| MarkdownUI | 2.4.1 | `gonzalezreal/swift-markdown-ui` | Markdown rendering |
| TelemetryDeck | 2.11.0 | `TelemetryDeck/SwiftClient` | Analytics/telemetry |
| Supabase Swift | 2.41.0 | `supabase/supabase-swift` | Auth, database, storage |

### Transitive Dependencies (resolved automatically)

| Package | Version | Pulled By |
|---------|---------|----------|
| ActivityIndicatorView | 1.2.1 | ExyteChat |
| AnchoredPopup | 1.1.0 | ExyteChat |
| Giphy iOS SDK | 2.3.0 | ExyteChat |
| MediaPicker | 3.2.4 | ExyteChat |
| NetworkImage | 6.0.1 | MarkdownUI |
| libwebp-Xcode | 1.5.0 | Kingfisher |
| swift-cmark | 0.7.1 | MarkdownUI |
| swift-asn1 | 1.5.1 | Supabase (via swift-crypto) |
| swift-clocks | 1.0.6 | Supabase |
| swift-concurrency-extras | 1.3.2 | Supabase |
| swift-crypto | 4.2.0 | Supabase |
| swift-http-types | 1.5.1 | Supabase |
| xctest-dynamic-overlay | 1.8.1 | Supabase |

### Dependency Notes
- **ExyteChat** brings significant transitive deps (Giphy, MediaPicker, ActivityIndicator). The app does NOT use ExyteChat's chat view — it has its own custom `ChatBubble` + `ChatInputBar`. ExyteChat may be a candidate for removal.
- **Kingfisher** is used for loading remote images (vision board items with cloud URLs).
- **Supabase Swift** is the heaviest transitive dependency tree (auth, PostgREST, storage, realtime).

---

*END OF MASTER HANDOFF DOCUMENT — ALL 24 SECTIONS COMPLETE*
