import 'package:flutter/material.dart';

import 'tokens.dart';

/// Thème Material construit sur les tokens générés (design/tokens.json).
ThemeData buildTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: TmColor.navy,
    onPrimary: Colors.white,
    secondary: TmColor.yellow,
    onSecondary: TmColor.navy,
    tertiary: TmColor.accent,
    onTertiary: Colors.white,
    error: TmColor.error,
    onError: Colors.white,
    surface: TmColor.surface,
    onSurface: TmColor.text,
    outline: TmColor.line,
  );

  const display = TextStyle(fontFamily: TmFont.display, fontWeight: FontWeight.w700, color: TmColor.text);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: TmColor.groundApp,
    fontFamily: TmFont.body,
    appBarTheme: const AppBarTheme(
      backgroundColor: TmColor.navy,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(fontFamily: TmFont.body, fontWeight: FontWeight.w700, fontSize: 20, color: Colors.white),
    ),
    textTheme: const TextTheme(
      displayLarge: display,
      headlineMedium: display,
      titleMedium: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
      bodyLarge: TextStyle(fontSize: 17),
      bodyMedium: TextStyle(fontSize: 15),
      labelLarge: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, TmTouch.primaryTarget),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TmRadius.md)),
        textStyle: const TextStyle(fontFamily: TmFont.body, fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, TmTouch.minTarget),
        foregroundColor: TmColor.navy,
        side: const BorderSide(color: TmColor.navy, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TmRadius.md)),
        textStyle: const TextStyle(fontFamily: TmFont.body, fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
  );
}
