// Stubs.swift
// Lightweight stand-ins for app-wide symbols the onboarding references
// in production but that aren't worth pulling in for a design-only package.
//
// In the real app these live in:
//   • Scanner/Config/AppConstants.swift
//   • Scanner/Utilities/AppLanguageManager.swift (the `L(_:)` helper)
//
// Both are reimplemented here with the minimum surface the onboarding uses.

import Foundation

/// Mirror of the production `AppConstants` namespace — only the keys the
/// onboarding actually reads.
enum AppConstants {
    enum Limits {
        /// Free-tier scan budget. Surfaced on the bridge screen to set up
        /// the paywall ("you get 3 free scans before subscribing").
        static let freeTierScans: Int = 3
    }
}

/// Global localization helper. In production this dispatches to a much
/// richer string table keyed by `AppLanguageManager.shared.current`.
/// Here it just returns the key — designers can replace literals in the
/// view code directly if they need different copy.
func L(_ key: String) -> String { key }
func L(_ key: String, _ args: CVarArg...) -> String {
    String(format: key, arguments: args)
}
