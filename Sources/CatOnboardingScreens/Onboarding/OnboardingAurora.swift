// OnboardingAurora.swift
// CatScan — InteractiveOnboarding
//
// "Onboarding Rediseño" (Aurora theme) atmosphere layer, ported from the
// Claude Design handoff. Same screen structure as before — this just reskins
// the background and primary gradient with warmth:
//   • Warmer near-black background (#0A0814) with a purple tint.
//   • A soft radial halo at the top of every screen (3 variants for rhythm).
//   • A barely-there paw-print motif tiled over everything (~2.5% white).
//   • Primary CTA gradient: purple → magenta → pink (instead of purple → blue).

import SwiftUI

// MARK: - Aurora palette

enum Aurora {
    /// Warmer near-black base (#0A0814) — same darkness, purple-tinted so glows
    /// mix without going grey.
    static let bg = Color(red: 0x0A / 255, green: 0x08 / 255, blue: 0x14 / 255)

    static let purple    = Color(red: 0x6B / 255, green: 0x47 / 255, blue: 0xFF / 255) // #6B47FF
    static let magenta   = Color(red: 0xB0 / 255, green: 0x42 / 255, blue: 0xD6 / 255) // #B042D6
    static let pink      = Color(red: 0xFF / 255, green: 0x5F / 255, blue: 0xA0 / 255) // #FF5FA0
    static let purpleSoft = Color(red: 0x94 / 255, green: 0x83 / 255, blue: 0xFF / 255) // #9483FF
    static let cyan      = Color(red: 0x61 / 255, green: 0xD1 / 255, blue: 0xFF / 255) // #61D1FF

    /// Primary CTA / accent gradient — warm purple → magenta → pink.
    static let primary = LinearGradient(
        stops: [
            .init(color: purple,  location: 0.0),
            .init(color: magenta, location: 0.55),
            .init(color: pink,    location: 1.0),
        ],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    /// Progress / selection gradient — soft purple → pink.
    static let soft = LinearGradient(
        colors: [purpleSoft, pink],
        startPoint: .leading, endPoint: .trailing
    )

    /// Pink-ish CTA glow shadow.
    static let ctaShadow = pink.opacity(0.36)
    static let ctaShadow2 = purple.opacity(0.55)
}

// MARK: - Background (halo + paw motif)

struct OnboardingAuroraBackground: View {
    enum Glow { case a, b, c }
    var glow: Glow = .a

    var body: some View {
        ZStack {
            Aurora.bg
            halo
            PawMotif()
        }
        .ignoresSafeArea()
    }

    /// Soft radial bloom anchored just above the top edge. The 3 variants
    /// rotate the hue across the flow to keep a sense of movement.
    private var halo: some View {
        let colors: [Color]
        switch glow {
        case .a: colors = [Color(red: 180/255, green: 110/255, blue: 255/255).opacity(0.32),
                           Aurora.pink.opacity(0.10), .clear]
        case .b: colors = [Color(red: 255/255, green: 120/255, blue: 175/255).opacity(0.34),
                           Aurora.purple.opacity(0.10), .clear]
        case .c: colors = [Aurora.cyan.opacity(0.30),
                           Color(red: 123/255, green: 91/255, blue: 255/255).opacity(0.12), .clear]
        }
        return GeometryReader { geo in
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: colors[0], location: 0.0),
                    .init(color: colors[1], location: 0.42),
                    .init(color: colors[2], location: 0.72),
                ]),
                center: UnitPoint(x: 0.5, y: -0.05),
                startRadius: 0,
                endRadius: geo.size.width * 1.0
            )
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

/// Barely-there tiled paw-print motif (~2.5% white). Pure Canvas, no assets.
private struct PawMotif: View {
    var body: some View {
        Canvas { context, size in
            let tile: CGFloat = 96
            var row = 0
            var y: CGFloat = -tile
            while y < size.height + tile {
                var x: CGFloat = (row % 2 == 0) ? 0 : tile / 2
                while x < size.width + tile {
                    drawPaw(&context, at: CGPoint(x: x, y: y), rotated: (x + y).truncatingRemainder(dividingBy: 3) > 1.5)
                    x += tile
                }
                y += tile
                row += 1
            }
        }
        .opacity(0.025)
        .allowsHitTesting(false)
    }

    private func drawPaw(_ ctx: inout GraphicsContext, at p: CGPoint, rotated: Bool) {
        var path = Path()
        // main pad
        path.addEllipse(in: CGRect(x: p.x + 4, y: p.y + 9, width: 16, height: 20))
        // four toes
        path.addEllipse(in: CGRect(x: p.x - 5, y: p.y + 1, width: 7, height: 10))
        path.addEllipse(in: CGRect(x: p.x + 4, y: p.y - 3, width: 7, height: 10))
        path.addEllipse(in: CGRect(x: p.x + 14, y: p.y - 3, width: 7, height: 10))
        path.addEllipse(in: CGRect(x: p.x + 22, y: p.y + 1, width: 7, height: 10))
        ctx.fill(path, with: .color(.white))
    }
}

// MARK: - Convenience modifier

extension View {
    /// Applies the Aurora onboarding background (warm bg + halo + paw motif)
    /// behind a screen. Use `glow` to vary the halo hue per screen.
    func auroraBackground(_ glow: OnboardingAuroraBackground.Glow = .a) -> some View {
        background(OnboardingAuroraBackground(glow: glow))
    }
}
