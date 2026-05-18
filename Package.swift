// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CatOnboardingScreens",
    // iOS 17 is the design target (SwiftUI onChange two-param closure, etc.)
    // macOS 14 is declared so `swift build` works on a Mac host for CI / local
    // compile checks — the view code itself is iOS-only (UIImpactFeedbackGenerator).
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "CatOnboardingScreens", targets: ["CatOnboardingScreens"]),
    ],
    targets: [
        .target(
            name: "CatOnboardingScreens",
            resources: [
                .process("Resources/Fonts"),
            ]
        ),
    ]
)
