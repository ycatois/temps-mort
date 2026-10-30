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
│   ├── ui/match_setup/    E03 Nouveau match
│   ├── ui/composition/    E04 Composition (glisser-déposer, libero, capitaine, système, compo type)
│   ├── ui/match/          écran E05 Match en direct, son contrôleur, panneau E06 Remplacement
│   ├── ui/stats/          E07 Statistiques en direct
│   ├── ui/summary/        E10 Résumé du match, PDF détaillé (package pdf) et partage (share_plus)
│   ├── ui/tactics/        E08 Tableau tactique (terrain dessiné avec CustomPainter, outils, bibliothèque)
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
- E01 Accueil : matchs en cours à reprendre et prochains matchs de toutes les équipes (tablette : à gauche, équipes à droite), les équipes avec leur nombre de matchs, création d'une équipe, équipe de démonstration pour essayer.
- E02 Effectif : ajouter, modifier, archiver et réactiver une joueuse (prénom, numéro, poste, genre si mixte) .
- E11 Historique (onglet Matchs de l'équipe) : en cours, à venir (le plus proche d'abord), terminés avec le score des sets. Menu de chaque match : voir le résumé, modifier les informations (E03 pré-rempli ; format et règles verrouillés une fois le match commencé), supprimer après confirmation.
- E03 Nouveau match : adversaire, date, heure, domicile ou extérieur, lieu, compétition, format du jour, sets gagnants et points.
- Joueuses présentes (V1-PRE-03), juste avant la composition : tout l'effectif coché par défaut, 14 au plus en 6x6, assez de joueuses (et de femmes en mixte) pour composer. Banc, composition et remplacements ne proposent que les présentes. Modifiable depuis l'historique ; les joueuses qui ont déjà joué le match restent cochées.
- E04 Composition, pour le premier set et les suivants : glisser-déposer sur les zones (appui long sur smartphone, ou toucher une joueuse puis une zone), libero et second libero, capitaine, système 5-1 / 4-2 / 6-2 avec alertes, premier service (en alternance à partir du set 2, au choix au set décisif), compo type enregistrée et rechargée.
- E05 Match en direct, en tablette et smartphone : joueuse puis action, faute adverse, point adverse, temps mort, annulation, set suivant, rotation automatique. Deux modes de saisie, choisis dans E03 et modifiables en cours de match : simple (l'action qui termine l'échange) ou complète (chaque geste : service, réception de 0 à 3, attaque, contre, défense, passe ; les gestes en jeu ne changent pas le score).
- E06 Remplacement (panneau latéral sur tablette, feuille du bas sur smartphone) : qui sort, qui entre, compteur, retour à la place d'origine (désactivable dans E03), entrée et sortie du libero, changement de libero quand un second est désigné. Les choix impossibles sont grisés avec la raison.
- E07 Statistiques en direct, ouvert depuis le match : side-out, break, origine des points, fautes directes, tableau par joueuse (points, attaques, aces, contres, fautes), points gagnés et perdus par rotation avec la plus faible mise en avant, filtre par set ou match. Smartphone : onglets Joueuses, Rotations, Équipe. Efficacité en attaque et réception moyenne quand la période contient de la saisie complète.
- E08 Tableau tactique, ouvert depuis le match (pions sur la rotation en cours) ou depuis l'équipe (pions sur la compo type) : déplacer les pions au doigt, crayon, flèche et zone en jaune, rouge ou blanc, annuler le dernier trait, tout effacer, adversaires et ballon, demi-terrain ou terrain entier, schémas enregistrés par équipe (enregistrer, rappeler, supprimer). Les schémas de réception pré-construits (V1-TAC-08) restent à faire.
- E09 Temps mort : le bouton « Temps mort » du match enregistre le temps mort et ouvre le tableau tactique avec un chrono de 30 secondes (vibration et « reprise » à la fin) et les trois chiffres du set : side-out, break, fautes directes.
- E10 Résumé du match, depuis le match (bouton « Résumé du match », mis en avant en fin de match) : carte avec score, sets, meilleures joueuses et chiffres clés, « à retenir pour l'entraînement » (rotation la plus forte et la plus faible, fautes de service). Partage par la feuille du téléphone : la carte en image PNG, un PDF détaillé (tableaux par joueuse et par rotation, polices embarquées) et les données brutes en CSV (un événement par ligne, point-virgule, pour un tableur en français).
- Accueil : « Réinitialiser la démonstration » efface les matchs, la compo type et les schémas de l'équipe de démonstration et remet son effectif d'origine.

## Prochaines étapes (ordre conseillé)

1. Schémas de réception pré-construits (V1-TAC-08, à valider avec un coach).
2. Saison et couleur d'équipe, suppression d'une joueuse sur demande (RGPD).
3. Compte coach et synchro (V1-EQU-01, V1-TEC-03).

## Publication

Google Play : voir le mode d'emploi du studio (section « Publier sur le Google Play Store ») et la commande `/release-mobile`. Le fichier à envoyer se produit avec `flutter build appbundle --release`.
