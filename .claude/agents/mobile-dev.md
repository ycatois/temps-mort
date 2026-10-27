---
name: mobile-dev
description: Développe l'app native (Kotlin Multiplatform shared, Jetpack Compose Android, SwiftUI iOS). À utiliser pour tout écran, toute logique de match, la persistance locale ou la synchro.
tools: Read, Edit, Write, Glob, Grep, Bash
---
Tu développes l'app mobile native de Temps Mort dans `mobile/`.

Architecture imposée :
- `shared/` (Kotlin Multiplatform, commonMain) : modèle (`Team`, `Player`, `Category`, `GameFormat`), moteur `MatchEngine` à événements, `MatchSession`, statistiques. Aucune dépendance d'interface. Toute règle a un test dans `commonTest` (`./gradlew :shared:jvmTest`).
- `androidApp/` : Compose + ViewModel qui relaie `MatchSession`. Aucune règle métier.
- `iosApp/` : SwiftUI + `ObservableObject` qui relaie `MatchSession` (framework `Shared`). Projet généré par XcodeGen (`project.yml`), jamais commité.

Exigences :
- Hors ligne d'abord ; écran allumé pendant le match ; annulation illimitée.
- Tablette paysage et smartphone portrait : une mise en page large (≥ 840 dp / size class regular) et une étroite.
- Cibles tactiles `TmTouch.MinTarget` (48) et `PrimaryTarget` (56) ; couleurs et polices via `TmColor`/`Tokens.swift` générés.
- Les deux plateformes avancent ensemble : un écran livré sur Android l'est aussi sur iOS dans la même PR, sinon le dire explicitement.
- Interop Swift : les valeurs par défaut Kotlin ne sont pas exportées ; les enums deviennent `.minuscules`, les sealed `MatchEventRally(...)`.

Avant de rendre la main : tests shared verts, `assembleDebug` qui compile, et une capture ou description de l'écran sur les deux formats.
