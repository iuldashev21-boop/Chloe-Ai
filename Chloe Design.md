# Chloe Design System

## Celestial Design v1.0 (LOCKED)

Complete reference for every font, colour, spacing, shadow, animation, and component used in ChloeApp.

---

## 1. Custom Font Files

| Font File | PostScript Name | Used As |
|-----------|----------------|---------|
| Cinzel-Regular.ttf | `Cinzel-Regular` | CTA buttons, sidebar section headers |
| CormorantGaramond-BoldItalic.ttf | `CormorantGaramond-BoldItalic` | Hero greetings, onboarding questions |
| TenorSans-Regular.ttf | `TenorSans-Regular` | Sidebar logo text |

### Font Constants (ChloeFont enum)

```swift
ChloeFont.heroBoldItalic  = "CormorantGaramond-BoldItalic"
ChloeFont.headerDisplay   = "Cinzel-Regular"
```

---

## 2. Font Definitions

### Static Fonts

| Token | Family | Size | Weight | Used For |
|-------|--------|------|--------|----------|
| `.chloeLargeTitle` | SF Pro | 28 | medium | Large screen titles |
| `.chloeTitle` | SF Pro | 22 | medium | Screen titles (Settings, etc.) |
| `.chloeTitle2` | SF Pro | 20 | regular | Secondary titles |
| `.chloeHeadline` | SF Pro | 17 | medium | Section headings |
| `.chloeSubheadline` | SF Pro | 15 | medium | Card titles, subheadings |
| `.chloeBodyDefault` | SF Pro | 17 | regular | Default body text |
| `.chloeBodyLight` | SF Pro | 17 | light | Login subtitle, completion body |
| `.chloeCaption` | SF Pro | 14 | regular | Small labels, metadata |
| `.chloeCaptionLight` | SF Pro | 14 | light | Onboarding card descriptions |
| `.chloeButton` | Cinzel-Regular | 15 | — | All CTA buttons |
| `.chloeGreeting` | CormorantGaramond-BoldItalic | 38 | — | Hero greetings, "Welcome back", "You're all set!" |
| `.chloeOnboardingQuestion` | CormorantGaramond-BoldItalic | 34 | — | Onboarding question text |
| `.chloeStatus` | Cinzel-Regular | 11 | — | Status labels |
| `.chloeProgressLabel` | SF Pro | 11 | light | Progress indicators |
| `.chloeSidebarSectionHeader` | Cinzel-Regular | 12 | — | Sidebar section headers |
| `.chloeSidebarMenuItem` | SF Pro | 15 | regular | Sidebar menu items |
| `.chloeSidebarChatItem` | SF Pro | 14 | regular | Sidebar chat history items |

### Dynamic Font Functions

| Function | Family | Weight | Usage |
|----------|--------|--------|-------|
| `.chloeHeading(_ size:)` | SF Pro | regular | Generic heading at custom size |
| `.chloeHeadingMedium(_ size:)` | SF Pro | medium | Medium heading at custom size |
| `.chloeBody(_ size:)` | SF Pro | regular | Body text at custom size |
| `.chloeBodyMedium(_ size:)` | SF Pro | medium | Medium body at custom size |
| `.chloeInputPlaceholder(_ size:)` | SF Pro | regular | Input placeholder text |

---

## 3. Typography Style Modifiers

| Modifier | Font | Tracking | Extra |
|----------|------|----------|-------|
| `.chloeHeroStyle()` | `.chloeGreeting` (Cormorant 38pt) | -0.68 (34 * -0.02) | — |
| `.chloeSecondaryHeaderStyle()` | `.chloeSidebarSectionHeader` (Cinzel 12pt) | 3 | `.uppercase` |
| `.chloeBodyStyle()` | `.chloeBodyDefault` (17pt) | — | lineSpacing: 8.5 |
| `.chloeCaptionStyle()` | `.chloeCaption` (14pt) | — | lineSpacing: 7 |
| `.chloeButtonTextStyle()` | `.chloeButton` (Cinzel 15pt) | 3 | — |

---

## 4. Tracking (Letter Spacing) Values

| Value | Where Used |
|-------|------------|
| `-0.68` (34 * -0.02) | ChloeHeroStyle (font is 38pt; tracking calc uses 34) |
| `0.78` (26 * 0.03) | WelcomeIntroView greeting |
| `1.08` (36 * 0.03) | SanctuaryView greeting |
| `2` | SidebarView heading, SettingsView section headers |
| `3` | All CTA buttons, ChloeButtonLabel, ChloeSecondaryHeaderStyle, SIGN IN, SIGN OUT |

---

## 5. Colours

### Core Palette

| Token | Hex | RGB | Usage |
|-------|-----|-----|-------|
| `.chloeBackground` | `#FFF8F0` | 255, 248, 240 | App background (cream) |
| `.chloeSurface` | `#FAFAFA` | 250, 250, 250 | Card surfaces |
| `.chloePrimary` | `#B76E79` | 183, 110, 121 | Rose Gold — buttons, accents, brand |
| `.chloePrimaryLight` | `#FFF0EB` | 255, 240, 235 | Light rose — selected card bg, AI bubbles |
| `.chloePrimaryDark` | `#8A4A55` | 138, 74, 85 | Dark rose |
| `.chloeAccent` | `#F4A896` | 244, 168, 150 | Peachy rose — gradient end, highlights |
| `.chloeAccentMuted` | `#E8B4A8` | 232, 180, 168 | Muted peach |
| `.chloeTextPrimary` | `#2D2324` | 45, 35, 36 | Primary text (near-black brown) |
| `.chloeTextSecondary` | `#6B6B6B` | 107, 107, 107 | Secondary text (medium gray) |
| `.chloeTextTertiary` | `#9A9A9A` | 154, 154, 154 | Tertiary text (light gray) |
| `.chloeBorder` | `#E5E5E5` | 229, 229, 229 | Standard border |
| `.chloeBorderWarm` | `#F0E0DA` | 240, 224, 218 | Warm border — inputs, cards |
| `.chloeUserBubble` | `#F0F0F0` | 240, 240, 240 | User chat bubble background |
| `.chloeGradientStart` | `#FFF8F5` | 255, 248, 245 | Background gradient start |
| `.chloeGradientEnd` | `#FEEAE2` | 254, 234, 226 | Background gradient end |
| `.chloeRosewood` | `#8E5A5E` | 142, 90, 94 | Muted rose — shadows, dividers, "or" text |
| `.chloeEtherealGold` | `#F3E5AB` | 243, 229, 171 | Gold — orb core, particles |

### Gradients

**LinearGradient.chloeHeadingGradient**
- Colours: `.chloePrimary` → `.chloeAccent`
- Direction: horizontal (leading → trailing)
- Usage: hero text, headings

**GradientBackground (full-screen)**
- Colours: `.chloeGradientStart` → `.chloeGradientEnd`
- Direction: responsive (vertical portrait, horizontal landscape)

**LuminousOrb radial gradient (5 stops)**
1. `chloeEtherealGold` 100% @ 0.0
2. `chloeEtherealGold` 90% @ 0.25
3. `chloeEtherealGold` 60% @ 0.45
4. `chloePrimary` 80% @ 0.70
5. `chloePrimary` 40% @ 1.0

**LuminousOrb outer glow**
- `chloePrimary` 25% → `chloePrimary` 0% (radial)
- Radius: size * 0.25 → size * 0.6
- Blur: size * 0.15
- Scale: size * 1.4

---

## 6. Spacing Scale

| Token | Value (pt) |
|-------|-----------|
| `Spacing.xxxs` | 4 |
| `Spacing.xxs` | 8 (base unit) |
| `Spacing.xs` | 12 |
| `Spacing.sm` | 16 |
| `Spacing.md` | 20 |
| `Spacing.lg` | 24 |
| `Spacing.xl` | 32 |
| `Spacing.xxl` | 40 |
| `Spacing.xxxl` | 48 |
| `Spacing.huge` | 64 |

### Layout Constants

| Token | Value | Usage |
|-------|-------|-------|
| `Spacing.screenHorizontal` | 20 pt | Standard horizontal padding |
| `Spacing.cardPadding` | 16 pt | Card internal padding |
| `Spacing.cornerRadius` | 12 pt | Standard corner radius |
| `Spacing.cornerRadiusLarge` | 20 pt | Large corner radius |

### Orb Sizing

| Token | Value | Usage |
|-------|-------|-------|
| `Spacing.orbSize` | 80 pt | Default avatar orb |
| `Spacing.orbSizeSanctuary` | 120 pt | Sanctuary screen orb |
| `Spacing.sanctuaryOrbY` | 0.25 | Fraction of screen height |

---

## 7. Corner Radius Values

| Value | Where Used |
|-------|------------|
| 12 pt | Standard cards (`Spacing.cornerRadius`) |
| 20 pt | Large cards (`Spacing.cornerRadiusLarge`), VisionBoard |
| 28 pt | Inputs, BentoGridCard, capsule-like buttons |
| 32 pt | SanctuaryView sidebar open state |
| Capsule | ChloeButtonLabel, SIGN OUT, chips |

---

## 8. Shadow Definitions

| Component | Colour | Opacity | Radius | X | Y |
|-----------|--------|---------|--------|---|---|
| **ChloeButtonLabel** | black | 0.15 | 20 | 0 | 10 |
| **PressableButtonStyle (rest)** | chloePrimary | 0.30 | 8 | 0 | 4 |
| **PressableButtonStyle (pressed)** | chloePrimary | 0.15 | 4 | 0 | 2 |
| **SelectionCard (selected)** | chloePrimary | 0.15 | 10 | 0 | 3 |
| **SelectionCard (unselected)** | black | 0.04 | 4 | 0 | 2 |
| **BentoGridCard** | chloeRosewood | 0.12 | 16 | 0 | 6 |
| **SidebarView** | chloeRosewood | 0.15 | 8 | 2 | 0 |
| **PlusBloomMenu** | chloeRosewood | 0.12 | 8 | 0 | 3 |
| **AddVisionSheet** | black | 0.04 | 6 | 0 | 2 |
| **SettingsView SIGN OUT** | black | 0.15 | 20 | 0 | 10 |
| **SanctuaryView (sidebar open)** | black | 0.10 | 20 | 0 | 0 |
| **History/Journal/Goals cards** | chloeRosewood | 0.12 | 16 | 0 | 6 |

---

## 9. Opacity Reference

| Value | Usage |
|-------|-------|
| 0.03 | EtherealDustParticles (atmospheric) |
| 0.04 | Subtle card shadows |
| 0.06 | SidebarView background tint |
| 0.12 | Card shadows (BentoGridCard, History, Vision, etc.) |
| 0.15 | Button shadows, selected card shadows, rosewood tints |
| 0.2 | White border strokes, stardust particle opacity |
| 0.25 | LuminousOrb glow |
| 0.3 | Divider lines, border strokes, button shadow (rest) |
| 0.4 | Primary border strokes |
| 0.45 | Disabled button background, stardust particles |
| 0.5 | Red tint in dev settings |
| 0.6 | LuminousOrb gradient mid-stop |
| 0.7 | Disabled button pulse min |
| 0.75 | Unselected card opacity |
| 0.8 | Selected card description text, orb gradient |
| 0.9 | Orb gradient near-centre |
| 1.0 | Full opacity (default) |

---

## 10. Button Styles

### ChloeButtonLabel (Primary CTA)
- Font: Cinzel-Regular 15pt, ALL-CAPS, tracking 3
- Foreground: white
- Background: `.chloePrimary` (full / 0.45 disabled)
- Shape: Capsule
- Shadow: black 0.15, radius 20, y 10
- Disabled: pulsing opacity 1.0 ↔ 0.7 (1.5s easeInOut, forever)

### PressableButtonStyle
- Scale: 1.0 → 0.96 on press
- Shadow: chloePrimary 0.3/r8/y4 → 0.15/r4/y2 on press
- Animation: easeOut 0.15s

### SelectionCardModifier
- Background: `.chloePrimaryLight` (selected) / `.chloeSurface` (unselected)
- Scale: 1.02 (selected) / 1.0 (unselected)
- Opacity: 1.0 (selected) / 0.75 (unselected)
- Shadow: chloePrimary 0.15/r10/y3 (selected) / black 0.04/r4/y2 (unselected)
- Animation: spring response 0.35, damping 0.7

---

## 11. Reusable Components

### Layout

| Component | Description |
|-----------|-------------|
| **GradientBackground** | Full-screen gradient (chloeGradientStart → chloeGradientEnd) |
| **BentoGridCard** | Container card — cornerRadius 28, ultraThinMaterial, rosewood shadow |

### Buttons / Inputs

| Component | Description |
|-----------|-------------|
| **ChloeButtonLabel** | Primary CTA — Cinzel, uppercase, capsule, rose gold |
| **PressableButtonStyle** | Press feedback — scale + shadow shift |
| **OnboardingCard** | Card selector — title (15pt medium) + description (14pt light) |
| **ChatInputBar** | Text input with media buttons, capsule shape |

### Avatar / Orb

| Component | Description |
|-----------|-------------|
| **ChloeAvatar** | Profile pic — LuminousOrb (>=80pt) or chloe-logo (< 80pt) |
| **LuminousOrb** | Canvas-based breathing blob, radial gold → rose gradient |
| **OrbStardustEmitter** | 10 particles emitting from orb edge, 1.5s lifecycle |

### Particles

| Component | Count | Direction | Opacity | Blur |
|-----------|-------|-----------|---------|------|
| **EtherealDustParticles** | 12 | Lissajous curves | 0.03 | 4pt |

### Text Effects

| Component | Description |
|-----------|-------------|
| **BloomTextModifier** `.bloomReveal(trigger:)` | Left-to-right reveal, blur 20→0, mask-based, 1s |
| **ShimmerTextModifier** `.luminousBloom(trigger:)` | Shimmer sweep + scale 1.1→1.0 + blur entrance, ~1.1s |

### Chat

| Component | Description |
|-----------|-------------|
| **ChatBubble** | User: `chloeUserBubble`, AI: `chloePrimaryLight`, cornerRadius 12, font 17pt |
| **TypingIndicator** | 3 dots, 8pt, scale 1.0→0.5, staggered 0.2s, easeInOut 0.6s |
| **PlusBloomMenu** | 3-item radial menu, 44pt circles, 46pt radius, spring animated |

### Utility

| Component | Description |
|-----------|-------------|
| **DisclaimerText** | chloeCaption 14pt, textTertiary, centred |
| **CameraPickerView** | UIKit camera wrapper |

---

## 12. Animation Timing

### Canonical Spring
```swift
Spacing.chloeSpring = .spring(response: 0.45, dampingFraction: 0.8)
```
Used in: BloomTextModifier, general UI transitions

### All Spring Variants

| Response | Damping | Where |
|----------|---------|-------|
| 0.30 | 0.8 | PlusBloomMenu dismiss |
| 0.35 | 0.7 | SelectionCardModifier |
| 0.35 | 0.75 | PlusBloomMenu open/close |
| 0.45 | 0.8 | **Canonical** — most UI transitions |
| 0.50 | 0.85 | SanctuaryView main interactions |
| 0.70 | 0.8 | ShimmerTextModifier bloom |

### Easing Animations

| Duration | Easing | Where |
|----------|--------|-------|
| 0.15s | easeOut | PressableButtonStyle, WelcomeIntroView button |
| 0.2s | easeOut | OnboardingCard selection |
| 0.2s | easeInOut | AddVisionSheet toggles |
| 0.4s | easeInOut | OrbStardustEmitter |
| 0.6s | easeInOut | TypingIndicator dots (repeating) |
| 0.8s | easeInOut | ShimmerTextModifier sweep |
| 1.0s | easeOut | BloomTextModifier reveal |
| 1.5s | easeInOut | ChloeButtonLabel disabled pulse (repeating) |

---

## 13. Line Spacing

| Value | Where |
|-------|-------|
| 8.5 (17 * 0.5) | ChloeBodyStyle |
| 7 (14 * 0.5) | ChloeCaptionStyle |
| 8 | WelcomeIntroView |
| 6 | JournalDetailView |

---

## 14. Screen-by-Screen Font Map

### Login (EmailLoginView)
| Element | Font | Colour |
|---------|------|--------|
| "Welcome back" | `.chloeGreeting` (Cormorant 38pt) | `.chloeTextPrimary` |
| "Enter your email to continue" | `.chloeBodyLight` (17pt light) | `.chloeRosewood` |
| Email/Password placeholders | `.chloeBodyDefault` (17pt regular) | `.chloeRosewood` |
| SIGN IN button | Cinzel 15pt, tracking 3 | white |
| "Sign Up" link | `.chloeCaption` (14pt) | `.chloePrimary` |
| "or" divider | system 14pt light | `.chloeRosewood` |
| "Skip (Dev)" | system 14pt light | `.chloePrimary` |

### Onboarding Questions
| Element | Font | Colour |
|---------|------|--------|
| Question text | `.chloeOnboardingQuestion` (Cormorant 34pt) | `.chloeTextPrimary` |
| Card title | `.chloeSubheadline` (15pt medium) | `.chloePrimary` (selected) / `.chloeTextPrimary` |
| Card description | `.chloeCaptionLight` (14pt light) | `.chloePrimary` 0.8 (selected) / `.chloeTextSecondary` |
| Continue button | ChloeButtonLabel — Cinzel 15pt, tracking 3 | white |

### Completion (OnboardingCompleteView)
| Element | Font | Colour |
|---------|------|--------|
| "You're all set!" | `.chloeGreeting` (Cormorant 38pt) | `.chloePrimary` |
| Body text | `.chloeBodyLight` (17pt light) | `.chloeTextSecondary` |
| MEET CHLOE button | ChloeButtonLabel — Cinzel 15pt, tracking 3 | white |

### Sanctuary (SanctuaryView)
| Element | Font | Colour |
|---------|------|--------|
| Greeting | `.chloeGreeting` (Cormorant 38pt), tracking 1.08 | `.chloeTextPrimary` |
| Status label | `.chloeStatus` (Cinzel 11pt) | `.chloeTextTertiary` |
| Chat input | `.chloeBodyDefault` (17pt) | — |

### Sidebar (SidebarView)
| Element | Font | Colour |
|---------|------|--------|
| "Chloe" logo | TenorSans-Regular 12pt | `.chloeTextSecondary` |
| Section headers | `.chloeSidebarSectionHeader` (Cinzel 12pt), tracking 2 | `.chloeTextTertiary` |
| Menu items | `.chloeSidebarMenuItem` (15pt regular) | `.chloeTextPrimary` |
| Chat history items | `.chloeSidebarChatItem` (14pt regular) | `.chloeTextPrimary` |

### Settings (SettingsView)
| Element | Font | Colour |
|---------|------|--------|
| "Settings" title | `.chloeTitle` (22pt medium) | `.chloeTextPrimary` |
| Section headers | `.chloeSidebarSectionHeader` (Cinzel 12pt), tracking 2 | `.chloeTextTertiary` |
| Row labels | `.chloeBodyDefault` (17pt regular) | `.chloeTextPrimary` |
| Row values | `.chloeCaption` (14pt regular) | `.chloeTextSecondary` |
| SIGN OUT | `.chloeButton` (Cinzel 15pt), tracking 3 | white on `.chloeRosewood` |

### Journal / Goals / Vision Board / History
| Element | Font |
|---------|------|
| Screen titles | `.chloeTitle` (22pt medium) |
| Card titles | `.chloeHeadline` (17pt medium) |
| Card metadata | `.chloeCaption` (14pt regular) |
| Body text | `.chloeBodyDefault` (17pt regular) |

### Chat (ChatBubble)
| Element | Font | Colour |
|---------|------|--------|
| Message text | `.chloeBodyDefault` (17pt regular) | `.chloeTextPrimary` |
| Timestamp | `.chloeCaption` (14pt regular) | `.chloeTextTertiary` |

---

## 15. Blur Radius Reference

| Value | Where |
|-------|-------|
| 0.8 pt | OrbStardustEmitter |
| 4 pt | EtherealDustParticles |
| size * 0.15 | LuminousOrb outer glow |
| 20 pt | ShimmerTextModifier initial state |

---

## 16. Scale Effect Reference

| Value | Context |
|-------|---------|
| 0.3 → 1.0 | PlusBloomMenu item entrance |
| 0.5 | TypingIndicator dot pulse min |
| 0.9 | SanctuaryView sidebar-open content |
| 0.96 | PressableButtonStyle pressed |
| 1.0 | Default / rest state |
| 1.02 | SelectionCardModifier selected |
| 1.1 → 1.0 | ShimmerTextModifier entrance |
