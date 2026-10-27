# App mobile native

## Prérequis

| Pour | Il faut |
|---|---|
| Module partagé + Android | JDK 21, Android Studio (dernière version stable) avec le plugin Kotlin Multiplatform. Fonctionne sous Windows, WSL ou Linux. |
| iOS | Un Mac avec Xcode 16 ou plus, `brew install xcodegen`, JDK 21. |
| Publier | Compte Google Play Console (25 $ une fois) et Apple Developer Program (99 $/an), au nom d'Hasteria SASU. |

## Démarrer

```bash
cd mobile
./gradlew :shared:jvmTest                 # tests des règles (rapides, sans émulateur)
./gradlew :androidApp:installDebug        # installe sur la tablette ou le téléphone branché
```

iOS (sur le Mac) :
```bash
cd mobile/iosApp
xcodegen                                  # génère TempsMort.xcodeproj depuis project.yml
open TempsMort.xcodeproj                  # choisir un iPad, Run
```
La phase de build « Compiler le module Kotlin partagé » appelle Gradle et fournit `Shared.framework`.

## Versions

Fixées dans `gradle/libs.versions.toml` (octobre 2026) : AGP 9.4.0 (Gradle 9.6.0), Kotlin 2.3.20, Compose BOM 2026.09.00, compileSdk/targetSdk 36, minSdk 26 (Android 8). Android Studio signale les mises à jour ; les accepter dans une branche dédiée et relancer `/check`.

AGP 9 : le Kotlin est compilé par AGP lui-même (pas de plugin `kotlin-android`) et le module partagé utilise le plugin `com.android.kotlin.multiplatform.library`.

## Ce qui existe

- `shared` : équipes, joueuses, catégories (M7 → vétérans, loisir), formats 6x6/4x4/2x2, mixité, règles paramétrables, moteur de match à événements, statistiques (side-out, break, par rotation, par joueuse), passage au set suivant, 21 tests.
- `androidApp` et `iosApp` : premier écran E05 « Match en direct » sur une équipe de démonstration (celle des maquettes), en disposition tablette et smartphone, branché sur le vrai moteur : saisie joueuse puis action, faute adverse, point adverse, temps mort, annulation, libero, rotation automatique.

## Prochaines étapes (ordre conseillé)

1. Persistance locale des événements (SQLDelight dans `shared`) : V1-TEC-02, V1-MAT-12.
2. Écrans E02 Effectif et E03 Nouveau match, puis E04 Composition (glisser-déposer sur les zones).
3. E06 Remplacement et règle du retour à la place d'origine (V1-MAT-04).
4. E07 Stats, E08 Tactique (dessin au doigt), E09 Temps mort, E10 Résumé + partage image/PDF.
5. Compte coach et synchro (V1-EQU-01, V1-TEC-03).

## Publication

- Android : `./gradlew :androidApp:bundleRelease`, signé avec un keystore conservé hors dépôt (gestionnaire de mots de passe + sauvegarde NAS). Test interne Play Console, puis test fermé avec des coachs.
- iOS : Archive dans Xcode puis TestFlight. Penser aux libellés de confidentialité (« données liées à l'utilisateur » minimales) et à la mention des mineurs dans la fiche.
