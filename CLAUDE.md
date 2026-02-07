# ChloeApp — iOS Native Project

## Project Overview
Chloe in Your Pocket — a native iOS app built with Swift/SwiftUI.
This is strictly an iOS app. No web app work until explicitly requested.

## Tech Stack (iOS Only)
- **Language:** Swift 5
- **UI Framework:** SwiftUI (iOS 17+ deployment target)
- **Architecture:** MVVM (Model-View-ViewModel)
- **Persistence:** SwiftData / UserDefaults (native — no Realm)
- **Networking:** URLSession + async/await (native — no Alamofire)
- **AI API:** Gemini (direct REST calls, or Google Generative AI Swift SDK)
- **Package Manager:** Swift Package Manager (SPM primary)
- **Haptics:** Native `.sensoryFeedback()` (no pods)
- **Keyboard:** Native SwiftUI handling (no IQKeyboardManager)
- **Animations:** Native SwiftUI (Canvas, TimelineView)
- **Chat UI:** Custom-built (SwiftUI)
- **Celebrations:** ConfettiSwiftUI (SPM)
- **Markdown:** MarkdownUI (SPM)
- **Analytics:** TelemetryDeck (SPM)

## Key Rules
- **iOS ONLY.** Do not reference, modify, or suggest anything related to the Expo/React Native web app (`chloe-in-your-pocket/`). The web app is completely ignored until the user explicitly says "let's move to the web app."
- **Native first.** Always prefer native iOS/SwiftUI solutions over third-party libraries. Only add a dependency when native APIs genuinely can't do the job.
- **SwiftUI idioms.** Use `@StateObject`, `@ObservedObject`, `@EnvironmentObject`, `@State`, `@Binding`, `@Query` (SwiftData). No UIKit unless absolutely necessary.
- **Build verification.** After significant changes, build with: `xcodebuild -project ChloeApp.xcodeproj -scheme ChloeApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet build`
- **No CocoaPods.** Use Swift Package Manager for all dependencies.
- **API keys in xcconfig.** Never hardcode secrets. Use `Config.xcconfig` → `Info.plist` → `Bundle.main.infoDictionary`.

## Project Structure
```
/Users/secondary/ChloeApp/
├── ChloeApp.xcodeproj
├── ChloeApp/
│   ├── ChloeApp.swift          (App entry point)
│   ├── Info.plist
│   ├── Config.xcconfig         (API keys)
│   ├── Assets.xcassets/
│   ├── Models/                 (Codable structs)
│   ├── Views/
│   │   ├── App/               (ContentView — root routing)
│   │   ├── Auth/              (Email login)
│   │   ├── Onboarding/        (4-step onboarding flow: Welcome → Name → Archetype Quiz → Complete)
│   │   ├── Main/              (Sanctuary, Journal, History, VisionBoard, Goals, Affirmations, Settings, etc.)
│   │   └── Components/        (Reusable UI components)
│   ├── ViewModels/            (ObservableObject VMs)
│   ├── Services/              (Gemini, Storage, Safety, etc.)
│   ├── Theme/                 (Colors, Fonts, Spacing)
│   ├── Constants/             (Prompts, Crisis responses)
│   ├── Resources/Fonts/       (Custom .ttf files)
│   └── Extensions/            (Color+Theme, Date, String)
```

## SPM Dependencies (already added)
- ConfettiSwiftUI 1.1.0
- MarkdownUI 2.4.1
- TelemetryDeck 2.11.0
