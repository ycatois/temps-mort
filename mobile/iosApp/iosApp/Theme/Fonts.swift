import SwiftUI

/// Polices Barlow embarquées (Fonts/*.ttf, déclarées dans UIAppFonts).
extension Font {
    static func barlow(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .bold, .heavy, .black: name = "Barlow-Bold"
        case .semibold: name = "Barlow-SemiBold"
        case .medium: name = "Barlow-Medium"
        default: name = "Barlow-Regular"
        }
        return .custom(name, size: size)
    }

    static func barlowCondensed(_ size: CGFloat, bold: Bool = true) -> Font {
        .custom(bold ? "BarlowCondensed-Bold" : "BarlowCondensed-SemiBold", size: size)
    }
}
