# ChloeApp — Full Codebase Audit Report

**Date:** February 7, 2026
**Build:** 1.0 (2) — TestFlight Approved
**Auditors:** 5-agent parallel swarm + dependency audit
**Scope:** Every `.swift` file, asset, dependency, and configuration in the project

---

## Remediation Status (February 7, 2026)

**Branch:** `audit-remediation` (from `main` at `1593aab`)
**Pre-change tag:** `pre-audit-v1.0`

All phases completed. 0 build errors, 0 warnings across all 8 phases.

### Phase 1: Critical Security Hardening — DONE
- Replaced 3 `fatalError()` calls with `preconditionFailure()` / graceful fallback
- Added offline account deletion queue (GDPR-safe: throws when offline instead of silently failing)
- Fixed StorageService decode safety: `try?` → `do/catch` with logging, failed decodes not cached
- Capped user facts at 50 with oldest-first eviction
- Capped insight queue at 50 entries
- Cleaned up export temp files and removed deprecated `.synchronize()` calls

### Phase 2: Network Resilience & Error Handling — DONE
- Added server error retry (HTTP 500/503) with exponential backoff (1s/2s/4s) in GeminiService
- Added HTTP status validation on `downloadImage()` (non-2xx throws `StorageError.downloadFailed`)
- Added `PushLock` actor to prevent concurrent `pushAllToCloud()` executions
- Added 0.5s debounce for `pushUserStateToCloud()`
- Added retry-once-after-2s for all 5 cloud delete operations
- Added offline guard to FeedbackService

### Phase 3: AI Memory & Prompt Safety — DONE
- Added `sanitizeForPrompt()` — strips XML-like injection tags, caps text length
- All user facts, session summaries, and insights sanitized before prompt injection
- Messages truncated to 4000 chars each in API calls
- Behavioral loops sanitized (XML stripped, 200-char cap) before prompt injection
- Leaked internal instruction labels stripped from strategist output (16 labels)
- Response text capped at 5000 chars
- Session summary capped at 500 chars, notification text at 200 chars
- Behavioral loops capped at 5 per analysis extraction
- Per-extraction fact cap at 10

### Phase 4: Quick Wins — Dead Code, Dependencies, Constants — DONE
- Deleted unused `ChloeEmptyState.swift`
- Removed unused `showRetryButton` property from SyncStatusBadge
- Removed 79 lines of unused font utilities (4 functions, 2 properties, 5 ViewModifiers)
- Fixed BUG-1: duplicate `chloeSpring` definition now references `Spacing.chloeSpring`
- Added `.chloeSuccess` color constant, replaced 25+ hardcoded hex colors across 10 files
- Removed MarkdownUI SPM dependency (0 imports found, ~1MB binary savings)
- Removed deprecated `.synchronize()` call from app entry point

### Phase 5: SyncDataService Decomposition — DONE
- Extracted `pushToCloud(_:)` generic helper replacing 10 duplicated push methods
- Extracted `mergeByID<T: Identifiable>()` generic helper replacing 3 merge patterns
- File reduced from 1246 to 1155 lines (-91 lines, -7.3%)

### Phase 6: ViewModel & View Cleanup — DONE
- Broke `ChatViewModel.sendMessage()` from 260-line monolith into 7 focused helpers
- Extracted shared `String.isValidEmail` property, removed 2 duplicate implementations
- Added `chloeAuthSubheading` font constant, replaced 7 inline font declarations

### Phase 7: Performance Optimization — DONE
- Cached 3 `DateFormatter` instances as static properties (StreakService, AboutChloe, Settings)
- Reduced particle animation from 120fps to 60fps
- Deleted 2 unused font files (-401KB)
- Moved image compression off main thread (background `DispatchQueue`)
- Cached `screenWidth` as `@State` instead of re-querying `UIApplication` per render
- Removed duplicate `loadGhostMessages()` call in `onAppear`
- Changed `recentConversations` from computed O(n log n) to stored `@Published` property

### Phase 8: Testing & Documentation — DONE
- Fixed 5 test files missing from Xcode project (ChatViewModelTests, GeminiServiceTests, MessageModelTests, SyncDataServiceTests + new StringUtilsTests)
- Added 20+ new unit tests covering: `String.isValidEmail`, `sanitizeForPrompt`, `sanitizeResponseText`, fact merge caps (10/extraction, 50/total), case-insensitive/substring dedup
- Fixed `ChatViewModelTests` compilation (adapted to `isTyping` computed property change)
- All existing tests pass

### Items NOT Addressed (Require Infrastructure Changes)
- **SEC-1:** Gemini API key in client binary — requires server-side proxy (infrastructure)
- **SEC-2:** Unencrypted UserDefaults — requires migration to encrypted storage (breaking change)
- **SEC-3:** User PII sent to Gemini — requires privacy policy update + data minimization
- **SEC-4:** System prompts in client binary — requires server-side prompt management
- **ARCH-3:** SettingsView 743 lines — functional, lower priority than addressed items

---

## Executive Summary

**Overall Health Score: 6.5 / 10**

The app is functional, builds with zero warnings, and has a solid foundation (MVVM, protocol-based DI, async/await). However, significant issues exist in security (API key in client binary, unencrypted user data), architecture (god files, incomplete DI), and test coverage (critical paths untested). The codebase carries notable dead code and duplication that increases maintenance burden.

### Top 5 Most Critical Findings

| # | Finding | Category | Risk |
|---|---------|----------|------|
| 1 | Gemini API key embedded in client binary — extractable from IPA | Security | Critical |
| 2 | All user data (chats, journal, behavioral analysis) stored in unencrypted UserDefaults | Security | Critical |
| 3 | User PII (name, relationship history, behavioral loops) sent to Gemini API | Security | Critical |
| 4 | SyncDataService.swift is 1,180 lines with 260+ line functions and 10x duplicated boilerplate | Architecture | Critical |
| 5 | AuthService, FeedbackService, and 6/8 ViewModels have zero unit tests | Testing | Critical |

### Findings Summary

| Agent | Total Findings | Critical | High | Medium | Low |
|-------|---------------|----------|------|--------|-----|
| Security & Error Handling | 32 | 4 | 10 | 12 | 6 |
| Code Quality & Architecture | 84 | 6 | 27 | 33 | 18 |
| Performance & Bloat | 24 | 0 | 2 | 12 | 10 |
| Dead Code & Duplication | 25+ | 1 (bug) | 6 | 10 | 8 |
| Testing & Documentation | 20+ | 3 | 5 | 8 | 4 |
| **Total** | **185+** | **14** | **50** | **75** | **46** |

---

## 1. Critical Issues — Fix IMMEDIATELY

### SEC-1: Gemini API Key in Client Binary
**File:** `Services/GeminiService.swift:34-36`
**Risk:** Critical

The Gemini API key is read from `Info.plist` (baked in at build time from `Config.xcconfig`) and sent in every request header. Anyone who downloads the IPA can extract this key and make unlimited API calls billed to the developer's Google account.

```swift
private var apiKey: String {
    Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String ?? ""
}
```

**Fix:** Implement a server-side proxy. The client authenticates to your server (via Supabase auth token), and the server holds the Gemini key and forwards requests.

---

### SEC-2: Unencrypted User Data in UserDefaults
**File:** `Services/StorageService.swift` (entire file)
**Risk:** Critical

ALL user data — chat messages, journal entries, profile (email, name), behavioral analysis, user facts, AI-generated psychological assessments — is stored in plain UserDefaults. This is:
- Readable by anyone with physical device access
- Included in unencrypted iTunes backups
- Accessible on jailbroken devices

For an AI relationship advisor app handling deeply personal information, this is a severe privacy risk.

**Fix:** Migrate sensitive data to files in Documents directory with `NSFileProtectionComplete`, or use SwiftData/Core Data with encryption. UserDefaults should only hold non-sensitive preferences.

---

### SEC-3: User PII Sent to Gemini API
**File:** `Services/GeminiService.swift:56-63`, `ViewModels/ChatViewModel.swift:201-206`
**Risk:** Critical

User's display name, archetype, vibe score, known facts (relationship history, behavioral patterns), and session summaries are sent to Google's Gemini API in every chat request. Google can log this data per their retention policies.

**Fix:** Disclose in privacy policy. Minimize PII sent. Use pseudonyms instead of real names. Investigate Gemini API data processing agreements.

---

### SEC-4: System Prompts in Client Binary
**File:** `Constants/Prompts.swift` (648 lines)
**Risk:** High

The entire AI strategy, coaching framework, engagement hooks, and output protocols are embedded in client-side source code. Anyone decompiling the IPA can read the complete system prompts and manipulate the AI.

**Fix:** Move system prompts to server-side configuration.

---

### ARCH-1: SyncDataService God File (1,180 lines)
**File:** `Services/SyncDataService.swift`
**Risk:** Critical

Single file handling ALL sync operations with:
- 10x duplicated push-to-cloud boilerplate
- 312-line `syncFromCloud()` method
- Mixed responsibilities (local storage, cloud sync, conflict resolution, retry logic)

**Fix:** Extract into focused services: `SyncPushService`, `SyncPullService`, `SyncConflictResolver`. Extract shared push pattern into generic helper.

---

### ARCH-2: ChatViewModel.sendMessage() — 260 Lines
**File:** `ViewModels/ChatViewModel.swift`
**Risk:** Critical

The most critical user-facing code path is a single 260-line function handling: input validation, image saving, message creation, safety checks, routing, API calls, response parsing, error handling, analytics, and state updates.

**Fix:** Break into focused methods: `validateInput()`, `prepareMessage()`, `routeMessage()`, `handleResponse()`, `handleError()`.

---

### ARCH-3: SettingsView — 743 Lines, No ViewModel
**File:** `Views/Main/SettingsView.swift`
**Risk:** High

743-line view file performing business logic directly (profile saves, image uploads, data export, account deletion) with no ViewModel. Violates MVVM architecture.

**Fix:** Extract `SettingsViewModel` for all business logic.

---

### TEST-1: Zero Tests on Critical Auth Paths
**Files:** `Services/AuthService.swift`, `Services/FeedbackService.swift`
**Risk:** Critical

Sign-in, sign-up, password reset, session restore, and deep link handling have zero unit tests. Only the AuthViewModel state machine is tested. FeedbackService (user reports of harmful AI content) has no tests at all.

---

### BUG-1: Duplicate chloeSpring Animation Values
**Files:** `Theme/Spacing.swift:40` vs `Theme/ChloeViewModifiers.swift:47`
**Risk:** High (visual inconsistency)

Two different spring animations named `chloeSpring` with different parameters:
- `Spacing.chloeSpring`: response 0.45, damping 0.8
- `Animation.chloeSpring`: response 0.5, damping 0.85

Both are actively used across different views, creating inconsistent animation feel.

**Fix:** Consolidate to one definition. Delete the other.

---

## 2. High Priority — Fix Soon

### Security (High)

| ID | Finding | File | Lines |
|----|---------|------|-------|
| SEC-5 | `fatalError()` crashes app if Supabase config missing | `SupabaseClient.swift` | 21, 30 |
| SEC-6 | `fatalError()` in Apple Sign-In nonce generation | `EmailLoginView.swift` | 422 |
| SEC-7 | Delete account while offline silently skips cloud deletion | `SyncDataService.swift` | 1173 |
| SEC-8 | Storage deletion errors silently swallowed during account delete | `SupabaseDataService.swift` | 668-670 |
| SEC-9 | No SSL pinning on any API endpoint | `GeminiService.swift` | 367 |
| SEC-10 | Local profile fallback bypasses auth validation | `AuthService.swift` | 395-406 |
| SEC-11 | Data export written to temp dir without cleanup or encryption | `SettingsView.swift` | 575-580 |
| SEC-12 | Auth state flags stored in plain UserDefaults | `AuthService.swift` | 280, 349 |

### Architecture (High)

| ID | Finding | File |
|----|---------|------|
| ARCH-4 | 80+ direct `.shared` singleton references in Views bypass DI container | Multiple view files |
| ARCH-5 | Missing ViewModels for HistoryView, ContentView | `Views/Main/` |
| ARCH-6 | Duplicated push-to-cloud boilerplate repeated 10+ times | `SyncDataService.swift` |
| ARCH-7 | Duplicated merge-by-ID logic repeated 5+ times in syncFromCloud | `SyncDataService.swift` |

### Performance (High)

| ID | Finding | File | Lines |
|----|---------|------|-------|
| PERF-1 | pushUserStateToCloud() called 4-6x redundantly per analysis cycle | `SyncDataService.swift` | 1035-1098 |
| PERF-2 | ChatViewModel has 10 @Published properties causing full-tree re-renders | `ChatViewModel.swift` | 14-29 |

### Dead Code (High)

| ID | Finding | File |
|----|---------|------|
| DEAD-1 | ChloeEmptyState.swift — entire file unused (superseded by EmptyStateView) | `Views/Components/` |
| DEAD-2 | MarkdownUI SPM dependency — never imported, adds ~1MB + 2 transitive deps | `project.pbxproj` |

### Testing (High)

| ID | Finding |
|----|---------|
| TEST-2 | 6/8 ViewModels have zero unit tests |
| TEST-3 | 8+ always-pass tests using `XCTAssertTrue(true, ...)` |
| TEST-4 | 4 network simulation flags referenced but never implemented |
| TEST-5 | No README.md, no CHANGELOG.md, no docs/ directory |

---

## 3. Medium Priority — Fix When Possible

### Security (Medium)

| Finding | File |
|---------|------|
| Silent `try?` on profile saves after sign-in | `AuthService.swift:122,227,456,473` |
| Image save returns nil with no error info | `StorageService.swift:96-101` |
| Weak email validation (only checks @ and .) | `EmailLoginView.swift:24-29` |
| Minimum password length only 6, no complexity | `EmailLoginView.swift:37` |
| No input sanitization for prompt injection | `ChatViewModel.swift:87-101` |
| Sign-out doesn't await Supabase response | `AuthService.swift:326` |
| Account deletion catch still clears local data | `SettingsView.swift:550-556` |
| Export file not cleaned up after share | `SettingsView.swift:575-585` |
| Sync errors swallowed in production | `SyncDataService.swift` (multiple) |
| NSLock could deadlock on recursive access | `StorageService.swift:20` |

### Performance (Medium)

| Finding | File |
|---------|------|
| Double loadGhostMessages() call in loadData() | `SanctuaryView.swift:244-245` |
| pushAllToCloud() spawns 100+ concurrent Tasks | `SyncDataService.swift:168-197` |
| buildPreviousUserMessageMap recomputed every render | `SanctuaryView.swift:403` |
| recentConversations O(n log n) sort on every render | `SanctuaryViewModel.swift:67-71` |
| screenWidth queries UIApplication on every body eval | `SanctuaryView.swift:46-50` |
| Duplicate LinearGradient background | `SanctuaryView.swift:55-60, 264-268` |
| Synchronous image compression on main thread | `StorageService.swift:90-101` |
| Synchronous profile image load from disk | `SanctuaryViewModel.swift:42-46` |
| UserDefaults used as database (1MB per-key limit) | `StorageService.swift:248-253` |
| Unused font files bundled (401 KB) | `Resources/Fonts/` |

### Dead Code & Duplication (Medium)

| Finding | File |
|---------|------|
| Email validation logic duplicated verbatim | `EmailLoginView.swift` / `PasswordResetView.swift` |
| Auth header pattern copy-pasted 5 times | All auth views |
| Input field underline styling duplicated 5 times | All auth + onboarding views |
| Inline gradient instead of GradientBackground component | `ChloeApp.swift`, `ContentView.swift`, `SanctuaryView.swift` |
| `Color(hex: "#B76E79")` hardcoded 15+ times instead of `.chloePrimary` | 8 files |
| `Color(hex: "#4A7C59")` hardcoded 10+ times with no named constant | 4 files |
| `.custom(ChloeFont.headerDisplay, size: 13)` repeated 7 times | Auth + onboarding views |

---

## 4. Low Priority — Cleanup Items

### Dead Code to Remove

| Item | File | Lines |
|------|------|-------|
| `buildPersonalizedPrompt()` — only used in tests | `Prompts.swift` | 570 |
| `showRetryButton` — computed but never read | `SyncStatusBadge.swift` | 148 |
| `String.trimmed` — never used (.trimmingCharacters used directly) | `String+Utils.swift` | 4 |
| 4 parametric font functions — never called | `Fonts.swift` | 9-23 |
| 2 static font properties — never used | `Fonts.swift` | 34, 37 |
| 5 ViewModifier structs + 5 extension methods — never used | `Fonts.swift` | 82-146 |
| `GoalStatus.paused` — enum case never assigned | `Goal.swift` | 37 |
| `AffirmationsViewModel` — never instantiated | `AffirmationsViewModel.swift` | entire file |
| Commented-out font definitions | `DynamicTypeTests.swift` | 152-156 |

### Performance (Low)

| Finding | File |
|---------|------|
| DateFormatter recreated on every call | `StreakService.swift:55`, `Date+Formatting.swift:5` |
| Unbounded messages cache, no LRU eviction | `StorageService.swift:33` |
| Unnecessary `.receive(on: DispatchQueue.main)` | `ChatViewModel.swift:68` |
| Deprecated `.synchronize()` calls | `ChloeApp.swift:144`, `AuthService.swift:281` |
| EtherealDustParticles at 120fps (30-60 sufficient) | `EtherealDustParticles.swift:27` |

### Security (Low)

| Finding | File |
|---------|------|
| Debug logging may contain PII (properly gated) | `AuthViewModel.swift:29-58` |
| NSLog used instead of print (in DEBUG block) | `FeedbackService.swift:76` |
| Display name in notification content (lock screen visible) | `NotificationService.swift:67-77` |

---

## 5. Dependency Audit

| Package | Pinned | Latest | Status | Action |
|---------|--------|--------|--------|--------|
| **MarkdownUI** | 2.4.1 | 2.4.1 | **UNUSED** | **REMOVE** — 0 imports, adds ~1MB + 2 transitive deps |
| **ConfettiSwiftUI** | 1.1.0 | 3.0.0 | 2 majors behind | **UPDATE** — 1 param rename in 1 file |
| **Supabase** | 2.41.0 | 2.41.1 | 1 patch behind | **UPDATE** — MFA bugfix |
| **TelemetryDeck** | 2.11.0 | 2.11.0 | Current | **KEEP** |

**Unused font files (401 KB):** `PlayfairDisplay-Italic-VF.ttf` (272 KB), `TenorSans-Regular.ttf` (129 KB)

---

## 6. Quick Wins — Easy Fixes, Immediate Impact

These can each be done in under 30 minutes:

| # | Fix | Impact | Effort |
|---|-----|--------|--------|
| 1 | Remove MarkdownUI SPM dependency | -1MB binary, -2 transitive deps | 5 min |
| 2 | Delete `ChloeEmptyState.swift` | Remove dead file | 2 min |
| 3 | Remove unused font files + Info.plist entries | -401 KB | 10 min |
| 4 | Fix duplicate `chloeSpring` animation values | Fix visual bug | 5 min |
| 5 | Remove 10 dead ViewModifier items from Fonts.swift | Remove ~65 lines dead code | 10 min |
| 6 | Remove 4 dead parametric font functions | Remove dead code | 5 min |
| 7 | Remove deprecated `.synchronize()` calls | Remove deprecation | 2 min |
| 8 | Update ConfettiSwiftUI to 3.0.0 | Stay current | 15 min |
| 9 | Update Supabase to 2.41.1 | Patch fix | 5 min |
| 10 | Replace hardcoded `Color(hex: "#B76E79")` with `.chloePrimary` | Consistency | 15 min |

---

## 7. Architecture Recommendations

### Short Term (Before App Store)
1. **Server-side API proxy** — Move Gemini API key off the client. This is the #1 security priority.
2. **Encrypt user data at rest** — Migrate off UserDefaults for sensitive data.
3. **Replace `fatalError()` calls** with graceful error handling.

### Medium Term (Next 2-3 Releases)
4. **Extract SettingsViewModel** — Move 743 lines of business logic out of the view.
5. **Break up SyncDataService** — Extract push/pull into focused services, deduplicate boilerplate.
6. **Break up ChatViewModel.sendMessage()** — 260 lines → 5-6 focused methods.
7. **Complete DI migration** — Replace 80+ `.shared` references in views with injected dependencies.
8. **Add unit tests** for AuthService, SyncDataService, and remaining ViewModels.

### Long Term (V2+)
9. **Migrate storage to SwiftData/SQLite** — UserDefaults has a ~1MB per-key limit and no encryption.
10. **Move system prompts server-side** — Enable prompt updates without app releases.
11. **Add SSL pinning** for API endpoints.
12. **Implement proper offline queue** for account deletion and critical operations.

---

## 8. Action Plan — Ordered Implementation

### Phase 1: Security Hardening (Before App Store)
1. Implement server-side Gemini API proxy
2. Migrate sensitive data off UserDefaults (at minimum: Keychain for auth, file protection for chats)
3. Replace `fatalError()` with graceful degradation
4. Fix delete-account-while-offline to queue deletion
5. Clean up temp export files after sharing

### Phase 2: Quick Wins (1 Session)
6. Remove MarkdownUI dependency
7. Delete ChloeEmptyState.swift
8. Remove unused fonts
9. Fix duplicate chloeSpring bug
10. Remove all dead code from Fonts.swift
11. Update ConfettiSwiftUI and Supabase
12. Replace hardcoded hex colors with theme constants

### Phase 3: Architecture Cleanup
13. Extract SettingsViewModel
14. Break up ChatViewModel.sendMessage()
15. Debounce pushUserStateToCloud()
16. Extract shared push-to-cloud pattern in SyncDataService
17. Extract shared auth UI components (header, input underline, email validation)

### Phase 4: Testing & Documentation
18. Add unit tests for AuthService
19. Add unit tests for remaining ViewModels
20. Fix always-pass tests
21. Implement network simulation flags in UITestSupport
22. Add README.md and basic documentation

### Phase 5: Performance & Polish
23. Split ChatViewModel @Published properties (or migrate to @Observable)
24. Cache recentConversations and previousUserMessageMap
25. Move image compression to background thread
26. Add LRU eviction to messages cache
27. Batch pushAllToCloud() with concurrency limits

---

## Positive Findings (Things Done Well)

1. **Zero build warnings** — Clean Swift 6 concurrency compliance
2. **All print() statements gated behind `#if DEBUG`** — No PII in production logs
3. **Protocol-based DI** in ViewModels (ServiceContainer pattern)
4. **Rate limiting** on Gemini API with exponential backoff
5. **Safety service** for crisis detection with proper crisis resources
6. **Input length validation** — 10,000 char limit on chat messages
7. **TelemetryDeck analytics are privacy-first** — No PII in signals
8. **RLS policies on Supabase** — All tables use auth.uid() pattern
9. **CASCADE deletion** — Profile deletion cascades to all child tables
10. **Thread safety with NSLock** on StorageService
11. **Structured sync status** — UI reflects sync state to users
12. **Haptic feedback** and loading states on auth buttons
13. **Performance optimizations** already applied (Waves 1-3: drawingGroup, particle pausing, image caching, state batching)

---

## 8. Git History Audit

### 8.1 Repository Overview

| Metric | Value |
|--------|-------|
| Repository size (`.git/`) | 8.3 MB |
| Total commits | 117 |
| Date range | 2026-01-30 to 2026-02-07 (9 days) |
| Active branch | `main` |
| Sync status | Fully synced with `origin/main` (0 ahead, 0 behind) |
| Pack files | None (all loose objects) |
| Largest blob | ~225 KB compressed |

### 8.2 Secrets Scan — ALL CLEAN

| Check | Status | Details |
|-------|--------|---------|
| `Config.xcconfig` committed | CLEAN | Never committed; properly in `.gitignore` |
| Hardcoded API keys in history | CLEAN | All keys use `$(VARIABLE)` substitution from xcconfig |
| JWT tokens (`eyJ` prefix) | CLEAN | None found in any commit |
| Google API keys (`AIza` prefix) | CLEAN | None found |
| OpenAI/Anthropic keys (`sk-` prefix) | CLEAN | None found |
| `.env` files tracked | CLEAN | None tracked |

All sensitive values in `Info.plist` use build variable references (`$(GEMINI_API_KEY)`, `$(SUPABASE_URL)`, `$(SUPABASE_ANON_KEY)`, etc.) resolved from `Config.xcconfig` at build time. The actual secrets file has never been committed.

### 8.3 Branch Status

| Branch | Type | Last Commit | Status |
|--------|------|-------------|--------|
| `main` | Local + Remote | `1593aab` Fix profile/vision images | Active, fully synced |
| `feature/safe-dedup` | Local only | `8c4ae61` safe dedup: spring animations | Stale — no remote tracking |
| `origin/feature/notification-priming` | Remote only | `20bb85a` Wire image upload e2e | Stale — not checked out locally |

### 8.4 Working Tree

- **Staged:** None
- **Modified:** None
- **Untracked:** `AUDIT_REPORT.md`
- **Stashed:** None

### 8.5 .gitignore Review

Current `.gitignore` is **adequate** — covers Xcode artifacts, SPM, CocoaPods, `Config.xcconfig`, and OS files.

**Hardening recommendations:**
```
# Add for defense in depth
.env*
*.xcconfig
!*.xcconfig.template
Secrets/
*.key
*.pem
```

### 8.6 Git History Findings

| Finding | Severity | Recommendation |
|---------|----------|----------------|
| PAT exposed in remote URL (`.git/config`) | Medium | Switch to SSH or use macOS Keychain credential helper |
| `feature/safe-dedup` stale local branch | Low | Delete if work is abandoned: `git branch -d feature/safe-dedup` |
| `origin/feature/notification-priming` stale remote branch | Low | Delete if merged/abandoned: `git push origin --delete feature/notification-priming` |
| `.gitignore` missing `*.xcconfig` wildcard | Low | Add `*.xcconfig` with `!*.xcconfig.template` negation |
| `DEV_SUPABASE_PASSWORD` key in Info.plist | Low | Consider reading from debug-only mechanism instead of production plist |

**Overall assessment:** Repository is in excellent shape for secrets hygiene. No credentials have ever been committed. The main concerns are the two stale branches and the PAT embedded in the remote URL.

---

## 9. API & Network Layer Audit

**Auditors:** 4-agent parallel swarm (GeminiService, Supabase/Sync, Auth, NetworkMonitor+remaining)
**Scope:** Every network call, timeout, retry path, offline behavior, and response validation

### 9.1 Architecture Overview

The app has no single central HTTP layer. Two distinct networking approaches are used:
1. **Supabase Swift SDK** — handles all database, storage, and auth operations (uses its own internal URLSession)
2. **Raw URLSession** — used only by `GeminiService.swift` for direct Gemini API calls

| Layer | File | Purpose |
|-------|------|---------|
| Connectivity | `NetworkMonitor.swift` | NWPathMonitor wrapper |
| Supabase Client | `SupabaseClient.swift` | Singleton SupabaseClient config |
| Supabase CRUD | `SupabaseDataService.swift` | All Supabase DB + Storage operations |
| Sync Engine | `SyncDataService.swift` | Offline-first sync orchestrator |
| AI API | `GeminiService.swift` | Direct HTTP to Gemini REST API |
| Analytics | `ChloeApp.swift` (`trackSignal`) | TelemetryDeck (third-party SDK) |
| Auth | `AuthService.swift` | Supabase Auth (via SDK) |
| Feedback | `FeedbackService.swift` | Supabase insert for feedback |
| Analyst | `AnalystService.swift` | Thin wrapper around GeminiService |

### 9.2 Critical Findings

#### NET-C1: Account Deletion Silently Skips Cloud Data When Offline
**Severity:** Critical
**File:** `SyncDataService.swift:1164-1175`

```swift
func deleteAccount() async throws {
    local.clearAll()
    resetPendingChanges()
    guard network.isConnected else { return }  // SILENT SKIP
    try await remote.deleteAllUserData()
}
```

If offline, local data is wiped, function returns successfully (no error), but cloud data is never deleted. No retry, no queued deletion, no user notification. This is a GDPR/privacy violation.

### 9.3 High Severity Findings

| # | Finding | File | Impact |
|---|---------|------|--------|
| NET-H1 | No retry for transient server errors (500/502/503) in GeminiService | `GeminiService.swift:384-387` | Only 429 is retried; 500s fail immediately |
| NET-H2 | URLError catch-all misclassifies errors as timeouts | `GeminiService.swift:392-401` | DNS failures, TLS errors all show "taking too long" |
| NET-H3 | No timeout configured on Supabase client (defaults to 60s) | `SupabaseClient.swift:45-62` | 8+ sequential sync calls = 8+ min potential hang |
| NET-H4 | No cancel mechanism during authentication | `EmailLoginView.swift:172-233` | User stuck at spinner for up to 60s |
| NET-H5 | Silent `guard return` on missing auth in SupabaseDataService | `SupabaseDataService.swift:133-652` | `deleteAllUserData()` silently skipped if session expired |
| NET-H6 | No retry on transient failures in SupabaseDataService | `SupabaseDataService.swift` (all methods) | Single attempt; 500s propagate immediately |
| NET-H7 | `pushAllToCloud()` re-uploads entire dataset on every retry | `SyncDataService.swift:168-197` | No dirty tracking; 50 convos = 50+ concurrent requests |
| NET-H8 | No concurrency guard on `pushAllToCloud()` | `SyncDataService.swift:168` | Network flaps cause overlapping push swarms |
| NET-H9 | FeedbackService silently swallows all errors | `FeedbackService.swift:70-78` | User safety reports silently lost |
| NET-H10 | FeedbackService has no offline handling | `FeedbackService.swift:46-78` | Offline feedback submissions permanently lost |
| NET-H11 | Profile + image upload not atomic | `SyncDataService.swift:630-634` | Image upload can succeed while profile save fails |

### 9.4 Medium Severity Findings

| # | Finding | File |
|---|---------|------|
| NET-M1 | No request cancellation for in-flight Gemini calls | `GeminiService.swift:351-405` |
| NET-M2 | Two sequential API calls per user message (Router + Strategist) | `ChatViewModel.swift:171-268` |
| NET-M3 | Full system prompts re-sent on every request (no caching) | `GeminiService.swift:68-170` |
| NET-M4 | User PII sent without minimization to Gemini | `GeminiService.swift:56-63` |
| NET-M5 | No offline guard in GeminiService itself | `GeminiService.swift:351-405` |
| NET-M6 | No response size validation before JSON parsing | `GeminiService.swift:367, 424-433` |
| NET-M7 | Profile fetch errors silently swallowed via `try?` in auth paths | `AuthService.swift:121-128` |
| NET-M8 | `restoreSession` has no retry on cold-start, no reconnect hook | `AuthService.swift:339-409` |
| NET-M9 | No proactive offline check before auth attempts | `AuthService.swift:104-153` |
| NET-M10 | Race window allowing duplicate auth requests on rapid taps | `EmailLoginView.swift:172-181` |
| NET-M11 | `pushUserStateToCloud()` called 2-5x per message (no debounce) | `SyncDataService.swift` (7 call sites) |
| NET-M12 | `downloadImage()` ignores HTTP status code entirely | `SupabaseDataService.swift:635-638` |
| NET-M13 | Signed URLs not cached (regenerated every call) | `SupabaseDataService.swift:629-632` |
| NET-M14 | `syncFromCloud` re-fetches all data (no If-Modified-Since) | `SyncDataService.swift:201-513` |
| NET-M15 | Enum raw value defaults silently mask data corruption | `SupabaseDataService.swift:174-559` |
| NET-M16 | Failed cloud deletes not retried — items reappear after sync | `SyncDataService.swift:711-723` |
| NET-M17 | `hasPendingChanges` race condition (scheduleRetry outside lock) | `SyncDataService.swift:60-72` |
| NET-M18 | N+1 sequential queries for message sync (not parallelized) | `SyncDataService.swift:241-320` |
| NET-M19 | `deleteAllUserData` is non-atomic (storage + DB separate) | `SupabaseDataService.swift:651-678` |
| NET-M20 | Deletion operations blocked offline without queuing | `SyncDataService.swift:711-951` |

### 9.5 Low Severity Findings

| # | Finding | File |
|---|---------|------|
| NET-L1 | Inconsistent cancellation handling in retry delays | `GeminiService.swift:203, 379-381` |
| NET-L2 | No caching for title generation or affirmations | `GeminiService.swift:292-343` |
| NET-L3 | Fallback response may expose internal reasoning | `GeminiService.swift:221-229` |
| NET-L4 | `extractText` ignores Gemini error/block fields | `GeminiService.swift:424-433` |
| NET-L5 | Hardcoded model version in URL | `GeminiService.swift:31` |
| NET-L6 | Error classification relies on fragile string matching | `AuthService.swift:503-535` |
| NET-L7 | Sign-out fire-and-forget; server token may remain valid | `AuthService.swift:325-327` |
| NET-L8 | Vision images uploaded with no size limits | `SyncDataService.swift:932-941` |
| NET-L9 | `retryCount` not thread-safe | `SyncDataService.swift:80-149` |
| NET-L10 | JSON decode retry re-sends entire API request | `GeminiService.swift:189-214` |

### 9.6 Positive Findings

- GeminiService has good rate limit handling with exponential backoff (2s, 4s, 8s)
- Reasonable 15-second timeout on Gemini requests
- TelemetryDeck analytics properly implemented — privacy-first, no PII
- Auth tokens stored in Keychain by Supabase SDK
- Apple Sign In nonce flow is cryptographically correct
- User-friendly error messages via `friendlyError()` mapping
- Session management (refresh, cold start, deep link) properly handled
- `SyncLock` actor prevents concurrent `syncFromCloud()` operations
- NetworkMonitor correctly detects connectivity changes and triggers reconnect

### 9.7 Priority Recommendations

1. **[Critical]** Queue account deletion for retry when offline — never silently skip
2. **[High]** Route FeedbackService through SyncDataService for offline queuing and retry
3. **[High]** Add retry logic for 500/502/503 in GeminiService (alongside existing 429 retry)
4. **[High]** Add concurrency guard to `pushAllToCloud()` matching `syncFromCloud()`'s `SyncLock`
5. **[High]** Implement dirty-tracking to avoid full-dataset re-upload on retry
6. **[Medium]** Debounce `pushUserStateToCloud()` with 1-2 second delay
7. **[Medium]** Flag failed cloud deletes in `hasPendingChanges` to prevent ghost data
8. **[Medium]** Validate HTTP status codes in `downloadImage()` before treating data as image
9. **[Medium]** Add timeout configuration to Supabase client (15-30s per request)
10. **[Medium]** Add cancel button or auto-timeout during auth loading state

---

## 10. AI Memory System Audit

**Auditors:** 3-agent parallel swarm (Router/Strategist/Analyst memory, Chat/Journal persistence, AI prompt system)
**Scope:** All data persistence, memory growth, context window, prompt construction, privacy

### 10.1 Architecture Overview

| Component | Purpose | Storage |
|-----------|---------|---------|
| **Router** | Classifies messages by category/urgency via LLM | Stateless (result stored in `RouterMetadata` per message) |
| **Strategist** | Generates structured JSON responses with internal reasoning | Stateless (context injected per call) |
| **Analyst** | Extracts facts, detects behavioral loops, scores vibes | Results stored in UserDefaults via StorageService |
| **StorageService** | Local persistence layer | `UserDefaults.standard` + in-memory caches |
| **SyncDataService** | Offline-first sync wrapper | Writes local-first, pushes to Supabase async |

### 10.2 Critical Findings

#### MEM-C1: All User Data Stored in Unencrypted UserDefaults
**Severity:** Critical
**File:** `StorageService.swift:13`

All memory system data — conversation history (deeply personal relationship discussions), user facts (extracted PII), internal AI reasoning, vibe scores, session summaries — is stored in `UserDefaults.standard`, which writes to an unencrypted plist file. On a jailbroken device or via unencrypted backup, all data is trivially extractable.

#### MEM-C2: UserDefaults Used as Primary Database for Growing Datasets
**Severity:** Critical
**File:** `StorageService.swift` (throughout)

UserDefaults is designed for small preference values. The entire app data model — profile, conversations, messages, journal entries, goals, affirmations, vision items, user facts — is serialized as JSON. UserDefaults loads its entire property list into memory at launch. Individual values have ~4MB limits on iOS. No transactional guarantees. This is a ticking time bomb for long-term users.

#### MEM-C3: User Facts Array Grows Without Bounds
**Severity:** Critical
**File:** `AnalystService.swift:30-48`, `StorageService.swift:410-436`

`mergeNewFacts` only deduplicates by exact string match. Slight LLM rephrasing creates duplicates. No cap, no expiry, no pruning. These facts are injected into every Strategist API call, growing the prompt (and cost) linearly with user lifetime. A power user could accumulate hundreds of facts adding thousands of tokens per request.

### 10.3 High Severity Findings

| # | Finding | File | Impact |
|---|---------|------|--------|
| MEM-H1 | Chat messages stored in UserDefaults with no per-conversation cap | `StorageService.swift:248-254` | 1000+ message conversation = huge plist entry |
| MEM-H2 | No conversation/message retention or archival policy | `StorageService.swift:160-243` | Data grows forever without cleanup |
| MEM-H3 | JSON decode failures silently return empty arrays | `StorageService.swift:241-283` | Corrupted data → empty array → overwrites real data on next save |
| MEM-H4 | No schema versioning for stored data | `StorageService.swift` | Model field changes break deserialization, silently losing all data |
| MEM-H5 | Analyst receives ALL messages — no truncation | `GeminiService.swift:50-65`, `ChatViewModel.swift:457` | Up to 100+ messages sent in one API call |
| MEM-H6 | AI-generated behavioral loops injected as system prompt instructions | `ChatViewModel.swift:247-256` | Indirect prompt injection vector (self-injection) |
| MEM-H7 | Safety check is client-side regex only — easily bypassed | `SafetyService.swift:89-103` | Obfuscation, unicode, spacing all bypass |
| MEM-H8 | Chat images orphaned on conversation delete | `StorageService.swift:220-228` | `chat_*.jpg` files accumulate indefinitely |
| MEM-H9 | Debug logging exposes sensitive AI reasoning | `GeminiService.swift:178-180, 258-260` | Vibe analysis, behavioral assessments in console |

### 10.4 Medium Severity Findings

| # | Finding | File |
|---|---------|------|
| MEM-M1 | In-memory messages cache has no eviction (grows as user browses history) | `StorageService.swift:33` |
| MEM-M2 | Conversations list grows without bounds in single UserDefaults key | `StorageService.swift:160-243` |
| MEM-M3 | Every API call re-sends ALL user facts in system prompt | `GeminiService.swift:116-118` |
| MEM-M4 | System prompt grows unboundedly via dynamic injection | `ChatViewModel.swift:201-256` |
| MEM-M5 | No token estimation or budget system for prompt construction | Entire codebase |
| MEM-M6 | 2-3 separate API calls per user message (Router + Strategist + Analyst) | `ChatViewModel.swift:157-311` |
| MEM-M7 | API responses not validated/sanitized before display to user | `ChatBubble.swift:30` |
| MEM-M8 | No input sanitization beyond 10K char length check | `ChatViewModel.swift:98-100` |
| MEM-M9 | Analyst results update multiple storage locations non-atomically | `ChatViewModel.swift:465-504` |
| MEM-M10 | Concurrent read-modify-write in SyncDataService compound operations | `SyncDataService.swift:561-599` |
| MEM-M11 | Message options lost during cloud sync round-trip | `SupabaseDataService.swift:329` |
| MEM-M12 | No disk space checking before file writes | `StorageService.swift:90-114` |
| MEM-M13 | Vision images not cleaned on `clearAll()` / sign-out | `StorageService.swift:652-671` |
| MEM-M14 | Silent decode failures throughout StorageService (no logging) | `StorageService.swift` (all load methods) |
| MEM-M15 | No version migration strategy for Codable models | All model files |
| MEM-M16 | Data export loads ALL data into memory simultaneously | `SettingsView.swift:592-621` |
| MEM-M17 | All journal entries stored in one UserDefaults blob | `StorageService.swift` |
| MEM-M18 | InternalThought data stored alongside messages and synced to cloud | `ChatViewModel.swift:271-279` |
| MEM-M19 | Insight queue has no size cap | `StorageService.swift:524-536` |
| MEM-M20 | Analysis triggers on app exit may be lost (async after counter reset) | `ChatViewModel.swift:516-522` |

### 10.5 Low Severity Findings

| # | Finding | File |
|---|---------|------|
| MEM-L1 | No conversation summarization for context compression | Entire codebase |
| MEM-L2 | Vibe mode selection is non-deterministic (randomized) | `Prompts.swift:633-643` |
| MEM-L3 | `@AppStorage` keys scattered across files (not centralized) | `ChloeApp.swift`, `SettingsView.swift` |
| MEM-L4 | `clearAll()` skips Documents directory files | `StorageService.swift:652-671` |
| MEM-L5 | No truncation on LLM-generated strings stored in UserDefaults | `StorageService.swift` |
| MEM-L6 | Silent no-op save when `conversationId` is nil | `ChatViewModel.swift:407-409` |
| MEM-L7 | Router call may be unnecessary for trivial messages | `ChatViewModel.swift:171-175` |

### 10.6 Positive Findings

- Router, Strategist, and Analyst are stateless — clean separation, single source of truth in StorageService
- First-time user with no data handled gracefully (sensible defaults everywhere)
- Memory warning handler exists — clears caches and URL cache on `didReceiveMemoryWarning`
- Behavioral loops capped at 20 entries in `SyncDataService`
- Insight queue has deduplication and 14-day expiry
- Chat images use efficient `ImageIO` downsampling (2048px max, 0.7 JPEG quality)
- 10,000 character input length limit
- Router models have robust flexible decoding with custom `init(from decoder:)`
- Conversation history capped at 20 messages for Strategist API calls

### 10.7 Priority Recommendations

1. **[Critical]** Migrate from UserDefaults to SwiftData/SQLite for messages, conversations, journal entries
2. **[Critical]** Cap user facts at 50-100 entries with relevance-based pruning or expiry
3. **[High]** Add schema versioning and migration logic for stored data
4. **[High]** Log decode failures instead of silently returning empty arrays — never overwrite on decode error
5. **[High]** Truncate messages sent to Analyst using same `MAX_CONVERSATION_HISTORY` cap
6. **[High]** Clean up orphaned chat images when conversations are deleted
7. **[High]** Sanitize AI-generated data (facts, loops) before injecting into system prompts — strip XML/HTML tags
8. **[Medium]** Implement LRU eviction for `messagesCache` dictionary
9. **[Medium]** Add token estimation before API calls to detect oversized prompts
10. **[Medium]** Implement Gemini prompt caching for static system prompt portions
11. **[Medium]** Add output sanitization — filter internal reasoning from fallback responses
12. **[Medium]** Delete Documents directory files (images) in `clearAll()` on sign-out

---

## Updated Findings Summary

| Audit Section | Total | Critical | High | Medium | Low |
|---------------|-------|----------|------|--------|-----|
| Security & Error Handling (original) | 32 | 4 | 10 | 12 | 6 |
| Code Quality & Architecture (original) | 84 | 6 | 27 | 33 | 18 |
| Performance & Bloat (original) | 24 | 0 | 2 | 12 | 10 |
| Dead Code & Duplication (original) | 25+ | 1 | 6 | 10 | 8 |
| Testing & Documentation (original) | 20+ | 3 | 5 | 8 | 4 |
| Git History | 5 | 0 | 0 | 1 | 4 |
| **API & Network Layer** | **42** | **1** | **11** | **20** | **10** |
| **AI Memory System** | **39** | **3** | **9** | **20** | **7** |
| **Grand Total** | **271+** | **18** | **70** | **116** | **67** |

---

*Report generated by 5-agent codebase audit + dependency audit + git history audit + 4-agent API/network audit + 3-agent AI memory system audit*
*ChloeApp v1.0 Build 2 — February 7-8, 2026*
