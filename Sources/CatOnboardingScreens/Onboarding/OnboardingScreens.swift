// OnboardingScreens.swift
// CatScan — InteractiveOnboarding
//
// Welcome, QuestionScreen, NameSaveScreen (post-reveal), FeedScreen (post-reveal).
//
// CHANGES VS LEGACY:
//   • Profile photo upload REMOVED. Only the name (optional) + age are collected,
//     and they live on a new "NameSaveScreen" after the scanner reveal — framed
//     as "Name this troublemaker" to save the profile.
//   • Old step chip (UIScreen.main.bounds, 0.06 opacity) replaced by TopProgressBar
//     at the top of every QuestionScreen.

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Welcome

struct OnboardingWelcomeScreen: View {
    @Binding var lang: OnboardingLang
    var onStart: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Pinned top bar — must never be pushed off-screen by tall content,
            // otherwise its EN/ES toggle stops receiving taps.
            OnboardingTopBar(lang: $lang)
                .padding(.horizontal, 22).padding(.top, 8)

            // Scrollable middle: centers when it fits, scrolls when it doesn't.
            GeometryReader { geo in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 16)

                        VStack(spacing: 18) {
                            // Brand chip — fills the top area & gives an anchor
                            HStack(spacing: 10) {
                                Image(systemName: "pawprint.fill")
                                    .font(.system(size: 15, weight: .black))
                                    .foregroundStyle(.white)
                                    .frame(width: 30, height: 30)
                                    .background(
                                        LinearGradient(colors: [OnboardingColors.purple, OnboardingColors.blue],
                                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    )
                                    .shadow(color: OnboardingColors.purple.opacity(0.5), radius: 8, y: 3)
                                Text("CatScan")
                                    .font(OnboardingType.title)
                                    .tracking(-0.3)
                                    .foregroundStyle(.white)
                                Text(lang == .es ? "POR IA" : "AI-POWERED")
                                    .font(OnboardingType.micro)
                                    .tracking(1.4)
                                    .foregroundStyle(OnboardingColors.cyan)
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(OnboardingColors.cyan.opacity(0.15), in: Capsule())
                                    .overlay(Capsule().stroke(OnboardingColors.cyan.opacity(0.3), lineWidth: 1))
                            }

                            OnboardingHeroVisual(height: 260)

                            VStack(spacing: 10) {
                                Text(lang == .es ? "Descifra la mente oculta de tu gato."
                                                 : "Decode the hidden mind of your cat.")
                                    .font(OnboardingType.display)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.white)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(lang == .es
                                     ? "Un escaneo emocional de 60 segundos. Cinco escenas que ya conoces — tu gato decide el resto."
                                     : "A 60-second emotional scan. Five scenes you already know — your cat decides the rest.")
                                    .font(OnboardingType.subtitle)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(OnboardingColors.text2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.horizontal, 6)
                        }
                        .padding(.horizontal, 22)

                        Spacer(minLength: 16)
                    }
                    .frame(minHeight: geo.size.height)
                }
            }

            // Pinned footer
            VStack(spacing: 10) {
                PrimaryGradientButton(
                    title: lang == .es ? "Comenzar" : "Get started",
                    systemImage: "arrow.right",
                    action: onStart
                )
                Text(lang == .es
                     ? "Responder las preguntas no te toma más de 2 minutos."
                     : "Answering the questions takes no more than 2 minutes.")
                    .font(OnboardingType.micro)
                    .foregroundStyle(OnboardingColors.text3)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 22)
            .padding(.top, 8)
        }
    }
}

// MARK: - Question

struct OnboardingQuestionScreen: View {
    @Binding var lang: OnboardingLang
    let question: OnboardingQuestion
    let qIndex: Int
    let qTotal: Int
    @Binding var selected: Int?
    var onNext: () -> Void

    private var progress: Double {
        let answered = selected != nil ? 1.0 : 0.4
        return (Double(qIndex) + answered) / Double(qTotal)
    }
    private var accentColor: Color { question.customAccent ?? question.accent.color }

    var body: some View {
        VStack(spacing: 0) {
            // ── Header
            VStack(spacing: 10) {
                OnboardingTopBar(lang: $lang)
                TopProgressBar(progress: progress, accent: accentColor)
                HStack {
                    Text(question.eyebrow)
                        .font(OnboardingType.eyebrow)
                        .tracking(1.2).foregroundStyle(accentColor)
                    Spacer()
                    Text(lang == .es
                         ? "Escaneo \(qIndex + 1) / \(qTotal)"
                         : "Scan \(qIndex + 1) / \(qTotal)")
                        .font(OnboardingType.eyebrow)
                        .tracking(0.8)
                        .foregroundStyle(accentColor.opacity(0.85))
                }
            }
            .padding(.horizontal, 22).padding(.top, 8)

            // ── Body
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(question.title)
                        .font(OnboardingType.display)
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 16)
                    Text(question.subtitle)
                        .font(OnboardingType.subtitle)
                        .foregroundStyle(OnboardingColors.text2)
                        .fixedSize(horizontal: false, vertical: true)
                    VStack(spacing: 10) {
                        ForEach(Array(question.options.enumerated()), id: \.offset) { i, opt in
                            OptionCard(
                                index: i, label: opt.label, hint: opt.hint,
                                selected: selected == i, accent: accentColor,
                                action: {
                                    let isNew = selected != i
                                    selected = i
                                    if isNew {
                                        OnboardingAnalytics.questionAnswered(
                                            qIndex: qIndex, optionIndex: i, lang: lang)
                                    }
                                }
                            )
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .padding(.top, 2)
                }
                .padding(.horizontal, 22).padding(.bottom, 8)
            }

            // ── Footer
            PrimaryGradientButton(
                title: lang == .es ? "Continuar" : "Continue",
                systemImage: "arrow.right",
                enabled: selected != nil,
                action: onNext
            )
            .padding(.horizontal, 22).padding(.bottom, 24)
        }
    }
}

// MARK: - Name & save (post-reveal)

struct OnboardingNameSaveScreen: View {
    @Binding var lang: OnboardingLang
    @Binding var name: String
    /// nil until the user picks an age. Avoids pre-selecting "Young" silently.
    @Binding var ageIndex: Int?
    let dominant: OnboardingTrait
    var onSave: () -> Void

    private var ageOptions: [String] {
        lang == .es ? ["Gatito","Joven","Adulto","Senior"]
                    : ["Kitten","Young","Adult","Senior"]
    }

    var body: some View {
        VStack(spacing: 0) {
            OnboardingTopBar(lang: $lang)
                .padding(.horizontal, 22).padding(.top, 8)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    // Result chip — continuity with the reveal they just saw
                    HStack(spacing: 10) {
                        Text(dominant.emoji).font(.system(size: 22))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(lang == .es ? "TU GATO ES…" : "YOUR CAT IS…")
                                .font(OnboardingType.micro)
                                .tracking(1.4)
                                .foregroundStyle(OnboardingColors.text3)
                            Text("\u{201C}\(dominant.verdict(lang))\u{201D}")
                                .font(OnboardingType.eyebrow)
                                .foregroundStyle(.white)
                                .lineLimit(2)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(dominant.color.opacity(0.10))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(dominant.color.opacity(0.4), lineWidth: 1)
                    )
                    .padding(.top, 14)

                    Text(lang == .es ? "Guarda tu escaneo" : "Save your scan")
                        .font(OnboardingType.micro)
                        .tracking(1.6).foregroundStyle(dominant.color)
                        .padding(.top, 4)

                    Text(lang == .es ? "Ponle nombre al revoltoso."
                                     : "Name this troublemaker.")
                        .font(OnboardingType.display)
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(lang == .es ? "Guardaremos el reporte bajo su nombre."
                                     : "We’ll save the report under their name.")
                        .font(OnboardingType.subtitle)
                        .foregroundStyle(OnboardingColors.text2)
                        .fixedSize(horizontal: false, vertical: true)

                    // Name (optional)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(lang == .es ? "NOMBRE DEL GATO (OPCIONAL)" : "CAT’S NAME (OPTIONAL)")
                            .font(OnboardingType.micro)
                            .tracking(1.2)
                            .foregroundStyle(OnboardingColors.text3)
                        TextField(
                            lang == .es ? "ej. Michi" : "e.g. Whiskers",
                            text: $name
                        )
                        .font(OnboardingType.subtitle)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14).frame(height: 48)
                        .background(RoundedRectangle(cornerRadius: 14).fill(OnboardingColors.card))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(name.isEmpty ? OnboardingColors.border
                                                     : dominant.color.opacity(0.55),
                                        lineWidth: 1)
                        )
                    }

                    // Age (4 chips)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(lang == .es ? "EDAD" : "AGE")
                            .font(OnboardingType.micro)
                            .tracking(1.2)
                            .foregroundStyle(OnboardingColors.text3)
                        HStack(spacing: 6) {
                            ForEach(Array(ageOptions.enumerated()), id: \.offset) { i, label in
                                let active = ageIndex == i
                                Button {
                                    if !active { OnboardingHaptics.optionSelected.fire() }
                                    ageIndex = i
                                } label: {
                                    Text(label)
                                        .font(OnboardingType.micro)
                                        .foregroundStyle(active ? .white : OnboardingColors.text2)
                                        .frame(maxWidth: .infinity).frame(height: 42)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(active ? dominant.color.opacity(0.18) : OnboardingColors.card)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(active ? dominant.color.opacity(0.6) : OnboardingColors.border,
                                                        lineWidth: 1)
                                        )
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 22)
            }

            PrimaryGradientButton(
                title: lang == .es ? "Guardar perfil" : "Save profile",
                systemImage: "checkmark",
                action: onSave
            )
            .padding(.horizontal, 22).padding(.bottom, 24)
        }
    }
}

// MARK: - Feed teaser (post-reveal, pre-paywall)

struct OnboardingFeedScreen: View {
    @Binding var lang: OnboardingLang
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            OnboardingTopBar(lang: $lang)
                .padding(.horizontal, 22).padding(.top, 8)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    Text(lang == .es ? "Feed de la comunidad" : "Community feed")
                        .font(OnboardingType.micro)
                        .tracking(1.6).foregroundStyle(OnboardingColors.pink)
                        .padding(.top, 14)
                    Text(lang == .es
                         ? "Mira a otros gatos siendo igual de descontrolados."
                         : "See other cats being equally unhinged.")
                        .font(OnboardingType.display)
                        .foregroundStyle(.white)
                    Text(lang == .es
                         ? "Fotos y videos solo de gatos. Comparte tus escaneos, reacciona al caos."
                         : "Photos and videos of cats only. Share your scans, react to the chaos.")
                        .font(OnboardingType.subtitle)
                        .foregroundStyle(OnboardingColors.text2)

                    OnboardingFeedMosaic()
                        .frame(height: 220)

                    VStack(spacing: 8) {
                        feedBullet(icon: "pawprint.fill",
                                   label: lang == .es ? "Gatos reales de dueños reales"
                                                      : "Real cats from real owners")
                        feedBullet(icon: "camera.fill",
                                   label: lang == .es ? "Fotos y videos cortos — solo gatos"
                                                      : "Photos and short videos — cats only")
                        feedBullet(icon: "sparkles",
                                   label: lang == .es ? "Reacciones, comentarios y rachas diarias"
                                                      : "Reactions, comments and daily streaks")
                    }
                }
                .padding(.horizontal, 22)
            }

            PrimaryGradientButton(
                title: lang == .es ? "Llévame al feed" : "Take me to the feed",
                systemImage: "arrow.right",
                action: onContinue
            )
            .padding(.horizontal, 22).padding(.bottom, 24)
        }
    }

    @ViewBuilder
    private func feedBullet(icon: String, label: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(LinearGradient(colors: [OnboardingColors.purple, OnboardingColors.blue],
                                          startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
            Text(label)
                .font(OnboardingType.eyebrow)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12).padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 14).fill(OnboardingColors.card))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(OnboardingColors.border, lineWidth: 1))
    }
}

// MARK: - Brand cat image with SF Symbol fallback
//
// Wraps `Image("onboarding_cat_scan")` so that if the asset is missing
// (broken bundle, previews without the asset catalog, etc.) we fall back
// to an SF Symbol instead of an invisible 0×0 view. Keeps `#Preview`
// renders sane and avoids "ghost" hero/scanner cards in production.
struct OnboardingCatImage: View {
    var body: some View {
        if UIImage(named: "onboarding_cat_scan") != nil {
            Image("onboarding_cat_scan")
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Color.white.opacity(0.04)
                Image(systemName: "cat.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(36)
                    .foregroundStyle(OnboardingColors.text2)
            }
        }
    }
}

// MARK: - Welcome hero (scanner mock over the brand cat)

struct OnboardingHeroVisual: View {
    var height: CGFloat = 230
    @State private var scan = false
    private let purple = OnboardingColors.purple
    private let pink   = OnboardingColors.pink

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.03))

            OnboardingCatImage()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .clipped()   // clip the scaledToFill overflow so its hit-area can't cover the EN/ES toggle above

            // bottom fade
            LinearGradient(colors: [.clear, OnboardingColors.bg.opacity(0.55)],
                           startPoint: .center, endPoint: .bottom)

            cornerBrackets(color: purple.opacity(0.85))

            // continuous scan line
            Rectangle()
                .fill(LinearGradient(colors: [.clear, purple, pink, .clear],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(height: 2.5)
                .shadow(color: purple.opacity(0.8), radius: 8)
                .offset(y: scan ? height / 2 - 2.5 : -height / 2)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(purple.opacity(0.4), lineWidth: 1))
        .shadow(color: purple.opacity(0.3), radius: 18)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) { scan = true }
        }
    }

    private func cornerBrackets(color: Color) -> some View {
        GeometryReader { geo in
            let len: CGFloat = 20, inset: CGFloat = 10
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Path { p in p.move(to: CGPoint(x: inset, y: inset + len)); p.addLine(to: CGPoint(x: inset, y: inset)); p.addLine(to: CGPoint(x: inset + len, y: inset)) }.stroke(color, lineWidth: 2.5)
                Path { p in p.move(to: CGPoint(x: w - inset - len, y: inset)); p.addLine(to: CGPoint(x: w - inset, y: inset)); p.addLine(to: CGPoint(x: w - inset, y: inset + len)) }.stroke(color, lineWidth: 2.5)
                Path { p in p.move(to: CGPoint(x: inset, y: h - inset - len)); p.addLine(to: CGPoint(x: inset, y: h - inset)); p.addLine(to: CGPoint(x: inset + len, y: h - inset)) }.stroke(color, lineWidth: 2.5)
                Path { p in p.move(to: CGPoint(x: w - inset - len, y: h - inset)); p.addLine(to: CGPoint(x: w - inset, y: h - inset)); p.addLine(to: CGPoint(x: w - inset, y: h - inset - len)) }.stroke(color, lineWidth: 2.5)
            }
        }
    }
}

// MARK: - Feed mosaic preview (colored tiles in trait colors)

struct OnboardingFeedMosaic: View {
    private let cols = 3

    /// Deterministic tile spec — fixed counts and varied icons so the mosaic
    /// looks like a real feed snapshot, not a synthetic grid. Order is
    /// row-major (top-left → bottom-right). Tile (0,1) is the BIG one.
    private struct TileSpec {
        let trait: OnboardingTrait
        let icon: String
        let count: String
        let big: Bool
        /// Real cat photo asset for this tile. Falls back to the paw
        /// placeholder when the asset isn't in the bundle yet.
        let asset: String
        /// Optional looping video Data Set — when present and resolvable it
        /// plays in place of the photo (the Curiosity tile is a video post).
        var videoAsset: String? = nil
    }
    private let specs: [TileSpec] = [
        .init(trait: .love,         icon: "heart.fill",    count: "128",  big: false, asset: "feed_love"),
        .init(trait: .curiosity,    icon: "play.fill",     count: "0:12", big: true,  asset: "feed_curiosity", videoAsset: "feed_curiosity_video"),
        .init(trait: .sass,         icon: "message.fill",  count: "56",   big: false, asset: "feed_sass"),
        .init(trait: .chaos,        icon: "eye.fill",      count: "312",  big: false, asset: "feed_chaos"),
        .init(trait: .manipulation, icon: "flame.fill",    count: "21",   big: false, asset: "feed_manipulation"),
        .init(trait: .coldness,     icon: "bookmark.fill", count: "87",   big: false, asset: "feed_coldness"),
    ]

    /// Whether a real photo asset exists for this tile yet.
    private func hasAsset(_ name: String) -> Bool {
        #if canImport(UIKit)
        return UIImage(named: name) != nil
        #else
        return false
        #endif
    }

    var body: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 6
            let w = (geo.size.width - spacing * CGFloat(cols - 1)) / CGFloat(cols)
            let h = (geo.size.height - spacing) / 2
            VStack(spacing: spacing) {
                ForEach(0..<2, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(0..<cols, id: \.self) { col in
                            let spec = specs[row * cols + col]
                            tile(spec, width: w, height: h)
                        }
                    }
                }
            }
        }
    }

    /// Resolves a tile's looping video URL, if it has one bundled.
    private func videoURL(_ spec: TileSpec) -> URL? {
        guard let v = spec.videoAsset else { return nil }
        return OnboardingFeedVideo.url(asset: v)
    }

    @ViewBuilder
    private func tile(_ spec: TileSpec, width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            if let vURL = videoURL(spec) {
                videoLayer(url: vURL, width: width, height: height)
            } else if hasAsset(spec.asset) {
                // Real cat photo, filling the tile, with a bottom scrim so the
                // engagement count stays legible.
                Image(spec.asset)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
                    .overlay(
                        LinearGradient(colors: [.clear, .black.opacity(0.45)],
                                       startPoint: .center, endPoint: .bottom)
                    )
            } else {
                // Placeholder: trait-colored gradient + paw glyph.
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(LinearGradient(colors: [spec.trait.color.opacity(0.45),
                                                  spec.trait.color.opacity(0.12)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                Image(systemName: "pawprint.fill")
                    .font(.system(size: spec.big ? 26 : 18, weight: .regular))
                    .foregroundStyle(.white.opacity(0.85))
            }
            VStack {
                Spacer()
                HStack {
                    Image(systemName: spec.icon)
                        .font(.system(size: 8, weight: .bold))
                    Text(spec.count)
                        .font(.custom("Nunito-Black", size: 8))
                    Spacer()
                }
                .foregroundStyle(.white.opacity(0.95))
                .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
                .padding(6)
            }
        }
        .frame(width: width, height: height)
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(.white.opacity(0.1), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private func videoLayer(url: URL, width: CGFloat, height: CGFloat) -> some View {
        #if canImport(UIKit)
        LoopingVideoTile(url: url)
            .frame(width: width, height: height)
            .clipped()
            .overlay(
                LinearGradient(colors: [.clear, .black.opacity(0.45)],
                               startPoint: .center, endPoint: .bottom)
            )
        #else
        Color.clear
        #endif
    }
}
