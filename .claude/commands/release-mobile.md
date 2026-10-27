---
description: Préparer une version de l'app pour les tests (TestFlight, test interne Play)
argument-hint: <version, ex. 0.2.0>
---
Version : $ARGUMENTS

Android d'abord ; iOS viendra plus tard (Mac requis).

1. `cd mobile && flutter analyze && flutter test` : tout doit être vert.
2. Mets à jour `version:` dans `mobile/pubspec.yaml` au format `X.Y.Z+N` : `X.Y.Z` = version affichée, `N` = numéro de build, à augmenter de 1 à chaque envoi sur Google Play.
3. Rédige les notes de version en français pour les coachs testeurs (3 à 6 puces, sans jargon) dans `mobile/notes-de-version/X.Y.Z.txt`.
4. Signature Android : si `android/app/build.gradle.kts` n'a pas encore de `signingConfigs` « release », l'ajouter en lisant uniquement des variables d'environnement (`TM_UPLOAD_STORE_FILE`, `TM_UPLOAD_STORE_PASSWORD`, `TM_UPLOAD_KEY_ALIAS`, `TM_UPLOAD_KEY_PASSWORD`) ; aucun chemin ni mot de passe dans le code. Vérifier `targetSdk = 36` (exigence Google Play depuis le 31 août 2026) et `applicationId = "fr.hasteria.tempsmort"`.
5. `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`. Yann l'envoie dans la Play Console (mode d'emploi, section Google Play).
6. Commit `chore(release): vX.Y.Z`, tag `app-vX.Y.Z`.
