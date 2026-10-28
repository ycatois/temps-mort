# App mobile (Flutter)

Android d'abord, iOS ensuite. Une seule base de code ; le moteur de règles (`lib/domain`) est du Dart pur.

## Prérequis

| Pour | Il faut |
|---|---|
| Développer et tester | Flutter stable (Dart 3.5 ou plus). Sous Windows pour brancher la tablette ; aussi dans WSL si Claude lance les tests depuis WSL |
| Android | Android Studio (SDK Android 36), une tablette ou un téléphone en mode développeur |
| iOS, plus tard | Un Mac avec Xcode, ou un service de compilation en ligne (Codemagic, GitHub Actions macOS) ; compte Apple Developer (99 $/an) |
| Publier sur Google Play | Compte Google Play Console au nom d'Hasteria SASU (25 $ une fois, numéro D-U-N-S) |

## Première mise en route (une fois)

```powershell
cd C:\dev_web\temps-mort\mobile
flutter pub get
powershell -ExecutionPolicy Bypass -File tool\creer-plateformes.ps1
flutter test
flutter run            # tablette branchée en USB
```

Le script crée `android/` et `ios/` avec `flutter create`, fixe l'identifiant définitif `fr.hasteria.tempsmort`, vise Android 16 (API 36, exigé par Google Play) et nomme l'app « Temps Mort ». Commitez ensuite ces dossiers.

## Au quotidien

```bash
flutter analyze        # erreurs et règles de style
flutter test           # moteur (test/domain) et écrans (test/widget)
flutter run            # sur l'appareil branché, rechargement à chaud avec « r »
node ../design/build.mjs   # après une modification du design : régénère lib/ui/theme/tokens.dart et les polices
```

## Organisation

```
mobile/
├── lib/
│   ├── domain/            Dart pur : équipes, catégories, formats, règles, moteur, stats
│   ├── data/              stockage local SQLite (équipes, matchs, événements) et conversion JSON
│   ├── ui/theme/          tokens.dart (GÉNÉRÉ) et thème Material
│   ├── ui/common/         libellés français, cartes, boutons, accès au stockage
│   ├── ui/home/           accueil : les équipes du coach
│   ├── ui/team/           E02 Effectif, fiche joueuse, création d'équipe
│   ├── ui/match_setup/    E03 Nouveau match, composition simple (en attendant E04)
│   ├── ui/match/          écran E05 Match en direct + son contrôleur
│   ├── demo/              équipe de démonstration (celle des maquettes)
│   └── main.dart
├── test/domain/           tests des règles + contrôle « pas de Flutter dans le moteur »
├── test/data/             aller-retour JSON et reprise d'un match depuis SQLite
├── test/widget/           parcours complet et écran de match, en tablette et en smartphone
├── assets/fonts/          Barlow, Barlow Condensed (copiées par design/build.mjs)
└── tool/creer-plateformes.ps1
```

## Ce qui existe

- Moteur : équipes, joueuses, catégories (M7 → vétérans, loisir), formats 6x6/4x4/2x2, mixité, règles paramétrables, match à événements, annulation, set suivant, statistiques (side-out, break, par rotation, par joueuse).
- Stockage sur l'appareil (SQLite) : équipes, matchs, et événements enregistrés après chaque saisie. Un match quitté se reprend au même score.
- Accueil : les équipes, création d'une équipe, équipe de démonstration pour essayer.
- E02 Effectif : ajouter, modifier, archiver et réactiver une joueuse (prénom, numéro, poste, genre si mixte) ; liste des matchs de l'équipe.
- E03 Nouveau match : adversaire, date, heure, domicile ou extérieur, lieu, compétition, format du jour, sets gagnants et points.
- Composition simple : on touche les joueuses dans l'ordre des postes, libero, premier service. L'écran E04 de la maquette (glisser-déposer) la remplacera.
- E05 Match en direct, en tablette et smartphone : joueuse puis action, faute adverse, point adverse, temps mort, annulation, set suivant, libero et rotation automatiques.

## Prochaines étapes (ordre conseillé)

1. E04 Composition de la maquette (glisser-déposer sur les zones), capitaine, système de jeu.
2. E06 Remplacement et règle du retour à la place d'origine (V1-MAT-04).
3. E07 Stats en direct, puis E08 Tactique (dessin au doigt avec `CustomPainter`), E09 Temps mort, E10 Résumé + partage image/PDF.
4. Modifier ou supprimer un match, saison et couleur d'équipe, suppression d'une joueuse sur demande (RGPD).
5. Compte coach et synchro (V1-EQU-01, V1-TEC-03).

## Publication

Google Play : voir le mode d'emploi du studio (section « Publier sur le Google Play Store ») et la commande `/release-mobile`. Le fichier à envoyer se produit avec `flutter build appbundle --release`.
