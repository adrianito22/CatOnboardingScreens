// OnboardingTransitionScreen.swift
// CatScan — InteractiveOnboarding
//
// Sits between question 3 (the last emotional / "discover" question) and
// question 4 (the first physical cue). Mirrors the structure of
// OnboardingBridgeScreen but with a simpler hero — a single eye glyph with
// a brand-purple halo, no Memory-vs-Photo split. Bilingual (es/en).

import SwiftUI

struct OnboardingTransitionScreen: View {
    @Binding var lang: OnboardingLang
    var onContinue: () -> Void
    /// Optional hook for the host to react to language toggles. The bundled
    /// `OnboardingTopBar` already mutates `lang` via the binding, so this
    /// callback is purely informational (analytics, parent state, etc.).
    var onLanguageToggle: () -> Void = {}

    // MARK: Localized copy

    private var eyebrowText: String {
        lang == .es ? "AHORA VIENE LO BUENO" : "NOW THE GOOD PART"
    }
    private var titleText: String {
        lang == .es ? "Ahora veamos a tu gato" : "Now let's look at your cat"
    }
    private var subtitleText: String {
        lang == .es
            ? "Tres pistas físicas son todo lo que el escáner necesita para leerlo. Listo en 30 segundos."
            : "Three physical cues are all the scanner needs to read them. Done in 30 seconds."
    }
    private var ctaText: String {
        lang == .es ? "Empezar el escaneo" : "Start the scan"
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            OnboardingTopBar(lang: $lang, showSkip: false)
                .padding(.horizontal, 22)
                .padding(.top, 8)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Eyebrow(text: eyebrowText, color: .brandPurple)
                        .padding(.top, 14)

                    Text(titleText)
                        .font(.custom("Nunito-Black", size: 26, relativeTo: .title))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(subtitleText)
                        .font(.custom("Nunito-Medium", size: 15, relativeTo: .body))
                        .foregroundStyle(Color.white.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)

                    // Hero — SF Symbol eye.fill with a soft purple halo behind it
                    ZStack {
                        Circle()
                            .fill(Color.brandPurple.opacity(0.18))
                            .frame(width: 220, height: 220)
                            .blur(radius: 40)
                        Image(systemName: "eye.fill")
                            .font(.system(size: 96, weight: .bold))
                            .foregroundStyle(LinearGradient.brand)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 22)
            }

            Spacer(minLength: 0)

            PrimaryGradientButton(
                title: ctaText,
                haptic: .primaryTapped,
                action: onContinue
            )
            .padding(.horizontal, 22)
            .padding(.bottom, 24)
        }
        .background(Color.brandBg.ignoresSafeArea())
        .onChange(of: lang) { _, _ in onLanguageToggle() }
    }
}
