// OnboardingScannerView.swift
// CatScan — InteractiveOnboarding
//
// The "demo scan": a 5.2s scanning animation over the brand cat illustration,
// then a reveal panel styled to MATCH CatScannerView (meter cards, gold ✦
// confidence pill, verdict card with text.quote glyph + observation).
//
// A "FROM MEMORY / DE MEMORIA" badge sits over the visual so the user knows
// this was a scan built from their answers, not a photo — which sets up the
// bridge/paywall handoff ("now do it with a real photo").
//
// scanDuration is SACRED at 5.2 — do not change.

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct OnboardingScannerView: View {
    @Binding var lang: OnboardingLang
    let result: OnboardingResult
    let catName: String?
    let scanDuration: Double          // 5.2 — do not change
    var onContinue: () -> Void

    @State private var scanProgress: CGFloat = 0      // 0...1 vertical scan line
    @State private var stageIndex = 0
    @State private var done = false

    // staggered reveal
    @State private var showMeters: [Bool] = [false, false, false]
    @State private var showPill = false
    @State private var showVerdict = false
    @State private var animatedValues: [Int] = [0, 0, 0]
    @State private var barProgress: [CGFloat] = [0, 0, 0]
    @State private var scanTimer: Timer?
    /// Single cancellable task for the entire staggered reveal — replaces a
    /// chain of un-cancellable DispatchQueue.main.asyncAfter calls.
    @State private var revealTask: Task<Void, Never>?
    /// Idempotency guard so a double onAppear can't launch two timers.
    @State private var didStartScan = false

    private let purpleAccent = Color(red: 0.482, green: 0.431, blue: 0.965) // #7b6ef6
    private let pinkAccent   = Color(red: 1.0,   green: 0.373, blue: 0.627)
    private let goldAccent   = Color(red: 0.957, green: 0.784, blue: 0.259)

    private var stages: [String] {
        lang == .es
        ? ["Leyendo tensión de bigotes",
           "Mapeando dilatación pupilar",
           "Descifrando ángulo de orejas",
           "Cotejando postura y mirada",
           "Compilando matriz de personalidad"]
        : ["Reading whisker tension",
           "Mapping pupil dilation",
           "Decoding ear angle",
           "Cross-checking posture and gaze",
           "Compiling personality matrix"]
    }

    private var titleText: String {
        let name = catName ?? (lang == .es ? "tu gato" : "your cat")
        return lang == .es ? "Perfil emocional de \(name)" : "\(name)’s emotional profile"
    }

    private var visualAccent: Color { done ? result.dominant.color : purpleAccent }

    var body: some View {
        VStack(spacing: 0) {
            OnboardingTopBar(lang: $lang)
                .padding(.horizontal, 22).padding(.top, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    if done {
                        Text(lang == .es ? "ESCANEO DE PRUEBA COMPLETADO" : "DEMO SCAN COMPLETE")
                            .font(OnboardingType.micro)
                            .tracking(1.8)
                            .foregroundStyle(result.dominant.color)
                            .padding(.top, 14)
                        Text(titleText)
                            .font(OnboardingType.title)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                    }

                    scannerVisual
                        .padding(.top, done ? 0 : 24)

                    if !done {
                        Text(stages[min(stageIndex, stages.count - 1)] + "…")
                            .font(OnboardingType.hint)
                            .foregroundStyle(OnboardingColors.text2)
                            .id(stageIndex)
                            .transition(.opacity)
                            .padding(.top, 4)
                    } else {
                        ForEach(Array(result.top.enumerated()), id: \.offset) { i, tr in
                            meterCard(tr, index: i)
                                .opacity(showMeters[i] ? 1 : 0)
                                .offset(y: showMeters[i] ? 0 : 18)
                        }
                        confidencePill
                            .opacity(showPill ? 1 : 0)
                            .offset(y: showPill ? 0 : 18)
                        verdictCard
                            .opacity(showVerdict ? 1 : 0)
                            .offset(y: showVerdict ? 0 : 18)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, done ? 96 : 16)
            }

            if done {
                PrimaryGradientButton(
                    title: lang == .es ? "Guardar perfil" : "Save profile",
                    systemImage: "checkmark",
                    action: onContinue
                )
                .padding(.horizontal, 22).padding(.bottom, 24)
            }
        }
        .onAppear { startScan() }
        .onDisappear {
            scanTimer?.invalidate()
            scanTimer = nil
            revealTask?.cancel()
            revealTask = nil
        }
    }

    // MARK: - Scanner visual

    private var scannerVisual: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.03))

            OnboardingCatImage()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .brightness(done ? 0 : -0.18)
                .saturation(done ? 1.0 : 0.4)
                .animation(.easeInOut(duration: 0.4), value: done)

            cornerBrackets

            if !done {
                GeometryReader { geo in
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(LinearGradient(colors: [.clear, purpleAccent.opacity(0.18)],
                                                 startPoint: .top, endPoint: .bottom))
                            .frame(height: 36)
                        Rectangle()
                            .fill(LinearGradient(colors: [.clear, purpleAccent, pinkAccent, .clear],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(height: 2.5)
                            .shadow(color: purpleAccent.opacity(0.8), radius: 8)
                    }
                    .offset(y: scanProgress * (geo.size.height - 2.5) - 36)
                }
                .clipped()
            }

            VStack {
                HStack {
                    Text(lang == .es ? "DE MEMORIA" : "FROM MEMORY")
                        .font(OnboardingType.micro)
                        .tracking(1.6)
                        .foregroundStyle(.white.opacity(0.92))
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .background(.ultraThinMaterial, in: Capsule())
                    Spacer()
                    if done {
                        Text(L("scanner.scanComplete"))
                            .font(OnboardingType.micro)
                            .tracking(1.4)
                            .foregroundStyle(result.dominant.color)
                            .padding(.horizontal, 9).padding(.vertical, 5)
                            .background(result.dominant.color.opacity(0.18), in: Capsule())
                    }
                }
                Spacer()
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 230)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(visualAccent.opacity(done ? 0.3 : 0.6), lineWidth: 1.4)
        )
        .shadow(color: purpleAccent.opacity(done ? 0 : 0.35), radius: 18)
    }

    private var cornerBrackets: some View {
        GeometryReader { geo in
            let len: CGFloat = 20
            let inset: CGFloat = 8
            let color = visualAccent.opacity(done ? 0.5 : 0.9)
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Path { p in p.move(to: CGPoint(x: inset, y: inset + len)); p.addLine(to: CGPoint(x: inset, y: inset)); p.addLine(to: CGPoint(x: inset + len, y: inset)) }
                    .stroke(color, lineWidth: 2.5)
                Path { p in p.move(to: CGPoint(x: w - inset - len, y: inset)); p.addLine(to: CGPoint(x: w - inset, y: inset)); p.addLine(to: CGPoint(x: w - inset, y: inset + len)) }
                    .stroke(color, lineWidth: 2.5)
                Path { p in p.move(to: CGPoint(x: inset, y: h - inset - len)); p.addLine(to: CGPoint(x: inset, y: h - inset)); p.addLine(to: CGPoint(x: inset + len, y: h - inset)) }
                    .stroke(color, lineWidth: 2.5)
                Path { p in p.move(to: CGPoint(x: w - inset - len, y: h - inset)); p.addLine(to: CGPoint(x: w - inset, y: h - inset)); p.addLine(to: CGPoint(x: w - inset, y: h - inset - len)) }
                    .stroke(color, lineWidth: 2.5)
            }
        }
    }

    // MARK: - Reveal cards (mirrors CatScannerView)

    private func meterCard(_ tr: OnboardingTraitResult, index i: Int) -> some View {
        let color = tr.trait.color
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 8) {
                    Text(tr.trait.emoji).font(.system(size: 18))
                    Text((lang == .es ? tr.trait.localized.es : tr.trait.localized.en).uppercased())
                        .font(.custom("Nunito-Black", size: 11)).tracking(2)
                        .foregroundStyle(.white.opacity(0.55))
                }
                Spacer()
                Text("\(animatedValues[i])%")
                    .font(OnboardingType.display)
                    .foregroundStyle(color)
                    .shadow(color: color.opacity(0.6), radius: 8)
                    .contentTransition(.numericText())
            }
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 5).fill(.white.opacity(0.06)).frame(height: 10)
                GeometryReader { geo in
                    ZStack(alignment: .trailing) {
                        RoundedRectangle(cornerRadius: 5).fill(color)
                            .shadow(color: color.opacity(0.6), radius: 6)
                            .frame(width: max(0, geo.size.width * barProgress[i]), height: 10)
                        if barProgress[i] > 0.05 {
                            Circle().fill(.white).frame(width: 14, height: 14)
                                .shadow(color: color.opacity(0.7), radius: 6)
                                .offset(x: 2)
                                .frame(width: max(0, geo.size.width * barProgress[i]), alignment: .trailing)
                        }
                    }
                }
                .frame(height: 14)
            }
            Text(tr.phrase)
                .font(.custom("Nunito-Medium", size: 12).italic())
                .foregroundStyle(.white.opacity(0.38))
                .lineLimit(2)
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16).fill(color.opacity(0.04))
                RadialGradient(colors: [color.opacity(0.12), .clear],
                               center: .topLeading, startRadius: 0, endRadius: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        )
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.15), lineWidth: 1))
    }

    private var confidencePill: some View {
        HStack(spacing: 6) {
            Text("✦").font(.custom("Nunito-Black", size: 12)).foregroundStyle(goldAccent)
            Text("\(result.confidence)%").font(.custom("Nunito-Black", size: 14)).foregroundStyle(.white)
            Text(lang == .es ? "CONFIANZA" : "CONFIDENCE")
                .font(.custom("Nunito-Black", size: 8)).tracking(1.2)
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(Color.white.opacity(0.06), in: Capsule())
    }

    private var verdictCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "text.quote").font(.system(size: 14, weight: .bold))
                    .foregroundStyle(result.dominant.color)
                Text(lang == .es ? "VEREDICTO" : "VERDICT")
                    .font(.custom("Nunito-Black", size: 11)).tracking(2)
                    .foregroundStyle(.white.opacity(0.55))
            }
            Text("“\(result.dominant.verdict(lang))”")
                .font(.custom("Nunito-Black", size: 18))
                .foregroundStyle(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
            Divider().background(.white.opacity(0.08))
            HStack(spacing: 8) {
                Image(systemName: "eye").font(.system(size: 12, weight: .bold))
                    .foregroundStyle(result.dominant.color.opacity(0.7))
                Text(result.observation)
                    .font(.custom("Nunito-Medium", size: 13).italic())
                    .foregroundStyle(.white.opacity(0.45))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.04))
                RadialGradient(colors: [result.dominant.color.opacity(0.08), .clear],
                               center: .topLeading, startRadius: 0, endRadius: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
        )
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(result.dominant.color.opacity(0.18), lineWidth: 1))
    }

    // MARK: - Animation

    private func startScan() {
        // Idempotency: a double onAppear must not launch two timers.
        guard !didStartScan else { return }
        didStartScan = true

        let start = Date()
        let stageDuration = scanDuration / Double(stages.count)

        // Build the timer manually and add it to the RunLoop in `.common` mode so it
        // keeps firing during scroll/touch tracking (the default `.scheduledTimer`
        // installs in `.default`, which pauses while a finger is on the screen).
        let t = Timer(timeInterval: 1.0 / 60.0, repeats: true) { timer in
            let elapsed = Date().timeIntervalSince(start)
            let p = min(1.0, elapsed / scanDuration)
            scanProgress = CGFloat(p)
            let s = min(stages.count - 1, Int(elapsed / stageDuration))
            if s != stageIndex { withAnimation(.easeInOut(duration: 0.2)) { stageIndex = s } }
            if p >= 1.0 {
                timer.invalidate()
                OnboardingHaptics.scanCompleted.fire()
                OnboardingAnalytics.scanComplete(
                    dominant: result.dominant.rawValue,
                    confidence: result.confidence,
                    lang: lang
                )
                withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) { done = true }
                startRevealTask()
            }
        }
        RunLoop.main.add(t, forMode: .common)
        scanTimer = t
    }

    /// Drives the staggered reveal of the meter cards + pill + verdict.
    /// Everything lives in one cancellable Task — checks `Task.isCancelled`
    /// before each state mutation so leaving the view kills the chain cleanly.
    private func startRevealTask() {
        revealTask?.cancel()
        revealTask = Task { @MainActor in
            let beat: UInt64 = 180_000_000   // 0.18s in nanoseconds
            for i in 0..<min(3, result.top.count) {
                try? await Task.sleep(nanoseconds: beat)
                if Task.isCancelled { return }
                withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                    showMeters[i] = true
                }
                animateMeter(i)
            }
            try? await Task.sleep(nanoseconds: beat)
            if Task.isCancelled { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) { showPill = true }

            try? await Task.sleep(nanoseconds: beat)
            if Task.isCancelled { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) { showVerdict = true }
        }
    }

    /// Animates a single meter's bar + count-up via an inner Task so it can
    /// also be cancelled when the reveal task is cancelled (it's a child).
    private func animateMeter(_ i: Int) {
        guard i < result.top.count else { return }
        let target = result.top[i].value
        withAnimation(.timingCurve(0.22, 1, 0.36, 1, duration: 1.3)) {
            barProgress[i] = CGFloat(target) / 100.0
        }
        Task { @MainActor in
            let steps = 36
            let stepNs: UInt64 = UInt64(1_200_000_000 / steps)   // ~33ms per step
            for s in 0...steps {
                if Task.isCancelled { return }
                animatedValues[i] = Int(Double(target) * Double(s) / Double(steps))
                try? await Task.sleep(nanoseconds: stepNs)
            }
        }
    }
}

#Preview {
    OnboardingScannerView(
        lang: .constant(.es),
        result: OnboardingScoring.compute(
            questions: OnboardingContent.questions(.es),
            answers: [0, 1, 2, 3, 0],
            lang: .es),
        catName: "Michi",
        scanDuration: 5.2,
        onContinue: {}
    )
    .background(OnboardingColors.bg)
}
