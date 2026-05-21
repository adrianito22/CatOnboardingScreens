// InteractiveOnboardingView.swift
// CatScan — InteractiveOnboarding flow controller.
//
// New flow (post "demo scan" redesign):
//   Welcome → Q1..Q5 (eyes/ears/posture/activity/gaze) → Scanner (5.2s + reveal)
//          → NameSave → Feed teaser → Bridge → AdaptyPaywallView
//
// CHANGES VS LEGACY (see HANDOFF.md for the full list):
//   1. 5 demo-scan questions mapped to the cues the real AI reads in the photo.
//   2. Default language now derives from Locale.current.
//   3. Skip randomizes UNANSWERED answers (no longer biased to option 0).
//   4. Profile photo upload removed. Name + age live on NameSaveScreen
//      AFTER the reveal ("name this troublemaker to save the profile").
//   5. Feed teaser moved AFTER the reveal.
//   6. Step chip replaced by TopProgressBar (no UIScreen.main.bounds).
//   7. Reveal visuals (meter cards / verdict card / confidence pill) now mirror
//      CatScannerView exactly so the user feels the demo IS a scan.
//   8. New BridgeScreen between Feed and the paywall: "that was a scan
//      from memory — try a real scan." Sets up the paywall organically.
//      When the user taps "Try a real scan", onboarding completes and
//      ContentView takes over showing AdaptyPaywallView (separate top-level state).
//
// UNTOUCHED (per brief):
//   • 5.2s scanner animation (OnboardingScannerView).
//   • AdaptyPaywallView (presented by ContentView, not from here).
//   • Trait/verdict system.
//   • Voice.

import SwiftUI

private enum Step: Equatable {
    case welcome
    case question(Int)        // 0..5
    case transition
    case scanner
    case nameSave
    case feed
    case recap
    case bridge

    /// Stable string identifier used in funnel analytics.
    var analyticsName: String {
        switch self {
        case .welcome:           return "welcome"
        case .question(let i):   return "question_\(i + 1)"
        case .transition:        return "transition"
        case .scanner:           return "scanner"
        case .nameSave:          return "name_save"
        case .feed:              return "feed"
        case .recap:             return "recap"
        case .bridge:            return "bridge"
        }
    }
}

struct InteractiveOnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool

    @State private var lang: OnboardingLang = OnboardingLang.systemDefault
    @State private var step: Step = .welcome

    @State private var answers: [Int?] = Array(repeating: nil, count: OnboardingContent.questions(.en).count)
    @State private var name: String = ""
    /// nil until the user explicitly picks an age. No silent default.
    @State private var ageIndex: Int? = nil
    @State private var result: OnboardingResult?
    /// Stable fallback computed ONCE if we ever enter `.scanner` without `commit()`.
    /// Stored in @State so it doesn't re-randomize on each render (bug fix).
    @State private var fallbackResult: OnboardingResult?

    private var questions: [OnboardingQuestion] {
        OnboardingContent.questions(lang)
    }

    /// Single, stable source of truth for the result during render.
    /// Never calls `fallback()` inline — that would re-randomize per render.
    private var committedResult: OnboardingResult {
        result ?? fallbackResult ?? OnboardingScoring.compute(
            questions: questions, answers: answers, lang: lang)
    }

    var body: some View {
        ZStack {
            OnboardingColors.bg.ignoresSafeArea()

            Group {
                switch step {
                case .welcome:
                    OnboardingWelcomeScreen(
                        lang: $lang,
                        onStart: { step = .question(0) }
                    )
                case .transition:
                    OnboardingTransitionScreen(lang: $lang) {
                        step = .question(3)
                    }
                case .question(let i):
                    OnboardingQuestionScreen(
                        lang: $lang,
                        question: questions[i],
                        qIndex: i, qTotal: questions.count,
                        selected: Binding(get: { answers[i] }, set: { answers[i] = $0 }),
                        onNext: { advanceFromQuestion(i) }
                    )
                case .scanner:
                    OnboardingScannerView(
                        lang: $lang,
                        result: committedResult,
                        catName: name.isEmpty ? nil : name,
                        scanDuration: 5.2,             // ⬅ SACRED. Do not change.
                        onContinue: { step = .nameSave }
                    )
                    // Defensive: if we ever enter .scanner without commit() (e.g.
                    // future deep-link), compute & cache a stable fallback once.
                    .task {
                        if result == nil && fallbackResult == nil {
                            fallbackResult = OnboardingScoring.compute(
                                questions: questions,
                                answers: OnboardingScoring.fillUnansweredRandomly(
                                    answers, questions: questions),
                                lang: lang)
                        }
                    }
                case .nameSave:
                    OnboardingNameSaveScreen(
                        lang: $lang, name: $name, ageIndex: $ageIndex,
                        dominant: committedResult.dominant,
                        onSave: { saveProfileAndAdvance() }
                    )
                case .feed:
                    OnboardingFeedScreen(
                        lang: $lang,
                        onContinue: { step = .recap }
                    )
                case .recap:
                    OnboardingRecapScreen(
                        lang: $lang,
                        result: committedResult,
                        questions: OnboardingContent.questions(lang),
                        answers: answers
                    ) {
                        step = .bridge
                    }
                case .bridge:
                    OnboardingBridgeScreen(
                        lang: $lang,
                        dominant: committedResult.dominant,
                        onContinue: { finishOnboarding() }
                    )
                }
            }
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: .trailing)),
                removal:   .opacity.combined(with: .move(edge: .leading))
            ))
            .animation(.spring(response: 0.45, dampingFraction: 0.86), value: step)
        }
        .preferredColorScheme(.dark)
        // ── Telemetry hooks ──────────────────────────────────────────────
        .onAppear {
            OnboardingAnalytics.started(lang: lang)
            OnboardingAnalytics.stepViewed(step.analyticsName, lang: lang)
        }
        .onChange(of: step) { _, new in
            OnboardingAnalytics.stepViewed(new.analyticsName, lang: lang)
        }
        .onChange(of: lang) { _, new in
            OnboardingAnalytics.languageChanged(to: new, on: step.analyticsName)
        }
    }

    // MARK: - Flow

    private func advanceFromQuestion(_ i: Int) {
        switch i {
        case 0, 1: step = .question(i + 1)
        case 2:    step = .transition
        case 3, 4: step = .question(i + 1)
        case 5:    commit(); step = .scanner
        default:   step = .scanner  // safety
        }
    }

    private func commit() {
        result = OnboardingScoring.compute(questions: questions, answers: answers, lang: lang)
    }

    /// Persist the demo-scan baseline and fire `profile_saved` analytics.
    /// Called from the NameSave screen's "Save profile" button.
    /// `-1` is the sentinel for "age not chosen" (keeps the storage/analytics
    /// schema as plain `Int` without making the field optional everywhere).
    private func saveProfileAndAdvance() {
        let r = committedResult
        let ageSentinel = ageIndex ?? -1
        OnboardingResultStore.shared.save(
            result: r,
            lang: lang,
            catName: name,
            ageIndex: ageSentinel,
            answers: answers
        )
        OnboardingAnalytics.profileSaved(
            hasName: !name.isEmpty,
            ageIndex: ageSentinel,
            dominant: r.dominant.rawValue,
            lang: lang
        )
        step = .feed
    }

    /// Fires bridge_cta + completed (with duration + user property) and hands
    /// control back to ContentView, which presents AdaptyPaywallView.
    private func finishOnboarding() {
        let dominant = committedResult.dominant.rawValue
        OnboardingAnalytics.bridgeCTATapped(dominant: dominant, lang: lang)
        OnboardingAnalytics.completed(dominant: dominant, lang: lang)
        withAnimation { hasCompletedOnboarding = true }
    }
}

#Preview {
    InteractiveOnboardingView(hasCompletedOnboarding: .constant(false))
}
