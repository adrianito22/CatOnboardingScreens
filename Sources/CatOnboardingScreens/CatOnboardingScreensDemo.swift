// CatOnboardingScreensDemo.swift
// Standalone navigator for the 8 onboarding screens. Lets a designer (or
// design tool) open any single screen in isolation, or run the full
// interactive flow end-to-end. No Firebase, no Adapty, no persistence —
// everything is in-memory.

import SwiftUI

public struct CatOnboardingScreensDemo: View {
    public init() {
        NunitoFontLoader.registerIfNeeded()
    }

    @State private var lang: OnboardingLang = .es
    @State private var selection: Screen? = nil

    enum Screen: String, CaseIterable, Identifiable {
        case fullFlow         = "Full interactive flow"
        case welcome          = "1 · Welcome"
        case questionEmotion  = "2 · Question — emotional (Q1)"
        case questionPhysical = "3 · Question — physical (Q4 eyes)"
        case transition       = "4 · Transition (Q3 → Q4)"
        case scanner          = "5 · Scanner reveal"
        case nameSave         = "6 · Name save"
        case feed             = "7 · Feed teaser"
        case recap            = "8 · Recap (before paywall)"
        case bridge           = "9 · Bridge (to paywall)"

        var id: String { rawValue }
    }

    public var body: some View {
        NavigationStack {
            List(Screen.allCases) { screen in
                Button {
                    selection = screen
                } label: {
                    HStack {
                        Text(screen.rawValue)
                            .font(.custom("Nunito-Bold", size: 16))
                            .foregroundStyle(.white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(.vertical, 6)
                }
                .listRowBackground(Color.white.opacity(0.04))
            }
            .scrollContentBackground(.hidden)
            .background(OnboardingColors.bg.ignoresSafeArea())
            .navigationTitle("CatOnboarding")
            #if os(iOS)
            .toolbarColorScheme(.dark, for: .navigationBar)
            #endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        lang = (lang == .es) ? .en : .es
                    } label: {
                        Text(lang.rawValue.uppercased())
                            .font(.custom("Nunito-Black", size: 13))
                            .foregroundStyle(.white)
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
        #if os(iOS)
        .fullScreenCover(item: $selection) { screen in
            ScreenWrapper(screen: screen, lang: $lang, dismiss: { selection = nil })
        }
        #else
        .sheet(item: $selection) { screen in
            ScreenWrapper(screen: screen, lang: $lang, dismiss: { selection = nil })
        }
        #endif
    }
}

// MARK: - Screen wrapper

private struct ScreenWrapper: View {
    let screen: CatOnboardingScreensDemo.Screen
    @Binding var lang: OnboardingLang
    let dismiss: () -> Void

    @State private var fakeAnswer: Int? = nil
    @State private var fakeName: String = ""
    @State private var fakeAge: Int? = nil
    @State private var done = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            OnboardingColors.bg.ignoresSafeArea()
            content
            // Floating close — useful when previewing a screen that doesn't
            // have its own back button.
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Circle().fill(Color.white.opacity(0.18)))
            }
            .padding(.top, 56)
            .padding(.trailing, 18)
            .opacity(screen == .fullFlow ? 0 : 1)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch screen {
        case .fullFlow:
            InteractiveOnboardingView(hasCompletedOnboarding: $done)
                .onChange(of: done) { _, isDone in
                    if isDone { dismiss() }
                }

        case .welcome:
            OnboardingWelcomeScreen(
                lang: $lang,
                onStart: { dismiss() }
            )

        case .questionEmotion:
            let qs = OnboardingContent.questions(lang)
            OnboardingQuestionScreen(
                lang: $lang,
                question: qs[1],                // emotional Q
                qIndex: 1, qTotal: qs.count,
                selected: $fakeAnswer,
                onNext: { dismiss() }
            )

        case .questionPhysical:
            let qs = OnboardingContent.questions(lang)
            OnboardingQuestionScreen(
                lang: $lang,
                question: qs[3],                // first physical (eyes)
                qIndex: 3, qTotal: qs.count,
                selected: $fakeAnswer,
                onNext: { dismiss() }
            )

        case .transition:
            OnboardingTransitionScreen(lang: $lang, onContinue: dismiss)

        case .scanner:
            OnboardingScannerView(
                lang: $lang,
                result: sampleResult,
                catName: "Pelusa",
                scanDuration: 5.2,
                onContinue: dismiss
            )

        case .nameSave:
            OnboardingNameSaveScreen(
                lang: $lang,
                name: $fakeName,
                ageIndex: $fakeAge,
                dominant: sampleResult.dominant,
                onSave: dismiss
            )

        case .feed:
            OnboardingFeedScreen(
                lang: $lang,
                onContinue: dismiss
            )

        case .recap:
            OnboardingRecapScreen(
                lang: $lang,
                result: sampleResult,
                questions: OnboardingContent.questions(lang),
                answers: [0, 1, 2, 0, 1, 0]    // example answers for the recap rows
            ) { dismiss() }

        case .bridge:
            OnboardingBridgeScreen(
                lang: $lang,
                dominant: sampleResult.dominant,
                onContinue: dismiss
            )
        }
    }

    /// Sample result for previewing screens that need one.
    private var sampleResult: OnboardingResult {
        OnboardingScoring.compute(
            questions: OnboardingContent.questions(lang),
            answers: [0, 1, 2, 1, 1, 0],
            lang: lang
        )
    }
}

#Preview("Onboarding Demo") {
    CatOnboardingScreensDemo()
}
