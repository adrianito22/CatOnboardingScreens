// OnboardingRecapScreen.swift
// CatScan — InteractiveOnboarding
//
// Recap screen shown between the `feed` step and the `bridge` step. It echoes
// back the user's literal answers + the scan result so the personalization
// feels earned — then primes the closer that leads into the paywall:
// "you saw X%, the real scanner shows the rest."
//
// Style matches BridgeScreen: dark background, GlowCard hero tinted to the
// dominant trait, small surface-card recap rows for each question they
// answered, and a heavy gradient CTA at the bottom.

import SwiftUI

struct OnboardingRecapScreen: View {
    @Binding var lang: OnboardingLang
    let result: OnboardingResult
    let questions: [OnboardingQuestion]
    let answers: [Int?]
    var onContinue: () -> Void
    var onLanguageToggle: () -> Void = {}

    // Accent color for the hero. OnboardingTrait.color exists (see
    // OnboardingData.swift lines 28–37) and matches the scanner palette,
    // so we use it directly. Falls back to .brandPurple if `top` is empty.
    private var accent: Color {
        result.top.isEmpty ? .brandPurple : result.dominant.color
    }

    private var dominantValue: Int {
        result.top.first?.value ?? 0
    }

    private var missing: Int {
        100 - dominantValue
    }

    private var dominantName: String {
        let pair = result.dominant.localized
        return (lang == .es ? pair.es : pair.en).uppercased()
    }

    private var closerText: String {
        lang == .es
            ? "Te falta entender el otro \(missing)%. Eso lo hace el scanner real."
            : "You're missing the other \(missing)%. That's what the real scanner reveals."
    }

    var body: some View {
        ZStack {
            Color.brandBg.ignoresSafeArea()

            VStack(spacing: 0) {
                OnboardingTopBar(lang: $lang)
                    .padding(.horizontal, 22).padding(.top, 8)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        Eyebrow(
                            text: lang == .es ? "TU LECTURA" : "YOUR READING",
                            color: accent
                        )
                        .padding(.top, 14)

                        Text(lang == .es ? "Esto es lo que vimos" : "Here's what we saw")
                            .font(OnboardingType.display)
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)

                        // Hero card — big % + dominant trait name + observation.
                        // If `result.top` is empty, render only the observation
                        // (still useful, never crashes).
                        GlowCard(accent: accent) {
                            VStack(spacing: 10) {
                                if !result.top.isEmpty {
                                    Text("\(dominantValue)%")
                                        .font(.custom("Nunito-Black", size: 56, relativeTo: .largeTitle))
                                        .foregroundStyle(accent)
                                        .accessibilityLabel(Text("\(dominantValue) percent"))

                                    Text(dominantName)
                                        .font(OnboardingType.eyebrow)
                                        .tracking(1.6)
                                        .foregroundStyle(.white)
                                }

                                Text(result.observation)
                                    .font(OnboardingType.hint)
                                    .foregroundStyle(.white.opacity(0.78))
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity)
                        }

                        // Three recap rows — render only the ones we have data for.
                        // Skipped answers degrade to "(saltado)" / "(skipped)".
                        VStack(spacing: 10) {
                            recapRow(
                                qIndex: 0,
                                eyebrow: lang == .es ? "Dijiste" : "You said"
                            )
                            recapRow(
                                qIndex: 1,
                                eyebrow: lang == .es ? "Sientes" : "You feel"
                            )
                            recapRow(
                                qIndex: 2,
                                eyebrow: lang == .es ? "Quieres saber" : "You want to know"
                            )
                        }

                        // Closer — plain text, no card, full width.
                        Text(closerText)
                            .font(OnboardingType.subtitle)
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 16)
                }

                Spacer(minLength: 0)

                PrimaryGradientButton(
                    title: lang == .es ? "Probar con mi gato" : "Try it with my cat",
                    haptic: .bridgeLaunch,
                    action: onContinue
                )
                .padding(.horizontal, 22).padding(.bottom, 24)
            }
        }
    }

    /// Renders a single recap row for question `qIndex` if it exists.
    /// Defensive: bails to EmptyView when the question/answer index is out
    /// of range so we never crash on a partially-answered onboarding.
    @ViewBuilder
    private func recapRow(qIndex: Int, eyebrow: String) -> some View {
        if qIndex < questions.count && qIndex < answers.count {
            let q = questions[qIndex]
            let a = answers[qIndex]
            let label: String = {
                if let idx = a, idx >= 0, idx < q.options.count {
                    return q.options[idx].label
                }
                return lang == .es ? "(saltado)" : "(skipped)"
            }()

            VStack(alignment: .leading, spacing: 6) {
                Eyebrow(text: eyebrow, size: 10, tracking: 1.4)
                Text(label)
                    .font(OnboardingType.subtitle)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.brandSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.borderDefault, lineWidth: 1)
            )
        }
    }
}
