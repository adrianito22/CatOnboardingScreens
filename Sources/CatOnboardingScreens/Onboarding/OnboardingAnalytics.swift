// OnboardingAnalytics.swift
// CatScan — InteractiveOnboarding
//
// Funnel telemetry for the demo-scan onboarding. Events follow
// `onboarding_<verb>` naming so they group cleanly in Firebase Analytics.
// All calls are no-ops in DEBUG (with a `print` for sanity) when Firebase
// Analytics isn't linked.
//
// The set:
//   onboarding_started
//   onboarding_step_viewed          step=welcome|question_1..5|scanner|name_save|feed|bridge
//   onboarding_question_answered    q_index, option_index, lang
//   onboarding_skipped              at=welcome|question|feed
//   onboarding_language_changed     to, on=<step>
//   onboarding_scan_complete        dominant_trait, confidence
//   onboarding_profile_saved        has_name, age_index, dominant_trait
//   onboarding_bridge_cta_tapped    dominant_trait
//   onboarding_completed            duration_s, dominant_trait
//
// On completion we also set the user property `onboarding_dominant_trait`
// so every downstream event can be segmented by personality archetype.

import Foundation

#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif

enum OnboardingAnalytics {
    enum SkipPoint: String { case welcome, question, feed }

    static func started(lang: OnboardingLang) {
        OnboardingTimer.shared.start()
        log("onboarding_started", ["lang": lang.rawValue])
    }

    static func stepViewed(_ step: String, lang: OnboardingLang) {
        log("onboarding_step_viewed", ["step": step, "lang": lang.rawValue])
    }

    static func questionAnswered(qIndex: Int, optionIndex: Int, lang: OnboardingLang) {
        log("onboarding_question_answered", [
            "q_index": qIndex,
            "option_index": optionIndex,
            "lang": lang.rawValue
        ])
    }

    static func skipped(at point: SkipPoint, lang: OnboardingLang) {
        log("onboarding_skipped", ["at": point.rawValue, "lang": lang.rawValue])
    }

    static func languageChanged(to lang: OnboardingLang, on step: String) {
        log("onboarding_language_changed", ["to": lang.rawValue, "on": step])
    }

    static func scanComplete(dominant: String, confidence: Int, lang: OnboardingLang) {
        log("onboarding_scan_complete", [
            "dominant_trait": dominant,
            "confidence": confidence,
            "lang": lang.rawValue
        ])
    }

    static func profileSaved(hasName: Bool, ageIndex: Int, dominant: String, lang: OnboardingLang) {
        log("onboarding_profile_saved", [
            "has_name": hasName,
            "age_index": ageIndex,
            "dominant_trait": dominant,
            "lang": lang.rawValue
        ])
    }

    static func bridgeCTATapped(dominant: String, lang: OnboardingLang) {
        log("onboarding_bridge_cta_tapped", [
            "dominant_trait": dominant,
            "lang": lang.rawValue
        ])
    }

    static func completed(dominant: String, lang: OnboardingLang) {
        let secs = OnboardingTimer.shared.stop()
        log("onboarding_completed", [
            "duration_s": secs,
            "dominant_trait": dominant,
            "lang": lang.rawValue
        ])
        // BONUS: stamp the user with their dominant trait so future events
        // (paywall, retention, scan usage) can be segmented by archetype —
        // e.g. "Chaos cats convert at X% vs Love cats at Y%".
        setUserProperty("onboarding_dominant_trait", value: dominant)
    }

    // MARK: - Plumbing

    private static func log(_ name: String, _ params: [String: Any]) {
        #if canImport(FirebaseAnalytics)
        Analytics.logEvent(name, parameters: params)
        #endif
        #if DEBUG
        print("[OnboardingAnalytics] \(name) \(params)")
        #endif
    }

    private static func setUserProperty(_ name: String, value: String) {
        #if canImport(FirebaseAnalytics)
        Analytics.setUserProperty(value, forName: name)
        #endif
        #if DEBUG
        print("[OnboardingAnalytics] userProperty \(name)=\(value)")
        #endif
    }
}

/// Measures total onboarding duration (start → completed). Single shared
/// instance because there is exactly one onboarding flow at a time and we
/// want the timer to survive view re-mounts.
final class OnboardingTimer {
    static let shared = OnboardingTimer()
    private var startedAt: Date?

    private init() {}

    func start() {
        // Only start the first time — avoid resetting if the user toggles
        // language or scrolls and SwiftUI re-fires onAppear.
        if startedAt == nil { startedAt = Date() }
    }

    @discardableResult
    func stop() -> Int {
        guard let t = startedAt else { return 0 }
        let elapsed = Int(Date().timeIntervalSince(t).rounded())
        startedAt = nil
        return elapsed
    }
}
