// OnboardingData.swift
// CatScan — InteractiveOnboarding
//
// "Demo scan" strategy: the 5 questions map 1:1 to the cues the real AI reads
// in the photo (eyes → ears → posture → activity → gaze). The reveal looks
// like the real CatScannerView. The paywall handoff says "that was a scan
// from memory — now do it with a real photo."
//
// Tone preserved: playful, irreverent, "tu gato es un pequeño villano adorable".

import SwiftUI

enum OnboardingTrait: String, CaseIterable, Hashable {
    case love, manipulation, coldness, sass, curiosity, chaos

    var localized: (en: String, es: String) {
        switch self {
        case .love:         return ("Love", "Amor")
        case .manipulation: return ("Manipulation", "Manipulación")
        case .coldness:     return ("Coldness", "Frialdad")
        case .sass:         return ("Sass", "Descaro")
        case .curiosity:    return ("Curiosity", "Curiosidad")
        case .chaos:        return ("Chaos", "Caos")
        }
    }

    /// Matches ScanTraitType.color in CatScannerView so the reveal looks identical.
    var color: Color {
        switch self {
        case .love:         return Color(red: 1.00, green: 0.56, blue: 0.68)
        case .manipulation: return Color(red: 0.82, green: 0.42, blue: 1.00)
        case .coldness:     return Color(red: 0.38, green: 0.72, blue: 1.00)
        case .sass:         return Color(red: 1.00, green: 0.42, blue: 0.72)
        case .curiosity:    return Color(red: 0.40, green: 0.85, blue: 0.55)
        case .chaos:        return Color(red: 1.00, green: 0.55, blue: 0.20)
        }
    }

    var emoji: String {
        switch self {
        case .love: return "💕"; case .manipulation: return "🎭"
        case .coldness: return "🧊"; case .sass: return "💅"
        case .curiosity: return "🔍"; case .chaos: return "😈"
        }
    }

    func verdict(_ lang: OnboardingLang) -> String {
        switch (self, lang) {
        case (.love, .en):         return "Secret cuddle plotter"
        case (.love, .es):         return "Conspirador de mimos"
        case (.manipulation, .en): return "Tiny tyrant in fur"
        case (.manipulation, .es): return "Pequeño tirano peludo"
        case (.coldness, .en):     return "Resident ice prince"
        case (.coldness, .es):     return "Príncipe de hielo"
        case (.sass, .en):         return "Drama in four paws"
        case (.sass, .es):         return "Drama en cuatro patas"
        case (.curiosity, .en):    return "Curtain-climbing detective"
        case (.curiosity, .es):    return "Detective trepa-cortinas"
        case (.chaos, .en):        return "Adorable chaos agent"
        case (.chaos, .es):        return "Agente de caos adorable"
        }
    }

    func observation(_ lang: OnboardingLang) -> String {
        switch (self, lang) {
        case (.love, .en):          return "Soft eyes + relaxed posture. Reads warm."
        case (.love, .es):          return "Ojos suaves + postura relajada. Lectura cálida."
        case (.manipulation, .en):  return "Steady stare with intent. Negotiating."
        case (.manipulation, .es):  return "Mirada fija con intención. Negociando."
        case (.coldness, .en):      return "Distant gaze, low activity. Detached."
        case (.coldness, .es):      return "Mirada distante, baja actividad. Desapegado."
        case (.sass, .en):          return "Ears, side-eye and posture all aligned for drama."
        case (.sass, .es):          return "Orejas, side-eye y postura alineados para el drama."
        case (.curiosity, .en):     return "Ears forward, tracking gaze. Investigating."
        case (.curiosity, .es):     return "Orejas adelante, mirada que rastrea. Investigando."
        case (.chaos, .en):         return "Dilated pupils, high activity. About to launch."
        case (.chaos, .es):         return "Pupilas dilatadas, alta actividad. A punto de lanzarse."
        }
    }
}

enum OnboardingLang: String { case en, es

    /// Maps Locale.current to onboarding language. Defaults to .en for anything non-Spanish.
    static var systemDefault: OnboardingLang {
        let code = Locale.current.language.languageCode?.identifier ?? "en"
        return code == "es" ? .es : .en
    }
}

struct OnboardingOption: Identifiable {
    let id = UUID()
    let label: String
    let hint: String
    let weights: [OnboardingTrait: Int]
    /// Phrase shown on the meter when this trait wins because of this question.
    /// Optional — if nil, OnboardingScoring falls back to the trait's default observation.
    let traitPhrase: String?
}

extension OnboardingOption {
    init(label: String, hint: String, weights: [OnboardingTrait: Int]) {
        self.init(label: label, hint: hint, weights: weights, traitPhrase: nil)
    }
}

struct OnboardingQuestion: Identifiable {
    let id = UUID()
    let eyebrow: String        // "Scan 1 — The eyes" / "Escaneo 1 — Los ojos"
    let title: String
    let subtitle: String
    let options: [OnboardingOption]
    /// Accent color for this question (trait-themed for the physical cues).
    let accent: OnboardingTrait
    /// Optional override for the accent color. Used by the non-scoring
    /// emotional/affinity questions so their pink/green trait color doesn't
    /// fight the brand palette — they fall back to brand purple instead.
    let customAccent: Color?

    init(eyebrow: String, title: String, subtitle: String,
         options: [OnboardingOption], accent: OnboardingTrait,
         customAccent: Color? = nil) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.options = options
        self.accent = accent
        self.customAccent = customAccent
    }
}

// MARK: - Question content (EN + ES)
//
// Each question is one of the 5 cues the AI analyzes in the real photo.
// The eyebrow makes that explicit. The reveal then mirrors the real scanner
// so the user understands they just experienced a "demo scan from memory."

enum OnboardingContent {
    static func questions(_ lang: OnboardingLang) -> [OnboardingQuestion] {
        switch lang { case .en: return en; case .es: return es }
    }

    private static let en: [OnboardingQuestion] = [
        OnboardingQuestion(
            eyebrow: "Question 1 — Your love for cats",
            title: "How much of the content you see daily is cats?",
            subtitle: "This tells us what kind of feed fits you.",
            options: [
                .init(label: "Almost all — I live in cat internet",
                      hint: "Your For You Page is 70% cats.",
                      weights: [:]),
                .init(label: "Half — I actively look for it",
                      hint: "You follow accounts, watch reels, laugh.",
                      weights: [:]),
                .init(label: "Some — it shows up sometimes",
                      hint: "Algorithm-fed, not chosen.",
                      weights: [:]),
                .init(label: "Almost none (yet 😅)",
                      hint: "But you opened this app for a reason.",
                      weights: [:]),
            ],
            accent: .love,
            customAccent: .brandPurpleSoft),

        OnboardingQuestion(
            eyebrow: "Question 2 — You and your cat",
            title: "How would you describe your relationship?",
            subtitle: "Your answer matters — we want to understand them with you.",
            options: [
                .init(label: "Best friends, we get each other",
                      hint: "You read them like a book.",
                      weights: [:]),
                .init(label: "I love them but don't always get them",
                      hint: "Sometimes they're a mystery.",
                      weights: [:]),
                .init(label: "Sometimes I feel they hate me 🥲",
                      hint: "Spoiler: probably not.",
                      weights: [:]),
                .init(label: "Still getting to know them",
                      hint: "Every day you learn something.",
                      weights: [:]),
            ],
            accent: .love,
            customAccent: .brandPurpleSoft),

        OnboardingQuestion(
            eyebrow: "Question 3 — What you want to know",
            title: "What would you love to discover about them?",
            subtitle: "The scanner pulls exactly this out.",
            options: [
                .init(label: "How much they actually love me",
                      hint: "Spoiler: probably more than you think.",
                      weights: [:]),
                .init(label: "Whether they're manipulating me",
                      hint: "The answer will surprise you.",
                      weights: [:]),
                .init(label: "What they feel day to day",
                      hint: "Their emotional state, as a percentage.",
                      weights: [:]),
                .init(label: "Their drama and chaos level",
                      hint: "Meet your favorite inner villain.",
                      weights: [:]),
            ],
            accent: .curiosity,
            customAccent: .brandPurpleSoft),

        OnboardingQuestion(
            eyebrow: "Scan 1 — The eyes",
            title: "Look at your cat right now. Their eyes are…",
            subtitle: "This is the first thing the scanner reads.",
            options: [
                .init(label: "Huge — pupils like black holes",
                      hint: "Something is about to be destroyed.",
                      weights: [.chaos: 4, .curiosity: 2]),
                .init(label: "Half-closed, slow-blinking at you",
                      hint: "The famous \"I love you\" blink.",
                      weights: [.love: 4, .coldness: 1]),
                .init(label: "Locked on you. Not blinking. At all.",
                      hint: "A negotiation is happening.",
                      weights: [.manipulation: 4, .coldness: 2]),
                .init(label: "Narrowed into a permanent side-eye",
                      hint: "You did something. You know what you did.",
                      weights: [.sass: 4, .coldness: 2]),
            ],
            accent: .curiosity,
            customAccent: .brandPurpleSoft),

        OnboardingQuestion(
            eyebrow: "Scan 2 — The posture",
            title: "Scan the whole body. The current pose is…",
            subtitle: "How they hold themselves says a lot.",
            options: [
                .init(label: "Perfect loaf, paws tucked under",
                      hint: "Bread has been achieved.",
                      weights: [.coldness: 3, .love: 2]),
                .init(label: "Belly fully exposed, limbs everywhere",
                      hint: "Trust level: dangerously high.",
                      weights: [.love: 4, .chaos: 2]),
                .init(label: "Crouched, butt wiggling, about to launch",
                      hint: "Your ankles are the target.",
                      weights: [.chaos: 4, .curiosity: 2]),
                .init(label: "Sitting tall and stiff, tail wrapped, judging",
                      hint: "Holding court from the couch.",
                      weights: [.sass: 4, .manipulation: 2]),
            ],
            accent: .sass,
            customAccent: .brandPurpleSoft),

        OnboardingQuestion(
            eyebrow: "Scan 3 — Where they look",
            title: "Last one. When you look at them, they’re looking at…",
            subtitle: "Gaze direction is the final clue.",
            options: [
                .init(label: "Right back at you — soft and steady",
                      hint: "You’re the favorite human (today).",
                      weights: [.love: 4, .curiosity: 1]),
                .init(label: "Through you, like you’re furniture",
                      hint: "You exist when food is involved.",
                      weights: [.coldness: 4, .sass: 2]),
                .init(label: "Your hands — tracking every move",
                      hint: "Calculating snack probability.",
                      weights: [.manipulation: 3, .curiosity: 2]),
                .init(label: "Something behind you that isn’t there",
                      hint: "The ghost committee is in session.",
                      weights: [.curiosity: 3, .chaos: 3]),
            ],
            accent: .love,
            customAccent: .brandPurpleSoft),
    ]

    private static let es: [OnboardingQuestion] = [
        OnboardingQuestion(
            eyebrow: "Cuestión 1 — Tu pasión por los gatos",
            title: "¿Cuánto del contenido que ves al día es de gatos?",
            subtitle: "Esto nos dice qué tipo de feed te encaja.",
            options: [
                .init(label: "Casi todo — vivo en internet gatuno",
                      hint: "Tu For You Page tiene 70% michis.",
                      weights: [:]),
                .init(label: "La mitad — los busco activamente",
                      hint: "Sigues cuentas, ves reels, te ríes.",
                      weights: [:]),
                .init(label: "De vez en cuando me pasan algunos",
                      hint: "Llegan por algoritmo, no por gusto.",
                      weights: [:]),
                .init(label: "Casi nada (aún 😅)",
                      hint: "Pero por algo abriste esta app.",
                      weights: [:]),
            ],
            accent: .love,
            customAccent: .brandPurpleSoft),

        OnboardingQuestion(
            eyebrow: "Cuestión 2 — Tu gato y tú",
            title: "¿Cómo describirías tu relación con tu gato?",
            subtitle: "Tu respuesta nos importa, queremos entenderlos juntos.",
            options: [
                .init(label: "Es mi mejor amigo, nos entendemos",
                      hint: "Lo lees como un libro abierto.",
                      weights: [:]),
                .init(label: "Lo amo pero no siempre lo entiendo",
                      hint: "A veces se siente como un misterio.",
                      weights: [:]),
                .init(label: "A veces siento que me odia 🥲",
                      hint: "Spoiler: probablemente no es así.",
                      weights: [:]),
                .init(label: "Aún lo estoy conociendo",
                      hint: "Cada día descubres algo nuevo.",
                      weights: [:]),
            ],
            accent: .love,
            customAccent: .brandPurpleSoft),

        OnboardingQuestion(
            eyebrow: "Cuestión 3 — Lo que quieres saber",
            title: "¿Qué te gustaría descubrir de él?",
            subtitle: "El escáner saca exactamente esto.",
            options: [
                .init(label: "Cuánto me quiere realmente",
                      hint: "Spoiler: probablemente más de lo que crees.",
                      weights: [:]),
                .init(label: "Si me manipula o no",
                      hint: "La respuesta te va a sorprender.",
                      weights: [:]),
                .init(label: "Qué siente día a día",
                      hint: "Su estado emocional en un porcentaje.",
                      weights: [:]),
                .init(label: "Su nivel de drama y caos",
                      hint: "Conoce a tu villano interior favorito.",
                      weights: [:]),
            ],
            accent: .curiosity,
            customAccent: .brandPurpleSoft),

        OnboardingQuestion(
            eyebrow: "Escaneo 1 — Los ojos",
            title: "Mira a tu gato ahora mismo. Sus ojos están…",
            subtitle: "Es lo primero que lee el escáner.",
            options: [
                .init(label: "Enormes — pupilas como agujeros negros",
                      hint: "Algo está a punto de ser destruido.",
                      weights: [.chaos: 4, .curiosity: 2]),
                .init(label: "Entrecerrados, parpadeando lento hacia ti",
                      hint: "El famoso parpadeo de \"te quiero\".",
                      weights: [.love: 4, .coldness: 1]),
                .init(label: "Fijos en ti. Sin parpadear. Para nada.",
                      hint: "Se está negociando algo.",
                      weights: [.manipulation: 4, .coldness: 2]),
                .init(label: "Entrecerrados en un eterno \"side-eye\"",
                      hint: "Hiciste algo. Tú sabes qué.",
                      weights: [.sass: 4, .coldness: 2]),
            ],
            accent: .curiosity,
            customAccent: .brandPurpleSoft),

        OnboardingQuestion(
            eyebrow: "Escaneo 2 — La postura",
            title: "Escanea todo el cuerpo. La pose actual es…",
            subtitle: "Cómo se sostienen dice mucho.",
            options: [
                .init(label: "Pan perfecto, patitas escondidas",
                      hint: "Pan logrado.",
                      weights: [.coldness: 3, .love: 2]),
                .init(label: "Panza totalmente al aire, patas por todos lados",
                      hint: "Confianza: peligrosamente alta.",
                      weights: [.love: 4, .chaos: 2]),
                .init(label: "Agachado, meneando el trasero, a punto de lanzarse",
                      hint: "Tus tobillos son el objetivo.",
                      weights: [.chaos: 4, .curiosity: 2]),
                .init(label: "Sentado erguido y tieso, cola enroscada, juzgando",
                      hint: "Dando audiencia desde el sillón.",
                      weights: [.sass: 4, .manipulation: 2]),
            ],
            accent: .sass,
            customAccent: .brandPurpleSoft),

        OnboardingQuestion(
            eyebrow: "Escaneo 3 — Hacia dónde mira",
            title: "La última. Cuando los miras, ellos miran…",
            subtitle: "La dirección de la mirada es la pista final.",
            options: [
                .init(label: "Directo de vuelta a ti — suave y firme",
                      hint: "Eres el humano favorito (hoy).",
                      weights: [.love: 4, .curiosity: 1]),
                .init(label: "A través de ti, como si fueras un mueble",
                      hint: "Existes cuando hay comida de por medio.",
                      weights: [.coldness: 4, .sass: 2]),
                .init(label: "Tus manos — siguiendo cada movimiento",
                      hint: "Calculando la probabilidad de premio.",
                      weights: [.manipulation: 3, .curiosity: 2]),
                .init(label: "Algo detrás de ti que no existe",
                      hint: "El comité fantasma está reunido.",
                      weights: [.curiosity: 3, .chaos: 3]),
            ],
            accent: .love,
            customAccent: .brandPurpleSoft),
    ]
}

// MARK: - Scoring

struct OnboardingTraitResult {
    let trait: OnboardingTrait
    let value: Int          // 0..100
    let phrase: String      // shown on the meter card
}

struct OnboardingResult {
    let traits: [OnboardingTraitResult]   // sorted desc by value
    let dominant: OnboardingTrait
    let confidence: Int                    // 72..99
    let observation: String                // shown on the verdict card
    var top: [OnboardingTraitResult] { Array(traits.prefix(3)) }
}

enum OnboardingScoring {
    /// answers[i] = selected option index for question i (nil = unanswered, contributes nothing).
    static func compute(questions: [OnboardingQuestion],
                        answers: [Int?],
                        lang: OnboardingLang) -> OnboardingResult {
        var totals: [OnboardingTrait: Int] = Dictionary(uniqueKeysWithValues:
            OnboardingTrait.allCases.map { ($0, 0) })

        // Track which question contributed the most to each trait — its phrase wins.
        var topContributionQ: [OnboardingTrait: Int] = [:]   // value contributed
        var topPhraseSource: [OnboardingTrait: (qIndex: Int, optIndex: Int)] = [:]

        for (qi, q) in questions.enumerated() {
            guard qi < answers.count, let optIdx = answers[qi],
                  optIdx >= 0, optIdx < q.options.count else { continue }
            let opt = q.options[optIdx]
            // Emotional/affinity questions have empty weights and must not affect scoring.
            guard !opt.weights.isEmpty else { continue }
            for (t, w) in opt.weights {
                totals[t, default: 0] += w
                if w > (topContributionQ[t] ?? -1) {
                    topContributionQ[t] = w
                    topPhraseSource[t] = (qi, optIdx)
                }
            }
        }

        let maxValue = max(totals.values.max() ?? 1, 1)
        let normalized = totals.mapValues { Int(28.0 + Double($0) / Double(maxValue) * 64.0) }
        let rankedKV = normalized.sorted { $0.value > $1.value }

        let traits: [OnboardingTraitResult] = rankedKV.map { (t, v) in
            let phrase = phraseFor(t, lang: lang, source: topPhraseSource[t])
            return OnboardingTraitResult(trait: t, value: v, phrase: phrase)
        }
        let dominant = traits.first!.trait
        let confidence = min(99, max(72, traits.first!.value - traits.last!.value + 70))
        return OnboardingResult(
            traits: traits,
            dominant: dominant,
            confidence: confidence,
            observation: dominant.observation(lang)
        )
    }

    /// Skip helper — fill nil answers with a random valid index so the result is
    /// plausible instead of biased to option 0.
    static func fillUnansweredRandomly(_ answers: [Int?], questions: [OnboardingQuestion]) -> [Int?] {
        zip(answers, questions).map { ans, q in
            ans ?? Int.random(in: 0..<q.options.count)
        }
    }

    private static func phraseFor(_ trait: OnboardingTrait,
                                  lang: OnboardingLang,
                                  source: (qIndex: Int, optIndex: Int)?) -> String {
        // Scanner-style readings keyed by (trait, lang). qIndex is ignored now that
        // the questionnaire is hybrid (emotional + physical) and trait→question is no
        // longer 1:1. We pick the most resonant phrase per trait — the eye-cue read.
        switch (trait, lang) {
        case (.love, .en):         return "Slow-blink read confirms warmth."
        case (.love, .es):         return "Parpadeo lento confirma calidez."
        case (.manipulation, .en): return "Unblinking lock — strategic stare."
        case (.manipulation, .es): return "Mirada fija — estrategia activa."
        case (.coldness, .en):     return "Detached stare. Pure indifference."
        case (.coldness, .es):     return "Mirada distante. Indiferencia pura."
        case (.sass, .en):         return "Side-eye detected. Drama in progress."
        case (.sass, .es):         return "Side-eye detectado. Drama en curso."
        case (.curiosity, .en):    return "Wide pupils — investigation mode."
        case (.curiosity, .es):    return "Pupilas anchas — modo investigación."
        case (.chaos, .en):        return "Pupils maxed — chaos imminent."
        case (.chaos, .es):        return "Pupilas al máximo — caos inminente."
        }
    }
}
