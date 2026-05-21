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

    var body: some View {
        VStack(spacing: 0) {
            OnboardingTopBar(lang: $lang)
                .padding(.horizontal, 22)
                .padding(.top, 8)

            // Title block at the top — short enough that it never needs scrolling.
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: eyebrowText, color: .brandPurpleSoft)

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
            }
            .padding(.horizontal, 22)
            .padding(.top, 14)

            // Flexible space pushes the cat down toward the CTA. Two Spacers
            // with different priorities keep the cat closer to the bottom
            // half while still leaving a comfortable gap above the button.
            Spacer(minLength: 24)

            SleepyCatHero(isAwake: $isAwake)
                .frame(maxWidth: .infinity)

            Spacer(minLength: 12)
                .frame(maxHeight: 36)

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
private struct SleepyCatHero: View {
    @Binding var isAwake: Bool

    // Sleeping idle animations
    @State private var breathing: CGFloat = 0          // 0..1 — scale loop
    @State private var bloomPulse: CGFloat = 0          // 0..1 — halo opacity
    @State private var sleepTailSway: CGFloat = 0       // 0..1 — slow tail dream sway
    @State private var zFloat: CGFloat = 0

    // Wake transition
    @State private var isStretching = false             // brief yawn squash before awake

    // Awake idle animations
    @State private var awakeBlink: CGFloat = 1          // 1 = open, 0 = closed
    @State private var awakeTailPhase: CGFloat = 0      // 0..1 — active swish
    @State private var earTwitch = false
    @State private var glanceX: CGFloat = 0             // -3..3 — pupil glance offset
    @State private var tongueDrop: CGFloat = 0          // 0..1 — tongue tip subtle drop

    // Particles
    @State private var particles: [WakeParticle] = []

    var body: some View {
        ZStack {
            bloom
            zParticles
                .opacity(isAwake ? 0 : 1)

            Button {
                if !isAwake { wakeUp() } else { petCat() }
            } label: {
                catBody
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Tap to wake the cat"))

            ForEach(particles) { p in
                WakeParticleView(particle: p)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
        .onAppear { startSleepingLoops() }
    }

    // MARK: Animation lifecycle

    private func startSleepingLoops() {
        withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
            breathing = 1
        }
        withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
            zFloat = 1
        }
        withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
            bloomPulse = 1
        }
        withAnimation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true)) {
            sleepTailSway = 1
        }
    }

    private func wakeUp() {
        OnboardingHaptics.optionSelected.fire()
        spawnParticles(count: 8, fan: true)

        // Stage 1: tiny stretch / yawn squash (0.18s)
        withAnimation(.easeInOut(duration: 0.18)) { isStretching = true }

        // Stage 2: release into awake state with bounce (0.4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.62)) {
                isStretching = false
                isAwake = true
            }
        }

        // Stage 3: start awake idle loops + brief curious glance
        Task {
            try? await Task.sleep(nanoseconds: 650_000_000)
            await runAwakeLoops()
        }
    }

    private func petCat() {
        OnboardingHaptics.optionSelected.fire()
        spawnParticles(count: 3, fan: false)
    }

    private func runAwakeLoops() async {
        // Continuous active tail swish.
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
            awakeTailPhase = 1
        }

        // Curious glance: left → right → center, once.
        withAnimation(.easeInOut(duration: 0.45)) { glanceX = -3 }
        try? await Task.sleep(nanoseconds: 500_000_000)
        withAnimation(.easeInOut(duration: 0.5)) { glanceX = 3 }
        try? await Task.sleep(nanoseconds: 500_000_000)
        withAnimation(.easeInOut(duration: 0.45)) { glanceX = 0 }

        // Tongue tip subtle drop loop.
        withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
            tongueDrop = 1
        }

        // Slow blink loop + occasional ear twitch.
        while !Task.isCancelled && isAwake {
            try? await Task.sleep(nanoseconds: 3_400_000_000)
            withAnimation(.easeInOut(duration: 0.08)) { awakeBlink = 0.05 }
            try? await Task.sleep(nanoseconds: 130_000_000)
            withAnimation(.easeInOut(duration: 0.12)) { awakeBlink = 1 }

            if Bool.random() {
                try? await Task.sleep(nanoseconds: 800_000_000)
                withAnimation(.easeInOut(duration: 0.12)) { earTwitch = true }
                try? await Task.sleep(nanoseconds: 180_000_000)
                withAnimation(.easeInOut(duration: 0.18)) { earTwitch = false }
            }
        }
    }

    // MARK: Particles

    private func spawnParticles(count: Int, fan: Bool) {
        let palette: [(String, Color)] = [
            ("heart.fill", Color.brandPink),
            ("sparkle",    Color.brandPurpleSoft),
            ("heart.fill", Color.brandPink.opacity(0.85)),
            ("sparkle",    Color.brandCyan),
        ]
        let now = Date()
        let new = (0..<count).map { i -> WakeParticle in
            let pair = palette[i % palette.count]
            // Spread in a slight upward fan around the cat's head (or tight cluster on pet).
            let spread: Double = fan ? 1.2 : 0.5
            let angle = Double.random(in: -spread ... spread)
            let distance = CGFloat.random(in: fan ? 90 ... 140 : 60 ... 90)
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
        Task {
            try? await Task.sleep(nanoseconds: 1_700_000_000)
            particles.removeAll { p in
                new.contains { $0.id == p.id }
            }
        }
    }

    // MARK: Sub-views

    private var bloom: some View {
        let baseOpacity: Double = 0.30
        let pulseOpacity: Double = isAwake ? baseOpacity : (0.25 + Double(bloomPulse) * 0.15)
        return Circle()
            .fill(
                RadialGradient(
                    colors: [Color.brandPurpleSoft.opacity(pulseOpacity), Color.brandPurpleSoft.opacity(0)],
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

    /// Cat composition. Z-order is: tail → torso → ears → head → face.
    /// This puts the tail BEHIND the torso so the curl reads naturally.
    private var catBody: some View {
        ZStack {
            tail
            torso
            ears
            head
            face
        }
        .scaleEffect(catScale, anchor: .bottom)
        .shadow(color: Color.brandPurpleSoft.opacity(0.45), radius: 24, y: 12)
    }

    /// Scale combines: sleeping breathing pulse OR awake stretch squash.
    /// Sleeping: x:y = 1.0 + b*0.025 (subtle inflate/deflate)
    /// Stretching: x: 1.08, y: 0.85 (squash/yawn)
    /// Awake idle: x:y = 1.0
    private var catScale: CGSize {
        if isStretching {
            return CGSize(width: 1.08, height: 0.85)
        } else if isAwake {
            return CGSize(width: 1.0, height: 1.0)
        } else {
            let s = 1.0 + breathing * 0.025
            return CGSize(width: s, height: s)
        }
    }

    // ── Torso & tail ─────────────────────────────────────────────────────

    private var torso: some View {
        Ellipse()
            .fill(
                LinearGradient(
                    colors: [Color.brandPurpleSoft.opacity(0.88), Color.brandPurpleSoft.opacity(0.55)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .frame(width: 130, height: 85)
            .overlay(
                // Belly fluff highlight — lighter zone
                Ellipse()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 80, height: 38)
                    .offset(y: 12)
            )
            .offset(y: 55)
    }

    private var tail: some View {
        // Sleeping: very slow dream sway. Awake: active swish.
        let rotation: Double = {
            if isAwake {
                return Double(awakeTailPhase) * 12.0 - 6.0      // ±6°
            } else {
                return Double(sleepTailSway) * 8.0 - 4.0        // ±4°, slower
            }
        }()
        return TailShape()
            .stroke(
                LinearGradient(
                    colors: [Color.brandPurpleSoft, Color.brandPurpleSoft.opacity(0.7)],
                    startPoint: .top, endPoint: .bottom
                ),
                style: StrokeStyle(lineWidth: 14, lineCap: .round)
            )
            .frame(width: 95, height: 95)
            .rotationEffect(.degrees(rotation), anchor: .bottomLeading)
            .offset(x: 45, y: 50)
    }

    // ── Head + ears ──────────────────────────────────────────────────────

    private var head: some View {
        ZStack {
            // Cheek puffs sit just inside the head silhouette — closer
            // spacing so they integrate as cheeks, not separate bumps.
            HStack(spacing: 96) {
                cheekPuff
                cheekPuff
            }
            .offset(y: 16)

            // Main head + inner shadow
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
            .fill(Color.brandPurpleSoft.opacity(0.95))
            .frame(width: 40, height: 36)
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
            mouthAndTongue.offset(y: 24)
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
                ZStack {
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [Color.brandCyan.opacity(0.85), Color.white],
                                center: UnitPoint(x: 0.4, y: 0.4),
                                startRadius: 1,
                                endRadius: 14
                            )
                        )
                        .frame(width: 22, height: 18)
                    // Pupil + catchlight as a group, both drift together for glance.
                    ZStack {
                        Capsule()
                            .fill(Color.black)
                            .frame(width: 4, height: 14)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 3, height: 3)
                            .offset(x: -3, y: -3)
                    }
                    .offset(x: glanceX)
                    Ellipse()
                        .stroke(Color.black.opacity(0.18), lineWidth: 1)
                        .frame(width: 22, height: 18)
                }
                .scaleEffect(x: 1, y: awakeBlink, anchor: .center)
            } else {
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

    private var mouthAndTongue: some View {
        ZStack(alignment: .top) {
            MouthShape()
                .stroke(Color.white.opacity(0.7), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                .frame(width: 18, height: 6)
            // Subtle tongue tip that drops slightly. Only visible when awake.
            Capsule()
                .fill(Color.brandPink.opacity(0.85))
                .frame(width: 6, height: 4 + tongueDrop * 2)
                .offset(y: 4 + tongueDrop * 1.5)
                .opacity(isAwake ? 0.9 : 0)
        }
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

/// Two-stage animation that gives particles a small "gravity arc": they
/// shoot up most of the way during the first 70% of their life, then drift
/// back down ~10pt while fading out. Closer to a physical feel than a
/// straight linear path.
private struct WakeParticleView: View {
    let particle: WakeParticle
    @State private var progress: CGFloat = 0
    @State private var fall: CGFloat = 0
    @State private var alpha: CGFloat = 0

    var body: some View {
        // y curve: rise to endOffset.y * progress, then drift down by `fall`.
        let xPos = particle.endOffset.width * progress
        let yPos = particle.endOffset.height * progress + fall
        return Image(systemName: particle.symbol)
            .font(.system(size: particle.size, weight: .black))
            .foregroundStyle(particle.color)
            .shadow(color: particle.color.opacity(0.5), radius: 6, y: 2)
            .offset(x: xPos, y: yPos)
            .opacity(alpha)
            .scaleEffect(0.5 + progress * 0.8)
            .rotationEffect(.degrees(Double(progress) * 60 - 30))
            .onAppear {
                let delay = max(0, particle.startTime.timeIntervalSinceNow)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    // Quick fade in
                    withAnimation(.easeOut(duration: 0.12)) { alpha = 1 }
                    // Main rise (with most of the travel) over 0.9s easeOut
                    withAnimation(.easeOut(duration: 0.9)) { progress = 1 }
                    // Gentle gravity-style drift + fade over the last 0.6s
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        withAnimation(.easeIn(duration: 0.6)) {
                            fall = 12
                            alpha = 0
                        }
                    }
                }
            }
    }
}
