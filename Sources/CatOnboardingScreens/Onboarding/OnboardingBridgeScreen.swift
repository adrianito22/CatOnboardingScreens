// OnboardingBridgeScreen.swift
// CatScan — InteractiveOnboarding
//
// Sits between the reveal/feed teaser and the real AdaptyPaywallView. The job is
// to make the offer feel obvious: "that was a scan from memory — now do it with
// a real photo." Visual style matches the upload buttons in CatScannerView (the
// purple/blue/cyan gradient, dark cards on glass).

import SwiftUI

struct OnboardingBridgeScreen: View {
    @Binding var lang: OnboardingLang
    let dominant: OnboardingTrait
    /// Number of free scans the user gets after the paywall. Defaults to the
    /// app-wide constant — pass a different value (e.g. `profileStore.remainingScans`)
    /// if the entitlement changes per-user.
    var freeScans: Int = AppConstants.Limits.freeTierScans
    var onContinue: () -> Void

    private var freeScansBulletText: String {
        let isPlural = freeScans != 1
        if lang == .es {
            return "\(freeScans) \(isPlural ? "escaneos gratis" : "escaneo gratis") para probarlo"
        } else {
            return "\(freeScans) \(isPlural ? "free scans" : "free scan") to try it out"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            OnboardingTopBar(lang: $lang)
                .padding(.horizontal, 22).padding(.top, 8)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(lang == .es ? "Ahora hazlo de verdad" : "Now do it for real")
                        .font(OnboardingType.micro)
                        .tracking(1.6).foregroundStyle(dominant.color)
                        .padding(.top, 14)

                    Text(lang == .es ? "Eso fue un escaneo de memoria." : "That was a scan from memory.")
                        .font(OnboardingType.display)
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(lang == .es
                         ? "Hazlo con una foto real — la IA lee los ojos, orejas y postura reales de tu gato, no tu descripción."
                         : "Do it with a real photo — the AI reads your cat’s actual eyes, ears and posture, not your description.")
                        .font(OnboardingType.subtitle)
                        .foregroundStyle(OnboardingColors.text2)
                        .fixedSize(horizontal: false, vertical: true)

                    // Memory vs photo before/after preview
                    BridgeMemoryVsPhoto(accent: dominant.color)
                        .frame(height: 220)
                        .padding(.top, 4)

                    VStack(spacing: 8) {
                        bullet(index: 1, text: lang == .es
                               ? "Hasta 3× más nítido con fotos reales"
                               : "Up to 3× sharper readings on real photos",
                               accent: dominant.color)
                        bullet(index: 2, text: lang == .es
                               ? "Dilatación pupilar, ángulo de orejas, postura y mirada"
                               : "Eye dilation, ear angle, posture and gaze",
                               accent: dominant.color)
                        bullet(index: 3, text: freeScansBulletText,
                               accent: dominant.color)
                    }
                }
                .padding(.horizontal, 22)
            }

            PrimaryGradientButton(
                title: lang == .es ? "Probar un escaneo real" : "Try a real scan",
                systemImage: "camera.fill",
                haptic: .bridgeLaunch,
                action: onContinue
            )
            .padding(.horizontal, 22).padding(.bottom, 24)
        }
    }

    @ViewBuilder
    private func bullet(index: Int, text: String, accent: Color) -> some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(OnboardingType.micro)
                .foregroundStyle(accent)
                .frame(width: 22, height: 22)
                .background(RoundedRectangle(cornerRadius: 7).fill(accent.opacity(0.13)))
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(accent.opacity(0.33), lineWidth: 1))
            Text(text)
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

/// Side-by-side: a "MEMORY" card with stripes (representing words) and a
/// "PHOTO" card with the scan line + cat silhouette.
struct BridgeMemoryVsPhoto: View {
    let accent: Color
    @State private var scan: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            memoryCard
            Image(systemName: "arrow.right")
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(accent)
            photoCard
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                scan = true
            }
        }
    }

    private var memoryCard: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(OnboardingColors.card)
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(OnboardingColors.border, lineWidth: 1))

            // Centered visual: chat-bubble icon + 5 abstract "answer" lines —
            // one per onboarding question. Mirrors the visual weight of the
            // PHOTO card (which fills with the actual cat photo).
            VStack(spacing: 10) {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.20))
                VStack(alignment: .leading, spacing: 5) {
                    let widths: [CGFloat] = [70, 50, 80, 45, 62]
                    ForEach(0..<5, id: \.self) { i in
                        Capsule()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: widths[i], height: 5)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(12)

            Text(L("bridge.memoryLabel"))
                .font(.custom("Nunito-Black", size: 8, relativeTo: .caption2))
                .tracking(1.6).foregroundStyle(Color.white.opacity(0.55))
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.top, 8).padding(.leading, 8)
        }
        .frame(maxWidth: .infinity)
    }

    private var photoCard: some View {
        ZStack(alignment: .topLeading) {
            // Real cat photo — the same illustration they just saw in the demo
            // (falls back to an SF Symbol if the asset is missing).
            OnboardingCatImage()

            // Color tint for the dominant trait
            LinearGradient(colors: [accent.opacity(0.20), .clear],
                           startPoint: .topLeading, endPoint: .bottomTrailing)

            // Scan line — confined to the BOTTOM 55% of the card so it never
            // crosses the cat's eyes (those are the focal point and feel like
            // they get "sliced" when the line passes through them).
            GeometryReader { geo in
                let topY    = geo.size.height * 0.45
                let bottomY = geo.size.height - 1.5
                Rectangle()
                    .fill(LinearGradient(colors: [.clear, accent.opacity(0.75), .clear],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(height: 1.5)
                    .shadow(color: accent.opacity(0.75), radius: 5)
                    .offset(y: scan ? bottomY : topY)
            }

            Text(L("bridge.photoLabel"))
                .font(.custom("Nunito-Black", size: 8, relativeTo: .caption2))
                .tracking(1.6).foregroundStyle(accent)
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.top, 8).padding(.leading, 8)
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(accent.opacity(0.5), lineWidth: 1))
    }
}
