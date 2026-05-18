// OnboardingComponents.swift
// CatScan — InteractiveOnboarding
//
// Shared building blocks: TopProgressBar (replaces the legacy step chip),
// OptionCard, primary button, etc.
//
// IMPORTANT — TopProgressBar is iPad / Split View safe: it lays out at parent
// width using GeometryReader instead of UIScreen.main.bounds.

import SwiftUI

struct OnboardingColors {
    static let bg       = Color(red: 0.039, green: 0.039, blue: 0.059)        // #0A0A0F
    static let surface  = Color(red: 0.078, green: 0.078, blue: 0.098)        // #141419
    static let card     = Color.white.opacity(0.04)
    static let border   = Color.white.opacity(0.08)
    static let purple   = Color(red: 0.420, green: 0.278, blue: 1.0)          // #6B47FF
    static let blue     = Color(red: 0.141, green: 0.451, blue: 1.0)          // #2473FF
    static let accent   = Color(red: 0.620, green: 0.420, blue: 1.0)          // #9E6BFF
    static let pink     = Color(red: 1.0,    green: 0.373, blue: 0.627)        // #FF5FA0
    static let cyan     = Color(red: 0.380, green: 0.820, blue: 1.0)          // #61D1FF
    static let text2    = Color.white.opacity(0.78)
    static let text3    = Color.white.opacity(0.56)
}

/// Slim brand-gradient progress bar — used at the top of every quiz screen.
/// Replaces the old `stepChip` that used UIScreen.main.bounds.width.
struct TopProgressBar: View {
    let progress: Double          // 0...1
    var accent: Color = OnboardingColors.purple

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.06))
                Capsule()
                    .fill(
                        LinearGradient(colors: [accent, accent.opacity(0.75)],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .shadow(color: accent.opacity(0.55), radius: 8)
                    .frame(width: max(6, geo.size.width * CGFloat(min(max(progress, 0), 1))))
                    .animation(.spring(response: 0.5, dampingFraction: 0.86), value: progress)
            }
        }
        .frame(height: 16)
        .accessibilityElement()
        .accessibilityValue(Text("\(Int(progress * 100)) percent"))
    }
}

struct PrimaryGradientButton: View {
    let title: String
    var systemImage: String? = nil
    var enabled: Bool = true
    /// Optional override — Bridge uses `.bridgeLaunch` for a heavier "leap" feel.
    var haptic: OnboardingHaptics = .primaryTapped
    let action: () -> Void

    var body: some View {
        Button {
            haptic.fire()
            action()
        } label: {
            HStack(spacing: 8) {
                if let s = systemImage { Image(systemName: s).font(.system(size: 16, weight: .bold)) }
                Text(title)
                    .font(.custom("Nunito-Black", size: 17, relativeTo: .headline))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(colors: [OnboardingColors.purple, OnboardingColors.blue],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: OnboardingColors.purple.opacity(enabled ? 0.45 : 0), radius: 14, y: 8)
            .opacity(enabled ? 1 : 0.4)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

struct GhostPill: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button {
            OnboardingHaptics.secondaryTapped.fire()
            action()
        } label: {
            Text(title)
                .font(.custom("Nunito-Bold", size: 13, relativeTo: .footnote))
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal, 14).frame(height: 34)
                .background(Color.white.opacity(0.06))
                .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
                .clipShape(Capsule())
        }.buttonStyle(.plain)
    }
}

struct OptionCard: View {
    let index: Int
    let label: String
    let hint: String
    let selected: Bool
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button {
            // Only fire on a new selection — repeated taps shouldn't buzz.
            if !selected { OnboardingHaptics.optionSelected.fire() }
            action()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(selected ? accent : Color.white.opacity(0.06))
                        .frame(width: 32, height: 32)
                    if selected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(.white)
                    } else {
                        Text(String(UnicodeScalar(65 + index)!))
                            .font(.custom("Nunito-Black", size: 15))
                            .foregroundStyle(.white)
                    }
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text(label)
                        .font(.custom("Nunito-Black", size: 18, relativeTo: .body))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(hint)
                        .font(.custom("Nunito-Medium", size: 15, relativeTo: .footnote))
                        .foregroundStyle(OnboardingColors.text3)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(selected ? accent.opacity(0.13) : OnboardingColors.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(selected ? accent : OnboardingColors.border, lineWidth: 1)
            )
            .shadow(color: selected ? accent.opacity(0.30) : .clear, radius: 16, y: 8)
            .scaleEffect(selected ? 1.01 : 1.0)
            .animation(.spring(response: 0.34, dampingFraction: 0.78), value: selected)
        }
        .buttonStyle(.plain)
    }
}

/// Top bar (language toggle + optional skip). Skip is whitelisted per screen.
struct OnboardingTopBar: View {
    @Binding var lang: OnboardingLang
    var showSkip: Bool = false
    var skipTitle: String = ""
    var onSkip: () -> Void = {}

    var body: some View {
        HStack {
            Button {
                OnboardingHaptics.languageToggled.fire()
                lang = (lang == .en) ? .es : .en
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "globe").font(.system(size: 12, weight: .bold))
                    Text("EN").opacity(lang == .en ? 1 : 0.4)
                    Text("/").opacity(0.3)
                    Text("ES").opacity(lang == .es ? 1 : 0.4)
                }
                .font(.custom("Nunito-Black", size: 11, relativeTo: .caption2))
                .tracking(1.2)
                .foregroundStyle(.white)
                .padding(.horizontal, 11).frame(height: 30)
                .background(Capsule().fill(Color.white.opacity(0.07)))
                .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Spacer()

            if showSkip { GhostPill(title: skipTitle, action: onSkip) }
        }
    }
}
