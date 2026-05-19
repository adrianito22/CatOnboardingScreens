// OnboardingTransitionScreen.swift
// CatScan — InteractiveOnboarding
//
// Sits between question 3 (the last emotional / "discover" question) and
// question 4 (the first physical cue). Mirrors the structure of
// OnboardingBridgeScreen but with a simpler hero — a mini scanner viewport
// teasing what the real scan will look like after the paywall.

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
                        .font(OnboardingType.display)
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(subtitleText)
                        .font(OnboardingType.subtitle)
                        .foregroundStyle(Color.white.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)

                    MiniScannerHero()
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

// MARK: - Mini scanner hero
//
// Teaser for the actual scanner the user will use after the paywall: a
// viewport with corner brackets, a cat silhouette inside, and a vertical
// scan line sweeping up and down. The visual language matches
// OnboardingScannerView's `scannerVisual`, so the transition narratively
// previews what they're about to experience.
private struct MiniScannerHero: View {
    @State private var scanY: CGFloat = 0   // 0 = top, 1 = bottom

    private let viewportSize: CGFloat = 200

    var body: some View {
        ZStack {
            bloom
            viewport
                .shadow(color: Color.brandPurpleSoft.opacity(0.45), radius: 22, y: 10)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 240)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                scanY = 1
            }
        }
    }

    // Soft purple halo behind the viewport.
    private var bloom: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color.brandPurpleSoft.opacity(0.28), Color.brandPurpleSoft.opacity(0)],
                    center: .center, startRadius: 20, endRadius: 130
                )
            )
            .frame(width: 260, height: 260)
            .blur(radius: 24)
    }

    private var viewport: some View {
        ZStack {
            backdrop
            catSilhouette
            scanLine
            brackets
        }
        .frame(width: viewportSize, height: viewportSize)
    }

    private var backdrop: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Color.white.opacity(0.035))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
    }

    private var catSilhouette: some View {
        Image(systemName: "cat.fill")
            .resizable()
            .scaledToFit()
            .padding(42)
            .foregroundStyle(Color.white.opacity(0.55))
            .frame(width: viewportSize, height: viewportSize)
    }

    private var scanLine: some View {
        GeometryReader { geo in
            let h = geo.size.height
            VStack(spacing: 0) {
                // Trail above the bright line
                Rectangle()
                    .fill(LinearGradient(
                        colors: [.clear, Color.brandPurpleSoft.opacity(0.22)],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .frame(height: 32)
                // The bright line itself
                Rectangle()
                    .fill(LinearGradient(
                        colors: [.clear, Color.brandPurpleSoft, Color.brandPink, .clear],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(height: 2.5)
                    .shadow(color: Color.brandPurpleSoft.opacity(0.8), radius: 8)
            }
            .offset(y: scanY * (h - 2.5) - 32)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .frame(width: viewportSize, height: viewportSize)
    }

    private var brackets: some View {
        ZStack {
            bracket(corner: .topLeading)
            bracket(corner: .topTrailing)
            bracket(corner: .bottomLeading)
            bracket(corner: .bottomTrailing)
        }
        .frame(width: viewportSize, height: viewportSize)
    }

    private enum Corner { case topLeading, topTrailing, bottomLeading, bottomTrailing }

    private func bracket(corner: Corner) -> some View {
        let armLength: CGFloat = 22
        let armWidth: CGFloat = 3
        let edgeInset: CGFloat = 10
        return ZStack {
            // Horizontal arm
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(Color.brandPurpleSoft)
                .frame(width: armLength, height: armWidth)
                .offset(x: corner == .topLeading || corner == .bottomLeading
                        ? -(viewportSize / 2 - armLength / 2 - edgeInset)
                        : (viewportSize / 2 - armLength / 2 - edgeInset),
                        y: corner == .topLeading || corner == .topTrailing
                        ? -(viewportSize / 2 - armWidth / 2 - edgeInset)
                        : (viewportSize / 2 - armWidth / 2 - edgeInset))
            // Vertical arm
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(Color.brandPurpleSoft)
                .frame(width: armWidth, height: armLength)
                .offset(x: corner == .topLeading || corner == .bottomLeading
                        ? -(viewportSize / 2 - armWidth / 2 - edgeInset)
                        : (viewportSize / 2 - armWidth / 2 - edgeInset),
                        y: corner == .topLeading || corner == .topTrailing
                        ? -(viewportSize / 2 - armLength / 2 - edgeInset)
                        : (viewportSize / 2 - armLength / 2 - edgeInset))
        }
    }
}
