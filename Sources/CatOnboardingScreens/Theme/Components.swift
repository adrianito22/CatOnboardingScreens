//
//  Components.swift
//  CatScan — Theme
//
//  Shared building blocks lifted from the redesigned onboarding.
//  Every redesigned screen composes from these so each per-screen
//  patch stays small and the visual vocabulary stays consistent.
//
//  Add this file to the Scanner target; nothing else has to change.
//

import SwiftUI

// MARK: - Eyebrow label
//
// Convention across the app:
//   • inline (next to a value, badge, row eyebrow) — size 10, tracking 1.4
//   • section header / screen eyebrow (the default)  — size 11, tracking 1.6
//   • monumental (VERDICT on the verdict card, etc.) — size 11, tracking 2.0
// Defaults match the section-header case so most callers don't need overrides.
struct Eyebrow: View {
    let text: String
    var size: CGFloat = 11
    var tracking: CGFloat = 1.6
    var color: Color = .textTertiary

    var body: some View {
        Text(text)
            .font(.custom("Nunito-Black", size: size))
            .tracking(tracking)
            .textCase(.uppercase)
            .foregroundStyle(color)
            .accessibilityHidden(true) // decorative eyebrows are read via the title below them
    }
}

// MARK: - Primary CTA — brand gradient pill
// Same proportions as OnboardingComponents.PrimaryGradientButton.
struct PrimaryCTA: View {
    let title: String
    var systemImage: String? = nil
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let s = systemImage {
                    Image(systemName: s).font(.system(size: 16, weight: .bold))
                }
                Text(title).font(.custom("Nunito-Black", size: 17))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(LinearGradient.brand)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .brandPurple.opacity(enabled ? 0.45 : 0), radius: 14, y: 8)
            .opacity(enabled ? 1 : 0.4)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

// MARK: - Ghost CTA — neutral pill
struct GhostCTA: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let s = systemImage {
                    Image(systemName: s).font(.system(size: 14, weight: .bold))
                }
                Text(title).font(.custom("Nunito-Bold", size: 14))
            }
            .foregroundStyle(.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.borderHover, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tertiary text chip — for non-CTA actions ("New scan", "Reset")
struct TertiaryTextButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let s = systemImage {
                    Image(systemName: s).font(.system(size: 11, weight: .bold))
                }
                Text(title).font(.custom("Nunito-Bold", size: 12)).tracking(0.6)
            }
            .foregroundStyle(.textTertiary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - GlowCard — corner-glow card chrome
// Same vocabulary as the meter card in the onboarding reveal:
// translucent fill + radial glow from top-left + accent-tinted border.
struct GlowCard<Content: View>: View {
    let accent: Color
    var radius: CGFloat = 16
    var padding: CGFloat = 16
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(accent.opacity(0.04))

            RadialGradient(
                colors: [accent.opacity(0.14), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 140
            )
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))

            content()
                .padding(padding)
        }
        .overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(accent.opacity(0.18), lineWidth: 1)
        )
    }
}

// MARK: - SectionEyebrow — section header with optional hint
struct SectionEyebrow: View {
    let title: String
    var hint: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Eyebrow(text: title, size: 11, tracking: 1.6)
            if let h = hint {
                Text(h)
                    .font(.custom("Nunito-Medium", size: 11))
                    .foregroundStyle(.textSubtle)
            }
            Spacer()
        }
        .padding(.leading, 4)
        .padding(.bottom, 10)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - BrandRibbonHero — gradient hero with decorative sparkles
// Used at the top of Membership. Drop content() inside; sizing handled by caller.
struct BrandRibbonHero<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient.brand

            // Decorative sparkles — fixed positions, no layout impact.
            GeometryReader { _ in
                Group {
                    Text("✦").font(.system(size: 22)).foregroundStyle(.white.opacity(0.90))
                        .offset(x: 0, y: 0)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(.top, 14)
                        .padding(.trailing, 18)
                    Text("✦").font(.system(size: 14)).foregroundStyle(.white.opacity(0.55))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(.top, 38)
                        .padding(.trailing, 50)
                    Text("🐾").font(.system(size: 14)).foregroundStyle(.white.opacity(0.40))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(.bottom, 18)
                        .padding(.trailing, 28)
                }
                .allowsHitTesting(false)
            }

            content()
                .padding(20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: .brandPurple.opacity(0.45), radius: 18, y: 14)
    }
}

// MARK: - StatusDot — small green/orange/red pulse used in status chips
struct StatusDot: View {
    let color: Color
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 6, height: 6)
            .shadow(color: color.opacity(0.7), radius: 6)
    }
}

// MARK: - TraitBadge
//
// Omitted from the standalone package — depends on `ScanTraitType` from the
// main scanner module. The onboarding renders trait pills inline using
// `OnboardingTrait` directly, so this helper isn't referenced here.
