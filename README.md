# CatOnboardingScreens

Standalone Swift Package reproducing the **interactive onboarding flow** from the production CatScan iOS app, with Firebase / Adapty / persistence stripped out so design changes can iterate without touching the real app.

## What's in here

The full 6-question hybrid onboarding funnel + demo scan + paywall bridge — exactly as ships in the app.

### Screen flow (in order)

```
Welcome
  → Q1  Passion for cats          (affinity, non-scoring)
  → Q2  You and your cat          (emotional, non-scoring)
  → Q3  What you want to know     (emotional, non-scoring)
  → Community feed teaser
  → Cat game  (tap to wake the cat — interactive)
  → Q4  The eyes                  (physical, scored)
  → Q5  The posture               (physical, scored)
  → Q6  Where they look           (physical, scored)
  → Scanner reveal  (5.2s animation → trait meters + verdict)
  → Name save
  → Recap  (your answers + result)
  → Bridge → paywall handoff
```

### Files

- `CatOnboardingScreensDemo.swift` — entry point with a screen picker (each screen individually + the full interactive flow) and an EN/ES toggle in the nav bar
- `Onboarding/InteractiveOnboardingView.swift` — flow controller / routing
- `Onboarding/OnboardingScreens.swift` — Welcome, Question, NameSave, Feed screens
- `Onboarding/OnboardingTransitionScreen.swift` — the **tap-to-wake cat game** (pure SwiftUI shapes: sleeping cat → tap → wakes with particles)
- `Onboarding/OnboardingScannerView.swift` — 5.2s scan reveal with meter cards + verdict
- `Onboarding/OnboardingRecapScreen.swift` — recap of user's answers before paywall
- `Onboarding/OnboardingBridgeScreen.swift` — handoff to paywall ("now with a photo")
- `Onboarding/OnboardingData.swift` — 6 questions + 6 traits + scoring engine + **all EN/ES copy**
- `Onboarding/OnboardingComponents.swift` — `TopProgressBar`, `OptionCard`, `PrimaryGradientButton`, `OnboardingTopBar`
- `Onboarding/OnboardingTypography.swift` — the 7-role type scale (see below)
- `Onboarding/OnboardingAnalytics.swift` — funnel events (no-op when FirebaseAnalytics isn't linked)
- `Onboarding/OnboardingResultStore.swift` — local result persistence
- `Onboarding/OnboardingHaptics.swift` — named haptic vocabulary
- `Theme/Colors.swift` — every brand / trait / gradient token
- `Theme/Components.swift` — `Eyebrow`, `PrimaryCTA`, `GhostCTA`, `GlowCard`, etc.
- `FontLoader.swift` — registers bundled Nunito fonts with CoreText
- `Stubs.swift` — minimal stand-ins for `AppConstants` and the `L(...)` helper
- `Resources/Fonts/` — Nunito Black / Bold / Medium / Regular (TTF, bundled)

## Design system — color palette

All defined in `Theme/Colors.swift`. Dark theme throughout (background is near-black).

### Brand
| Token | Hex | Use |
|---|---|---|
| `brandPurple` | `#6B47FF` | Primary brand purple (CTAs, gradients) |
| `brandPurpleSoft` | `#9483FF` | Softer lavender — the **unified onboarding accent** (eyebrows, progress bar, selected option, cat game) |
| `brandBlue` | `#2473FF` | Gradient partner for purple |
| `brandCyan` | `#61D1FF` | Cool accent / highlights |
| `brandPink` | `#FF5FA0` | Warm accent (cat cheeks, hearts) |
| `brandBg` | `#0A0A0F` | App background (near-black) |
| `brandSurface` | `#141419` | Cards / surfaces |
| `brandBorder` | `#1F1F2A` | Hairline borders |

### Trait colors (6 cat personalities — used in the scan reveal)
| Trait | Hex | Emoji |
|---|---|---|
| Love | `#FF8FAD` | 💕 |
| Manipulation | `#7C3AED` | 🎭 |
| Coldness | `#61D1FF` | 🧊 |
| Sass | `#FF4D8F` | 💅 |
| Curiosity | `#66D98C` | 🔍 |
| Chaos | `#FF8C33` | 😈 |

### Text (white at opacity, on the dark background)
| Token | Opacity |
|---|---|
| `textPrimary` | 100% |
| `textSecondary` | 78% |
| `textTertiary` | 56% |
| `textDisabled` | 42% |
| `textSubtle` | 38% |

### Gradients
- **Brand** — `brandPurple → brandBlue` (top-leading → bottom-trailing) — used on primary CTAs.
- **Brand secondary** — `brandCyan → brandPurple` (leading → trailing).

## Typography

Custom font: **Nunito** (Black / Bold / Medium / Regular, bundled). 7-role scale in `OnboardingTypography.swift`:

| Role | Size / weight | Use |
|---|---|---|
| `display` | 28pt Black | Page hero titles |
| `title` | 22pt Black | Within-page headlines |
| `subtitle` | 16pt Medium | Descriptive intro paragraph |
| `optionLabel` | 17pt Black | A/B/C/D option card label |
| `hint` | 14pt Medium | Helper text under options |
| `eyebrow` | 14pt Black | Section labels / counters (uppercased, tracked) |
| `micro` | 12pt Black | Tiny chips, language toggle, tags |

## Bilingual — Spanish & English

The whole onboarding ships in **both Spanish (`es`) and English (`en`)**.

- Language is an `OnboardingLang` enum (`.es` / `.en`); it defaults to `Locale.current` on the device.
- Every string is inlined as a ternary `lang == .es ? "…" : "…"` (the question/option/verdict copy lives in `OnboardingData.swift`; screen copy lives in each screen file).
- The demo has an **EN / ES toggle** in the top-right of the nav bar — flip it live to see both languages.
- **When redesigning, keep both languages.** Spanish strings are usually ~15–20% longer than English, so layouts must tolerate longer text (titles wrap to 2–3 lines).

## What's interactive (don't lose these in a redesign)

- **Cat game** (transition screen): a sleeping cat (SwiftUI shapes) that the user **taps to wake** — ears spring up, eyes open, hearts/sparkles burst, copy changes. The "Start the scan" CTA is **disabled until the cat is tapped**.
- **Questions**: the Continue button is disabled until an option is selected (no skip — the onboarding requires engagement).
- **Scanner reveal**: 5.2s scan-line animation, then trait meter cards count up + a verdict card.

## What's stripped

- **No Firebase**. Analytics calls fall back to `print` in DEBUG; result-store key falls back to `"anon"` slot.
- **No Adapty / paywall**. The Bridge screen's CTA just calls its `onContinue` closure.
- **No AI scan engine**. The 5.2s "scan reveal" runs on a SwiftUI animation timer with a deterministic result computed from the user's answers.
- **No camera / PhotosPicker**. The onboarding never asks for a photo; the real scan happens after the paywall in the production app.
- **No usage / streak gating**. The store records the result but nothing reads from it inside the package.
- **No `ScanTraitType` from the main scanner module** — `TraitBadge` and `Color.traitColor(for:)` helpers were dropped because nothing in the onboarding actually used them.

## How to run

### Option A — Xcode preview (zero setup)

```bash
open /Users/usuario/CatOnboardingScreens/Package.swift
```

Open `Sources/CatOnboardingScreens/CatOnboardingScreensDemo.swift`, hit the canvas preview. The Nunito fonts auto-register so type renders correctly even in previews. From the picker you can open any single screen or run the full interactive flow.

### Option B — drop into your own iOS app

```swift
import CatOnboardingScreens
import SwiftUI

@main
struct DemoApp: App {
    var body: some Scene {
        WindowGroup {
            CatOnboardingScreensDemo()
        }
    }
}
```

Minimum target: iOS 17.

### Option C — quick build check from the CLI

```bash
cd /Users/usuario/CatOnboardingScreens
swift build
```

Builds on macOS host (no actual iPhone needed). Haptics and `UIImage`-based asset lookups are guarded with `#if canImport(UIKit)` so the package compiles cleanly on macOS too.

## Faithfulness to the production build

The screens are **byte-identical** to what ships, with only the dependencies stripped:

- Same 5.2s scanner duration (`scanDuration: 5.2` — sacred, do not change)
- Same trait scoring formula (`OnboardingScoring.compute` — emotional Qs use empty weights so they don't bias the result)
- Same brand colors, gradients, typography, animation curves
- Same haptic vocabulary (optionSelected → light, primaryTapped → medium, bridgeLaunch → heavy, etc.)
- No skip path — the production app requires the user to engage with every step (each question's Continue enables only after an answer)

## Limitations

- **Analytics fire to `print`**, not to a real funnel. Wire `OnboardingAnalytics` to whatever logger your design tooling uses if needed.
- **Result persistence** writes to UserDefaults under `catscan.onboarding.result.v1.anon` (no Firebase Auth). Clear with `OnboardingResultStore.shared.clear()` between previews if it gets stale.
- **`hasCompletedOnboarding` binding** in `InteractiveOnboardingView` is just a `@State` boolean in the demo — flipping it dismisses the screen wrapper.
- **Localization** is hardcoded EN/ES via `OnboardingLang`. Change the language with the toolbar toggle in the demo nav bar.
