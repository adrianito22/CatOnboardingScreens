// OnboardingTypography.swift
// CatScan — InteractiveOnboarding
//
// One source of truth for every font used in the onboarding flow. Before
// this file, sizes ranged across 13 distinct values (8, 9, 10, 11, 12, 13,
// 14, 15, 16, 17, 18, 22, 26, 28) with no clear hierarchy — eyebrows on one
// screen were 11pt, on the next they were 14pt, page titles drifted between
// 26 and 28, etc.
//
// The scale below collapses that into 7 named roles. Every onboarding view
// should pick exactly one of these — no inline `Font.custom(...)` calls
// for body text.

import SwiftUI

enum OnboardingType {
    /// Page hero title — Welcome, question title, bridge, transition, recap.
    /// 28pt Nunito-Black.
    static let display = Font.custom("Nunito-Black", size: 28, relativeTo: .largeTitle)

    /// Within-page headline — dominant trait reveal, recap value etc.
    /// 22pt Nunito-Black.
    static let title = Font.custom("Nunito-Black", size: 22, relativeTo: .title)

    /// Subtitle under a title — descriptive intro paragraph.
    /// 16pt Nunito-Medium.
    static let subtitle = Font.custom("Nunito-Medium", size: 16, relativeTo: .body)

    /// Option-card label — what the user is picking on A/B/C/D rows.
    /// 17pt Nunito-Black.
    static let optionLabel = Font.custom("Nunito-Black", size: 17, relativeTo: .body)

    /// Helper text under an option label, or any descriptive hint.
    /// 14pt Nunito-Medium.
    static let hint = Font.custom("Nunito-Medium", size: 14, relativeTo: .footnote)

    /// Section label / counter / breadcrumb — uppercase, with tracking
    /// applied at the call-site. 14pt Nunito-Black.
    static let eyebrow = Font.custom("Nunito-Black", size: 14, relativeTo: .caption)

    /// Tiny decorative chip / pill — language toggle, "%" pills, tags.
    /// 12pt Nunito-Black. Use tracking at the call-site.
    static let micro = Font.custom("Nunito-Black", size: 12, relativeTo: .caption2)
}
