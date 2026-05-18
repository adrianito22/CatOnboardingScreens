# CatOnboardingScreens

Standalone Swift Package reproducing the **interactive onboarding flow** from the production CatScan iOS app, with Firebase / Adapty / persistence stripped out so design changes can iterate without touching the real app.

## What's in here

The full 6-question hybrid onboarding funnel + demo scan + paywall bridge — exactly as ships in the app:

- `CatOnboardingScreensDemo.swift` — entry point with a screen picker (each of the 9 screens individually + the full interactive flow)
- `Onboarding/InteractiveOnboardingView.swift` — flow controller (Welcome → Q1..Q6 → Transition → Scanner → NameSave → Feed → Recap → Bridge)
- `Onboarding/OnboardingScreens.swift` — Welcome, Question, NameSave, Feed screens
- `Onboarding/OnboardingTransitionScreen.swift` — bridges emotional Qs into physical Qs
- `Onboarding/OnboardingScannerView.swift` — 5.2s scan reveal with meter cards + verdict
- `Onboarding/OnboardingRecapScreen.swift` — recap of user's answers before paywall
- `Onboarding/OnboardingBridgeScreen.swift` — handoff to paywall ("now try with a real photo")
- `Onboarding/OnboardingData.swift` — 6 questions (1 affinity + 2 emotional + 3 physical), 6 traits, scoring engine
- `Onboarding/OnboardingComponents.swift` — `TopProgressBar`, `OptionCard`, `PrimaryGradientButton`, `OnboardingTopBar`
- `Onboarding/OnboardingAnalytics.swift` — funnel events (no-op when FirebaseAnalytics isn't linked, prints in DEBUG)
- `Onboarding/OnboardingResultStore.swift` — local result persistence (UserDefaults, anon UID slot)
- `Onboarding/OnboardingHaptics.swift` — named haptic vocabulary
- `Theme/Colors.swift` — every brand / trait / streak / gradient token
- `Theme/Components.swift` — `Eyebrow`, `PrimaryCTA`, `GhostCTA`, `GlowCard`, etc.
- `FontLoader.swift` — registers bundled Nunito fonts with CoreText
- `Stubs.swift` — minimal stand-ins for `AppConstants` and the `L(...)` localization helper
- `Resources/Fonts/` — Nunito Black / Bold / Medium / Regular (TTF, bundled)

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
- Same skip behavior (`fillUnansweredRandomly` — random unanswered, no bias to option 0)

## Limitations

- **Analytics fire to `print`**, not to a real funnel. Wire `OnboardingAnalytics` to whatever logger your design tooling uses if needed.
- **Result persistence** writes to UserDefaults under `catscan.onboarding.result.v1.anon` (no Firebase Auth). Clear with `OnboardingResultStore.shared.clear()` between previews if it gets stale.
- **`hasCompletedOnboarding` binding** in `InteractiveOnboardingView` is just a `@State` boolean in the demo — flipping it dismisses the screen wrapper.
- **Localization** is hardcoded EN/ES via `OnboardingLang`. Change the language with the toolbar toggle in the demo nav bar.
