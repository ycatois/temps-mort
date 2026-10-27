---
description: Préparer une version de l'app pour les tests (TestFlight, test interne Play)
argument-hint: <version, ex. 0.2.0>
---
Version : $ARGUMENTS

1. Tests `./gradlew :shared:jvmTest` verts.
2. Mets à jour `versionName`/`versionCode` (androidApp/build.gradle.kts) et `CFBundleShortVersionString`/`CFBundleVersion` (iosApp/project.yml).
3. Rédige les notes de version en français pour les coachs testeurs (3 à 6 puces, sans jargon).
4. Android : si `androidApp/build.gradle.kts` n'a pas encore de `signingConfigs.release`, l'ajouter en lisant uniquement des variables d'environnement (`TM_UPLOAD_STORE_FILE`, `TM_UPLOAD_STORE_PASSWORD`, `TM_UPLOAD_KEY_ALIAS`, `TM_UPLOAD_KEY_PASSWORD`) ; aucun chemin ni mot de passe dans le code. Vérifier `targetSdk` ≥ 36 (exigence Google Play depuis le 31 août 2026). Puis `./gradlew :androidApp:bundleRelease` → `androidApp/build/outputs/bundle/release/app-release.aab`. Yann l'envoie en test interne dans la Play Console (voir le mode d'emploi, section Google Play).
5. iOS : sur le Mac, `xcodegen`, puis Xcode > Product > Archive > TestFlight.
6. Commit `chore(release): vX.Y.Z`, tag `app-vX.Y.Z`.
