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
                    Eyebrow(text: eyebrowText, color: .brandPurpleSoft)
                        .padding(.top, 14)

                    Text(titleText)
                        .font(.custom("Nunito-Black", size: 26, relativeTo: .title))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(subtitleText)
                        .font(.custom("Nunito-Medium", size: 15, relativeTo: .body))
                        .foregroundStyle(Color.white.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)

                    CatScannerEyeHero()
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

// MARK: - Cat scanner eye hero
//
// On-brand replacement for the generic `eye.fill` SF Symbol. A stylised cat
// eye (almond iris + vertical pupil + catch lights) sitting inside expanding
// scan rings. Pure SwiftUI shapes — no assets, scales perfectly.
private struct CatScannerEyeHero: View {
    @State private var pulse: CGFloat = 0
    @State private var blink: CGFloat = 1   // 1 = open, 0 = closed

    var body: some View {
        ZStack {
            bloom
            scanRings
            eye
                .scaleEffect(x: 1, y: blink, anchor: .center)
                .shadow(color: Color.brandPurpleSoft.opacity(0.55), radius: 28, y: 10)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 240)
        .onAppear {
            withAnimation(.easeOut(duration: 2.4).repeatForever(autoreverses: false)) {
                pulse = 1
            }
            Task { await runBlinkLoop() }
        }
    }

    // Soft purple bloom behind everything.
    private var bloom: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color.brandPurpleSoft.opacity(0.32), Color.brandPurpleSoft.opacity(0)],
                    center: .center, startRadius: 10, endRadius: 130
                )
            )
            .frame(width: 260, height: 260)
            .blur(radius: 28)
    }

    // Animated scan rings emanating outward.
    private var scanRings: some View {
        ZStack {
            scanRing(index: 0)
            scanRing(index: 1)
            scanRing(index: 2)
        }
    }

    private func scanRing(index: Int) -> some View {
        let opacity: Double = 0.28 - Double(index) * 0.07
        let size: CGFloat = 170 + CGFloat(index) * 36
        let scale: CGFloat = 1 + pulse * 0.04
        let alpha: Double = 1 - Double(pulse) * 0.35
        return Circle()
            .stroke(Color.brandPurpleSoft.opacity(opacity), lineWidth: 1.4)
            .frame(width: size, height: size)
            .scaleEffect(scale)
            .opacity(alpha)
    }

    // The cat eye composition.
    private var eye: some View {
        ZStack {
            iris
            pupil
            catchLights
            outline
        }
    }

    private var iris: some View {
        ZStack {
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.brandCyan.opacity(0.85),
                            Color.brandPurpleSoft,
                            Color.brandBlue
                        ],
                        center: UnitPoint(x: 0.4, y: 0.45),
                        startRadius: 4,
                        endRadius: 80
                    )
                )
            Ellipse()
                .fill(Color.brandPurpleSoft.opacity(0.45))
                .blur(radius: 18)
                .blendMode(.plusLighter)
                .opacity(0.55)
        }
        .frame(width: 160, height: 96)
    }

    private var pupil: some View {
        Capsule()
            .fill(Color.black)
            .frame(width: 18, height: 76)
    }

    private var catchLights: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 12, height: 12)
                .offset(x: -10, y: -18)
            Circle()
                .fill(Color.white.opacity(0.65))
                .frame(width: 6, height: 6)
                .offset(x: 13, y: 9)
        }
    }

    private var outline: some View {
        Ellipse()
            .stroke(Color.white.opacity(0.20), lineWidth: 1.5)
            .frame(width: 160, height: 96)
    }

    private func runBlinkLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 4_800_000_000)
            withAnimation(.easeInOut(duration: 0.08)) { blink = 0.1 }
            try? await Task.sleep(nanoseconds: 130_000_000)
            withAnimation(.easeInOut(duration: 0.12)) { blink = 1 }
        }
    }
}
