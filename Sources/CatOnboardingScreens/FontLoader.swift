import SwiftUI
import CoreText

/// Registers the bundled Nunito fonts with CoreText so `.custom("Nunito-…")`
/// resolves without needing the host app's Info.plist to list them.
/// Safe to call multiple times — CT returns false on already-registered fonts.
public enum NunitoFontLoader {
    private static var didRegister = false

    public static func registerIfNeeded() {
        guard !didRegister else { return }
        didRegister = true

        let names = [
            "Nunito-Black",
            "Nunito-Bold",
            "Nunito-Medium",
            "Nunito-Regular",
        ]

        for name in names {
            guard let url = Bundle.module.url(forResource: name, withExtension: "ttf") else { continue }
            var error: Unmanaged<CFError>?
            _ = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
            // Errors here typically mean the font is already registered — fine.
        }
    }
}
