---
description: Préparer une version de l'app pour les tests (TestFlight, test interne Play)
argument-hint: <version, ex. 0.2.0>
---
Version : $ARGUMENTS

1. Tests `./gradlew :shared:jvmTest` verts.
2. Mets à jour `versionName`/`versionCode` (androidApp/build.gradle.kts) et `CFBundleShortVersionString`/`CFBundleVersion` (iosApp/project.yml).
3. Rédige les notes de version en français pour les coachs testeurs (3 à 6 puces, sans jargon).
4. Android : `./gradlew :androidApp:bundleRelease` — la signature se fait avec le keystore de Yann (jamais dans le dépôt). Envoi en test interne Play Console par Yann.
5. iOS : sur le Mac, `xcodegen`, puis Xcode > Product > Archive > TestFlight.
6. Commit `chore(release): vX.Y.Z`, tag `app-vX.Y.Z`.
