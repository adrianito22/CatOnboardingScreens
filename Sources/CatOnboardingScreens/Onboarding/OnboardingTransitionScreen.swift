// OnboardingTransitionScreen.swift
// CatScan — InteractiveOnboarding
//
// Sits between question 3 (the last emotional / "discover" question) and
// question 4 (the first physical cue). Hosts the only interactive non-question
// moment in the entire onboarding: a "tap to wake the cat" mini-moment that
// narratively pivots the user from talking about themselves to looking at
// their cat. Bilingual (es/en).

import SwiftUI

struct OnboardingTransitionScreen: View {
    @Binding var lang: OnboardingLang
    var onContinue: () -> Void
    var onLanguageToggle: () -> Void = {}

    @State private var isAwake = false

    // MARK: Localized copy (changes when the cat wakes)

    private var eyebrowText: String {
        lang == .es ? "AHORA VIENE LO BUENO" : "NOW THE GOOD PART"
    }
    private var titleText: String {
        if isAwake {
            return lang == .es ? "Listo. Ahora obsérvalo" : "Ready. Now observe them"
        } else {
            return lang == .es ? "Despierta a tu gato" : "Wake up your cat"
        }
    }
    private var subtitleText: String {
        if isAwake {
            return lang == .es
                ? "Tres pistas físicas. Treinta segundos."
                : "Three physical cues. Thirty seconds."
        } else {
            return lang == .es
                ? "Toca al gato para llamarlo. Vamos a leer su cuerpo en tres preguntas."
                : "Tap the cat to call them. We're about to read their body in three questions."
        }
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
                        .contentTransition(.opacity)
                        .id(titleText)

                    Text(subtitleText)
                        .font(OnboardingType.subtitle)
                        .foregroundStyle(Color.white.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)
                        .contentTransition(.opacity)
                        .id(subtitleText)

                    SleepyCatHero(isAwake: $isAwake)
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
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: isAwake)
    }
}

// MARK: - Sleepy cat hero (interactive)
//
// A SwiftUI-shape cat that starts asleep (ears down, eyes closed as arcs,
// "Z" floating above). On tap: ears spring up, eyes morph to dots, the Z
// fades away, a soft purr-style haptic fires, and the parent screen flips
// `isAwake = true` so the copy + CTA update.
//
// Purely SwiftUI primitives — no assets. The composition is broken into
// sub-views so the SwiftUI type checker doesn't time out.
private struct SleepyCatHero: View {
    @Binding var isAwake: Bool

    @State private var idlePulse: CGFloat = 0
    @State private var awakeBlink: CGFloat = 1   // 1 = eyes open, 0 = closed
    @State private var zFloat: CGFloat = 0

    var body: some View {
        ZStack {
            bloom
            zParticles
                .opacity(isAwake ? 0 : 1)

            Button {
                if !isAwake { wakeUp() }
            } label: {
                cat
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Tap to wake the cat"))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 240)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                idlePulse = 1
            }
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                zFloat = 1
            }
        }
    }

    private func wakeUp() {
        OnboardingHaptics.optionSelected.fire()
        isAwake = true
        // After the wake animation lands, start the slow-blink loop.
        Task {
            try? await Task.sleep(nanoseconds: 600_000_000)
            await blinkLoop()
        }
    }

    private func blinkLoop() async {
        while !Task.isCancelled && isAwake {
            try? await Task.sleep(nanoseconds: 3_400_000_000)
            withAnimation(.easeInOut(duration: 0.08)) { awakeBlink = 0.05 }
            try? await Task.sleep(nanoseconds: 130_000_000)
            withAnimation(.easeInOut(duration: 0.12)) { awakeBlink = 1 }
        }
    }

    // MARK: Sub-views

    private var bloom: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color.brandPurpleSoft.opacity(0.30), Color.brandPurpleSoft.opacity(0)],
                    center: .center, startRadius: 10, endRadius: 130
                )
            )
            .frame(width: 260, height: 260)
            .blur(radius: 28)
    }

    private var zParticles: some View {
        ZStack {
            zLetter(size: 18, opacity: 0.7, baseOffset: CGSize(width: 32, height: -56), phase: 0)
            zLetter(size: 14, opacity: 0.5, baseOffset: CGSize(width: 48, height: -78), phase: 0.5)
            zLetter(size: 10, opacity: 0.35, baseOffset: CGSize(width: 60, height: -94), phase: 1.0)
        }
    }

    private func zLetter(size: CGFloat, opacity: Double, baseOffset: CGSize, phase: Double) -> some View {
        let drift: CGFloat = -8
        return Text("z")
            .font(.custom("Nunito-Black", size: size))
            .italic()
            .foregroundStyle(Color.brandPurpleSoft.opacity(opacity))
            .offset(x: baseOffset.width, y: baseOffset.height + zFloat * drift)
            .opacity(0.6 + (zFloat * 0.4))
    }

    /// The cat composition — head + ears + face. Eyes and ears swap pose
    /// based on `isAwake`.
    private var cat: some View {
        ZStack {
            ears
            head
            face
        }
        .scaleEffect(isAwake ? 1.0 : (1.0 + idlePulse * 0.025))
        .shadow(color: Color.brandPurpleSoft.opacity(0.45), radius: 22, y: 10)
    }

    private var head: some View {
        Ellipse()
            .fill(
                LinearGradient(
                    colors: [Color.brandPurpleSoft, Color.brandPurpleSoft.opacity(0.82)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .frame(width: 150, height: 130)
            .overlay(
                Ellipse()
                    .stroke(Color.white.opacity(0.10), lineWidth: 1.5)
            )
    }

    private var ears: some View {
        HStack(spacing: 70) {
            ear(side: .left)
            ear(side: .right)
        }
        .offset(y: -70)
    }

    private enum EarSide { case left, right }

    private func ear(side: EarSide) -> some View {
        let sleepingRotation: Double = side == .left ? -28 : 28
        let awakeRotation: Double = side == .left ? -6 : 6
        return Triangle()
            .fill(Color.brandPurpleSoft)
            .frame(width: 38, height: 44)
            .overlay(
                // Inner ear pink
                Triangle()
                    .fill(Color.brandPink.opacity(0.55))
                    .frame(width: 18, height: 26)
                    .offset(y: 6)
            )
            .rotationEffect(.degrees(isAwake ? awakeRotation : sleepingRotation))
            .offset(y: isAwake ? 0 : 8)
    }

    private var face: some View {
        ZStack {
            eyes
            nose.offset(y: 10)
            whiskers
        }
        .offset(y: -4)
    }

    private var eyes: some View {
        HStack(spacing: 36) {
            eye(side: .left)
            eye(side: .right)
        }
        .offset(y: -8)
    }

    private func eye(side: EarSide) -> some View {
        Group {
            if isAwake {
                // Open eye: filled white sclera with brand pupil
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 14, height: 14)
                    Circle()
                        .fill(Color.black)
                        .frame(width: 7, height: 7)
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 3, height: 3)
                        .offset(x: -2, y: -2)
                }
                .scaleEffect(x: 1, y: awakeBlink, anchor: .center)
            } else {
                // Sleeping eye: gentle arc (closed eyelid)
                SleepingEyeShape()
                    .stroke(Color.white.opacity(0.85), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                    .frame(width: 18, height: 8)
            }
        }
    }

    private var nose: some View {
        Triangle()
            .fill(Color.brandPink.opacity(0.85))
            .frame(width: 10, height: 7)
            .rotationEffect(.degrees(180))
    }

    private var whiskers: some View {
        HStack(spacing: 70) {
            whiskerSet(side: .left)
            whiskerSet(side: .right)
        }
        .offset(y: 16)
    }

    private func whiskerSet(side: EarSide) -> some View {
        let dir: CGFloat = side == .left ? -1 : 1
        return ZStack {
            whisker(angle: 0, length: 24, dir: dir)
            whisker(angle: -12, length: 22, dir: dir)
            whisker(angle: 12, length: 22, dir: dir)
        }
    }

    private func whisker(angle: Double, length: CGFloat, dir: CGFloat) -> some View {
        Rectangle()
            .fill(Color.white.opacity(0.45))
            .frame(width: length, height: 1.2)
            .offset(x: dir * length / 2)
            .rotationEffect(.degrees(angle))
    }
}

// MARK: - Shapes

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Sleeping eye = a gentle concave arc, like a closed eyelid seen from the front.
private struct SleepingEyeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control: CGPoint(x: rect.midX, y: rect.maxY + 2)
        )
        return path
    }
}
