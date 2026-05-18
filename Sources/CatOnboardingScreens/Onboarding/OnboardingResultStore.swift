// OnboardingResultStore.swift
// CatScan — InteractiveOnboarding
//
// Persists the "demo scan" baseline (the result from the onboarding quiz)
// so the rest of the app can reference it later — e.g. to show "your
// welcome scan" in profile, to compare against real photo scans, or to
// re-render the reveal when the user reopens the app pre-purchase.
//
// Keyed by Firebase Auth UID so two accounts on the same device get
// independent saves. Falls back to `.anon` when there's no session yet
// (typical during onboarding, before any sign-in / Apple-anon flow).

import Foundation
import SwiftUI
import Combine

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

struct StoredOnboardingResult: Codable, Equatable {
    var lang: String                       // "en" | "es"
    var dominant: String                   // OnboardingTrait.rawValue
    var topTraits: [TraitEntry]            // top 3, ordered desc
    var confidence: Int                    // 72..99
    var verdict: String                    // localized
    var observation: String                // localized
    var catName: String                    // empty if not provided
    var ageIndex: Int                      // 0=Kitten, 1=Young, 2=Adult, 3=Senior
    var answers: [Int?]                    // raw answer indices (5 entries)
    var savedAt: Date

    struct TraitEntry: Codable, Equatable {
        var key: String      // trait raw value
        var value: Int       // 0..100
        var phrase: String   // scanner-style reading shown on the meter
    }
}

@MainActor
final class OnboardingResultStore: ObservableObject {
    static let shared = OnboardingResultStore()

    @Published private(set) var current: StoredOnboardingResult?

    private let prefix = "catscan.onboarding.result.v1."

    private init() {
        load()
    }

    /// Computes the per-user storage key on each access — that way switching
    /// accounts (sign in / sign out) immediately points at the right slot
    /// without needing the consumer to call anything.
    private var key: String {
        #if canImport(FirebaseAuth)
        let uid = Auth.auth().currentUser?.uid ?? "anon"
        #else
        let uid = "anon"
        #endif
        return prefix + uid
    }

    /// Saves the result for the current user. Pass the raw `OnboardingResult`
    /// and the surrounding inputs — we serialize a slim snapshot.
    func save(result: OnboardingResult,
              lang: OnboardingLang,
              catName: String,
              ageIndex: Int,
              answers: [Int?]) {
        let entries = result.top.map {
            StoredOnboardingResult.TraitEntry(
                key: $0.trait.rawValue,
                value: $0.value,
                phrase: $0.phrase
            )
        }
        let snapshot = StoredOnboardingResult(
            lang: lang.rawValue,
            dominant: result.dominant.rawValue,
            topTraits: entries,
            confidence: result.confidence,
            verdict: result.dominant.verdict(lang),
            observation: result.observation,
            catName: catName,
            ageIndex: ageIndex,
            answers: answers,
            savedAt: Date()
        )
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: key)
        }
        current = snapshot
    }

    /// Reads from disk into `current`. Call on app launch and after sign-in
    /// to pick up the right per-user slot.
    func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(StoredOnboardingResult.self, from: data) else {
            current = nil
            return
        }
        current = decoded
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: key)
        current = nil
    }

    /// Called by ContentView when `authStore.isAuthenticated` flips to true.
    ///
    /// First-time sign-in flow: the user finished the onboarding while still
    /// anonymous, so the demo-scan baseline got written under the `.anon`
    /// storage key. Once Firebase Auth assigns them a real UID, the chip
    /// would start reading from the (empty) `<uid>` slot and the verdict
    /// would vanish from the profile. This copies the `.anon` blob into the
    /// new UID slot the first time we see one.
    ///
    /// Idempotent: if the UID slot already has data we leave it alone
    /// (returning users with cloud data win); if there's nothing under
    /// `.anon` either we no-op.
    func migrateAnonDataIfNeeded() {
        #if canImport(FirebaseAuth)
        let uid = Auth.auth().currentUser?.uid ?? "anon"
        #else
        let uid = "anon"
        #endif
        guard uid != "anon" else { return }

        let uidKey  = prefix + uid
        let anonKey = prefix + "anon"

        guard UserDefaults.standard.data(forKey: uidKey) == nil else { return }
        guard let anonData = UserDefaults.standard.data(forKey: anonKey) else { return }

        UserDefaults.standard.set(anonData, forKey: uidKey)
        UserDefaults.standard.removeObject(forKey: anonKey)

        load()   // refresh `current` so the chip immediately sees the migrated data
    }
}
