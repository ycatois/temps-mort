// GÉNÉRÉ par design/build.mjs depuis design/tokens.json — ne pas modifier à la main.
import SwiftUI

enum TmColor {
    /// Fond d'en-tête, texte fort, boutons principaux
    static let navy = Color(red: 0.0784, green: 0.1294, blue: 0.2392)
    /// Pied de page, cadre de la tablette
    static let deep = Color(red: 0.0431, green: 0.0824, blue: 0.1569)
    /// Fond secondaire sur navy (sélecteur, pastilles)
    static let navySoft = Color(red: 0.1412, green: 0.2039, blue: 0.3529)
    /// Liens, surtitres, actions positives
    static let accent = Color(red: 0.1176, green: 0.3569, blue: 0.8392)
    /// Appel à l'action, joueuse au service, bandeau formats
    static let yellow = Color(red: 1.0000, green: 0.8235, blue: 0.2471)
    /// Fond du site et du blog
    static let ground = Color(red: 0.9647, green: 0.9686, blue: 0.9765)
    /// Fond des écrans de l'application
    static let groundApp = Color(red: 0.9294, green: 0.9412, blue: 0.9569)
    /// Cartes
    static let surface = Color(red: 1.0000, green: 1.0000, blue: 1.0000)
    /// Boutons neutres, emplacements d'image
    static let surfaceAlt = Color(red: 0.9020, green: 0.9216, blue: 0.9490)
    /// Bordures
    static let line = Color(red: 0.8275, green: 0.8549, blue: 0.8902)
    /// Séparateurs de tableau
    static let lineSoft = Color(red: 0.8902, green: 0.9098, blue: 0.9373)
    /// Texte courant
    static let text = Color(red: 0.0941, green: 0.1333, blue: 0.2078)
    /// Texte secondaire sur clair
    static let muted = Color(red: 0.3569, green: 0.3961, blue: 0.4667)
    /// Paragraphes de carte
    static let bodyMuted = Color(red: 0.2902, green: 0.3333, blue: 0.4078)
    /// Texte courant sur navy
    static let onNavy = Color(red: 0.8392, green: 0.8863, blue: 0.9608)
    /// Texte secondaire sur navy
    static let onNavyMuted = Color(red: 0.7216, green: 0.7686, blue: 0.8510)
    /// Faute, action destructive
    static let error = Color(red: 0.7608, green: 0.3294, blue: 0.1098)
    /// Terrain
    static let court = Color(red: 0.9373, green: 0.6392, blue: 0.3608)
    /// Zone libre autour du terrain
    static let courtOut = Color(red: 0.1804, green: 0.3529, blue: 0.5843)
    /// Zone dessinée au tableau tactique
    static let zoneAlert = Color(red: 0.8510, green: 0.2118, blue: 0.1686)
}

enum TmRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 18
}

enum TmTouch {
    static let minTarget: CGFloat = 48
    static let primaryTarget: CGFloat = 56
}
