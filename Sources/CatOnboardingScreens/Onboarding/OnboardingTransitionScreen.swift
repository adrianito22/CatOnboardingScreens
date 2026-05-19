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
// "Z" floating above, tail curled). On tap: ears spring up, eyes morph
// into almond-shaped cat eyes with vertical pupils + catchlights, the Z
// fades away, a soft purr-style haptic fires, hearts and sparkles burst
// out, and the parent screen flips `isAwake = true` so the copy + CTA
// update. While awake, the tail swishes and an ear twitches periodically.
//
// Built entirely from SwiftUI primitives — no assets. The composition is
// broken into small sub-views so the SwiftUI type checker doesn't time out.
private struct SleepyCatHero: View {
    @Binding var isAwake: Bool

    @State private var idlePulse: CGFloat = 0
    @State private var awakeBlink: CGFloat = 1   // 1 = open, 0 = closed
    @State private var zFloat: CGFloat = 0
    @State private var tailPhase: CGFloat = 0
    @State private var earTwitch: Bool = false
    @State private var particles: [WakeParticle] = []

    var body: some View {
        ZStack {
            bloom
            zParticles
                .opacity(isAwake ? 0 : 1)

            Button {
                if !isAwake { wakeUp() }
            } label: {
                catWithBody
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Tap to wake the cat"))

            ForEach(particles) { p in
                WakeParticleView(particle: p)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 260)
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
        spawnParticles()
        isAwake = true
        // Start the awake loops once the wake transition lands.
        Task {
            try? await Task.sleep(nanoseconds: 600_000_000)
            await runAwakeLoops()
        }
    }

    private func spawnParticles() {
        let icons: [(String, Color)] = [
            ("heart.fill", Color.brandPink),
            ("sparkle",    Color.brandPurpleSoft),
            ("heart.fill", Color.brandPink.opacity(0.85)),
            ("sparkle",    Color.brandCyan),
            ("heart.fill", Color.brandPink),
            ("sparkle",    Color.brandPurpleSoft),
            ("heart.fill", Color.brandPink.opacity(0.7)),
            ("sparkle",    Color.brandPurpleSoft.opacity(0.85)),
        ]
        let now = Date()
        let new = icons.enumerated().map { (i, pair) -> WakeParticle in
            // Spread in a slight upward fan around the cat's head.
            let angle = Double.random(in: -1.2 ... 1.2)        // radians, mostly upward
            let distance = CGFloat.random(in: 90 ... 140)
            let endX = CGFloat(cos(angle - .pi / 2)) * distance
            let endY = CGFloat(sin(angle - .pi / 2)) * distance - 20
            return WakeParticle(
                id: UUID(),
                symbol: pair.0,
                color: pair.1,
                startTime: now.addingTimeInterval(Double(i) * 0.04),
                endOffset: CGSize(width: endX, height: endY),
                size: CGFloat.random(in: 12 ... 18)
            )
        }
        particles.append(contentsOf: new)
        // Clean up after the animation completes.
        Task {
            try? await Task.sleep(nanoseconds: 1_700_000_000)
            particles.removeAll()
        }
    }

    private func runAwakeLoops() async {
        // Tail swish — smooth back and forth.
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
            tailPhase = 1
        }
        // Slow blink + occasional ear twitch interleaved.
        while !Task.isCancelled && isAwake {
            try? await Task.sleep(nanoseconds: 3_400_000_000)
            withAnimation(.easeInOut(duration: 0.08)) { awakeBlink = 0.05 }
            try? await Task.sleep(nanoseconds: 130_000_000)
            withAnimation(.easeInOut(duration: 0.12)) { awakeBlink = 1 }

            // ~50% of the time, follow with a quick ear twitch.
            if Bool.random() {
                try? await Task.sleep(nanoseconds: 800_000_000)
                withAnimation(.easeInOut(duration: 0.12)) { earTwitch = true }
                try? await Task.sleep(nanoseconds: 180_000_000)
                withAnimation(.easeInOut(duration: 0.18)) { earTwitch = false }
            }
        }
    }

    // MARK: Sub-views

    private var bloom: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color.brandPurpleSoft.opacity(0.32), Color.brandPurpleSoft.opacity(0)],
                    center: .center, startRadius: 10, endRadius: 130
                )
            )
            .frame(width: 280, height: 280)
            .blur(radius: 28)
    }

    private var zParticles: some View {
        ZStack {
            zLetter(size: 20, opacity: 0.7,  baseOffset: CGSize(width: 38, height: -68), drift: -10)
            zLetter(size: 15, opacity: 0.5,  baseOffset: CGSize(width: 54, height: -90), drift: -12)
            zLetter(size: 11, opacity: 0.35, baseOffset: CGSize(width: 68, height: -108), drift: -14)
        }
    }

    private func zLetter(size: CGFloat, opacity: Double, baseOffset: CGSize, drift: CGFloat) -> some View {
        Text("z")
            .font(.custom("Nunito-Black", size: size))
            .italic()
            .foregroundStyle(Color.brandPurpleSoft.opacity(opacity))
            .offset(x: baseOffset.width, y: baseOffset.height + zFloat * drift)
    }

    /// Everything that responds to taps: body, tail, head, face.
    private var catWithBody: some View {
        ZStack {
            tail
            torso
            ears
            head
            face
        }
        .scaleEffect(isAwake ? 1.0 : (1.0 + idlePulse * 0.025))
        .shadow(color: Color.brandPurpleSoft.opacity(0.45), radius: 24, y: 12)
    }

    // ── Torso & tail ─────────────────────────────────────────────────────

    private var torso: some View {
        Ellipse()
            .fill(
                LinearGradient(
                    colors: [Color.brandPurpleSoft.opacity(0.85), Color.brandPurpleSoft.opacity(0.55)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .frame(width: 130, height: 80)
            .overlay(
                // Belly fluff highlight
                Ellipse()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: 80, height: 38)
                    .offset(y: 10)
            )
            .offset(y: 70)
    }

    private var tail: some View {
        TailShape()
            .stroke(
                LinearGradient(
                    colors: [Color.brandPurpleSoft, Color.brandPurpleSoft.opacity(0.7)],
                    startPoint: .top, endPoint: .bottom
                ),
                style: StrokeStyle(lineWidth: 14, lineCap: .round)
            )
            .frame(width: 110, height: 90)
            .rotationEffect(.degrees(isAwake ? Double(tailPhase) * 12.0 - 6.0 : 0), anchor: .bottomLeading)
            .offset(x: 60, y: 70)
    }

    // ── Head + ears ──────────────────────────────────────────────────────

    private var head: some View {
        ZStack {
            // Cheek puffs — give the head a chubbier, more cat-like silhouette.
            HStack(spacing: 110) {
                cheekPuff
                cheekPuff
            }
            .offset(y: 14)

            // Main head ellipse with a soft inner shadow for volume.
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Color.brandPurpleSoft, Color.brandPurpleSoft.opacity(0.78)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 150, height: 130)
                .overlay(
                    Ellipse()
                        .stroke(Color.white.opacity(0.10), lineWidth: 1.5)
                )
                .overlay(
                    // Subtle darker base for volume
                    Ellipse()
                        .fill(Color.black.opacity(0.12))
                        .frame(width: 130, height: 60)
                        .blur(radius: 14)
                        .offset(y: 28)
                        .blendMode(.multiply)
                )
        }
    }

    private var cheekPuff: some View {
        Ellipse()
            .fill(Color.brandPurpleSoft.opacity(0.92))
            .frame(width: 44, height: 38)
            .overlay(
                Ellipse()
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
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
        let baseAwakeRotation: Double = side == .left ? -6 : 6
        // The right ear is the one that twitches.
        let twitchOffset: Double = (side == .right && earTwitch) ? -14 : 0
        return Triangle()
            .fill(
                LinearGradient(
                    colors: [Color.brandPurpleSoft, Color.brandPurpleSoft.opacity(0.85)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .frame(width: 38, height: 44)
            .overlay(
                // Inner ear pink
                Triangle()
                    .fill(Color.brandPink.opacity(0.55))
                    .frame(width: 18, height: 26)
                    .offset(y: 6)
            )
            .rotationEffect(.degrees(isAwake ? (baseAwakeRotation + twitchOffset) : sleepingRotation))
            .offset(y: isAwake ? 0 : 8)
    }

    // ── Face ─────────────────────────────────────────────────────────────

    private var face: some View {
        ZStack {
            cheekBlush
            eyes
            nose.offset(y: 14)
            mouth.offset(y: 24)
            whiskers
        }
        .offset(y: -2)
    }

    private var cheekBlush: some View {
        HStack(spacing: 64) {
            Circle()
                .fill(Color.brandPink.opacity(0.35))
                .frame(width: 18, height: 18)
                .blur(radius: 4)
            Circle()
                .fill(Color.brandPink.opacity(0.35))
                .frame(width: 18, height: 18)
                .blur(radius: 4)
        }
        .offset(y: 16)
        .opacity(isAwake ? 1 : 0.5)
    }

    private var eyes: some View {
        HStack(spacing: 30) {
            eye()
            eye()
        }
        .offset(y: -10)
    }

    private func eye() -> some View {
        Group {
            if isAwake {
                // Open almond eye with vertical cat pupil + catchlight.
                ZStack {
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.brandCyan.opacity(0.85),
                                    Color.white,
                                ],
                                center: UnitPoint(x: 0.4, y: 0.4),
                                startRadius: 1,
                                endRadius: 14
                            )
                        )
                        .frame(width: 22, height: 18)
                    Capsule()
                        .fill(Color.black)
                        .frame(width: 4, height: 14)
                    // Catchlight
                    Circle()
                        .fill(Color.white)
                        .frame(width: 3, height: 3)
                        .offset(x: -3, y: -3)
                    // Outline for definition
                    Ellipse()
                        .stroke(Color.black.opacity(0.18), lineWidth: 1)
                        .frame(width: 22, height: 18)
                }
                .scaleEffect(x: 1, y: awakeBlink, anchor: .center)
            } else {
                // Closed sleeping eye — concave arc, like an eyelid.
                SleepingEyeShape()
                    .stroke(Color.white.opacity(0.9), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
                    .frame(width: 20, height: 9)
            }
        }
    }

    private var nose: some View {
        Triangle()
            .fill(Color.brandPink.opacity(0.9))
            .frame(width: 11, height: 8)
            .rotationEffect(.degrees(180))
    }

    private var mouth: some View {
        // Cute "3"-style mouth visible only when awake.
        MouthShape()
            .stroke(Color.white.opacity(0.7), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
            .frame(width: 18, height: 6)
            .opacity(isAwake ? 1 : 0)
    }

    private var whiskers: some View {
        HStack(spacing: 64) {
            whiskerSet(side: .left)
            whiskerSet(side: .right)
        }
        .offset(y: 18)
    }

    private func whiskerSet(side: EarSide) -> some View {
        let dir: CGFloat = side == .left ? -1 : 1
        return ZStack {
            whisker(angle: 0,   length: 26, dir: dir)
            whisker(angle: -10, length: 22, dir: dir)
            whisker(angle: 10,  length: 22, dir: dir)
        }
    }

    private func whisker(angle: Double, length: CGFloat, dir: CGFloat) -> some View {
        Rectangle()
            .fill(Color.white.opacity(0.55))
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

/// Cute "3"-shaped mouth — a quick double curve.
private struct MouthShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.midY),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.minY + 2),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        return path
    }
}

/// Tail curving out from the right of the body and rising up.
private struct TailShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let start = CGPoint(x: rect.minX + 4, y: rect.maxY - 6)
        let control1 = CGPoint(x: rect.maxX - 6, y: rect.maxY - 10)
        let control2 = CGPoint(x: rect.maxX - 4, y: rect.minY + 18)
        let end = CGPoint(x: rect.maxX - 18, y: rect.minY + 4)
        path.move(to: start)
        path.addCurve(to: end, control1: control1, control2: control2)
        return path
    }
}

// MARK: - Wake particles

private struct WakeParticle: Identifiable {
    let id: UUID
    let symbol: String
    let color: Color
    let startTime: Date
    let endOffset: CGSize
    let size: CGFloat
}

private struct WakeParticleView: View {
    let particle: WakeParticle
    @State private var progress: CGFloat = 0

    var body: some View {
        Image(systemName: particle.symbol)
            .font(.system(size: particle.size, weight: .black))
            .foregroundStyle(particle.color)
            .shadow(color: particle.color.opacity(0.5), radius: 6, y: 2)
            .offset(x: particle.endOffset.width * progress,
                    y: particle.endOffset.height * progress)
            .opacity(progress < 0.1 ? Double(progress * 10) : Double(1 - (progress - 0.1) * 1.1))
            .scaleEffect(0.5 + progress * 0.8)
            .rotationEffect(.degrees(Double(progress) * 60 - 30))
            .onAppear {
                // Delay each particle slightly for a staggered burst.
                let delay = max(0, particle.startTime.timeIntervalSinceNow)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeOut(duration: 1.4)) {
                        progress = 1
                    }
                }
            }
    }
}
