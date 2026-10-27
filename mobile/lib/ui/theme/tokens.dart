// GÉNÉRÉ par design/build.mjs depuis design/tokens.json — ne pas modifier à la main.
import 'package:flutter/painting.dart';

abstract final class TmColor {
  /// Fond d'en-tête, texte fort, boutons principaux
  static const navy = Color(0xFF14213D);
  /// Pied de page, cadre de la tablette
  static const deep = Color(0xFF0B1528);
  /// Fond secondaire sur navy (sélecteur, pastilles)
  static const navySoft = Color(0xFF24345A);
  /// Liens, surtitres, actions positives
  static const accent = Color(0xFF1E5BD6);
  /// Appel à l'action, joueuse au service, bandeau formats
  static const yellow = Color(0xFFFFD23F);
  /// Fond du site et du blog
  static const ground = Color(0xFFF6F7F9);
  /// Fond des écrans de l'application
  static const groundApp = Color(0xFFEDF0F4);
  /// Cartes
  static const surface = Color(0xFFFFFFFF);
  /// Boutons neutres, emplacements d'image
  static const surfaceAlt = Color(0xFFE6EBF2);
  /// Bordures
  static const line = Color(0xFFD3DAE3);
  /// Séparateurs de tableau
  static const lineSoft = Color(0xFFE3E8EF);
  /// Texte courant
  static const text = Color(0xFF182235);
  /// Texte secondaire sur clair
  static const muted = Color(0xFF5B6577);
  /// Paragraphes de carte
  static const bodyMuted = Color(0xFF4A5568);
  /// Texte courant sur navy
  static const onNavy = Color(0xFFD6E2F5);
  /// Texte secondaire sur navy
  static const onNavyMuted = Color(0xFFB8C4D9);
  /// Faute, action destructive
  static const error = Color(0xFFC2541C);
  /// Terrain
  static const court = Color(0xFFEFA35C);
  /// Zone libre autour du terrain
  static const courtOut = Color(0xFF2E5A95);
  /// Zone dessinée au tableau tactique
  static const zoneAlert = Color(0xFFD9362B);
}

abstract final class TmRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 18;
}

abstract final class TmTouch {
  static const double minTarget = 48;
  static const double primaryTarget = 56;
}

abstract final class TmFont {
  static const body = 'Barlow';
  static const display = 'BarlowCondensed';
}
