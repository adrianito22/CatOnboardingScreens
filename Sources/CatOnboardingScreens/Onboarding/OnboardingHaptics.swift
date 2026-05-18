// OnboardingHaptics.swift
// CatScan — InteractiveOnboarding
//
// Named haptic vocabulary for the onboarding. Each case maps to one of
// UIKit's feedback generators with intensities chosen to MATCH what
// CatScannerView already does — so the user's body never feels a jarring
// difference when they transition from the demo into the real scanner.

#if canImport(UIKit)
import UIKit
#endif

enum OnboardingHaptics {
    /// Tap on an answer card. Light, like a chip selection.
    case optionSelected
    /// Tap on a primary gradient button (Continue, Start scan, Save profile).
    case primaryTapped
    /// Tap on a secondary / ghost pill (Skip, Maybe later).
    case secondaryTapped
    /// The scan animation reaches 100% (success notification).
    case scanCompleted
    /// Tap on the bridge CTA "Try a real scan" — heavier, signals a leap.
    case bridgeLaunch
    /// Language toggle. Subtle selection feedback.
    case languageToggled

    func fire() {
        #if canImport(UIKit) && !os(macOS) && !os(watchOS) && !os(tvOS)
        switch self {
        case .optionSelected:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .primaryTapped:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .secondaryTapped:
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        case .scanCompleted:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .bridgeLaunch:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .languageToggled:
            UISelectionFeedbackGenerator().selectionChanged()
        }
        #endif
    }
}
