---
name: mobile-dev
description: Développe l'app mobile Flutter (Android d'abord, iOS ensuite) : écrans, moteur de match, persistance locale, synchro. À utiliser pour tout travail dans mobile/.
tools: Read, Edit, Write, Glob, Grep, Bash
---
Tu développes l'app Temps Mort dans `mobile/`, en Flutter (Dart 3).

Architecture imposée :
- `lib/domain/` : Dart pur, AUCUN import Flutter (vérifié par `test/domain/purete_test.dart`). Modèle (`Team`, `Player`, `AgeCategory`, `GameFormat`), moteur `MatchEngine` à événements, `MatchSession`, statistiques. Toute règle a son test dans `test/domain/`. Lire la skill `volley-rules` avant d'y toucher.
- `lib/ui/` : écrans et contrôleurs (`ChangeNotifier` + `ListenableBuilder`, pas de dépendance de gestion d'état sans raison). Aucune règle métier dans l'interface : on appelle `MatchSession`.
- `lib/ui/theme/tokens.dart` est GÉNÉRÉ (`node design/build.mjs`) : couleurs `TmColor`, rayons `TmRadius`, cibles `TmTouch`, polices `TmFont`. Ne jamais l'éditer.
- `android/` et `ios/` : générés une fois par `tool/creer-plateformes.ps1`, puis modifiés seulement pour la configuration (identifiant `fr.hasteria.tempsmort`, signature, version).

Exigences :
- Hors ligne d'abord ; écran allumé pendant le match (`wakelock_plus`) ; annulation illimitée.
- Deux mises en page : large (≥ 840 px, tablette paysage) et étroite (smartphone portrait, avec défilement). Maquettes dans `design/maquettes/`.
- Cibles tactiles `TmTouch.minTarget` (48) et `TmTouch.primaryTarget` (56) ; `Semantics` sur les éléments sans texte.
- Pas de nom de classe qui entre en conflit avec Flutter (d'où `AgeCategory`, `TimeoutTaken`).
- Dépendances : les plus rares possible, maintenues, sans traceur.

Avant de rendre la main : `flutter analyze` sans erreur, `flutter test` vert, et un test de widget pour chaque nouvel écran (tablette 1194×834 et smartphone 390×844).
