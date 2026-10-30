---
name: volley-rules
description: Règles du volley-ball modélisées dans le moteur Temps Mort (rotation, service, libero, remplacements, sets, 6x6/4x4/2x2, mixité, catégories). À lire avant de modifier mobile/lib/domain ou d'écrire un écran de match.
---
# Règles modélisées

Code : `mobile/lib/domain/` (Dart pur). Tests : `mobile/test/domain/match_engine_test.dart` (`flutter test`).

## Modèle
- Un match = liste de `MatchEvent` : `StartSet`, `Rally`, `Substitution`, `LiberoIn`, `LiberoOut`, `TimeoutTaken`.
- `MatchEngine.check()` renvoie un `Rejection` (raison lisible) ou null ; `apply()` produit le nouvel état ; `replay()` rejoue tout (annulation, reprise, synchro).
- `lineup[0]` = poste 1 (serveur quand l'équipe a le service), puis postes 2, 3, 4, 5, 6.

## Service et rotation
- L'équipe qui gagne l'échange marque le point (rally point).
- Si l'équipe qui reçoit gagne l'échange, elle récupère le service ET tourne d'un cran dans le sens des aiguilles d'une montre : poste 2 → 1, 1 → 6, 6 → 5, 5 → 4, 4 → 3, 3 → 2. Code : `rotate()`.
- `rotation` (R1…Rn) compte les rotations depuis le début du set ; c'est l'axe des stats « par rotation ».
- 4x4 et 2x2 : même logique sur 4 ou 2 postes.

## Sets
- 6x6 par défaut : 3 sets gagnants, 25 points, 5e set à 15, 2 points d'écart.
- 4x4 par défaut : 2 sets gagnants, 25 / 15. 2x2 par défaut : 2 sets gagnants, 21 / 15.
- Tout est paramétrable dans `MatchRules` (les championnats jeunes et tournois diffèrent souvent). Pas de plafond de points par défaut.
- Chaque set commence par un `StartSet` explicite (composition et premier serveur choisis par le coach).

## Remplacements et temps morts
- 6x6 : 6 remplacements par set ; 4x4 : illimités par défaut ; 2x2 : aucun. 2 temps morts par set (1 en 2x2).
- Règle du « couple » (FIVB 15.6), paramètre `MatchRules.pairedSubstitutions` (actif par défaut en 6x6, modifiable dans E03) : une titulaire ne sort qu'une fois par set et ne revient qu'à sa place d'origine, à la place de sa remplaçante ; une remplaçante n'entre qu'une fois par set et seule sa titulaire peut la remplacer. Titulaires = composition du `StartSet` du set ; `MatchState.partnerOf` donne le binôme. Refus : `StarterAlreadyLeft`, `SubstituteAlreadyPlayed`, `OnlyPartnerReturns`, `ReturnToOwnPlace`.
- Matchs enregistrés avant ce paramètre : il vaut `false` à la relecture, pour que leurs remplacements se rejouent.
- Non modélisé pour l'instant : remplacement exceptionnel sur blessure (hors compteur, hors règle du couple).

## Libero (6x6 uniquement)
- Déclaré au `StartSet`, jamais dans la composition de départ.
- Remplace un joueur arrière (postes 1, 6, 5) ; ne compte pas comme remplacement.
- Ne peut pas entrer au poste 1 quand son équipe sert (pas de service libero, règle FIVB ; certaines compétitions FFVB l'autorisent → futur paramètre).
- Sort automatiquement quand la rotation l'amènerait au poste 4.

## Mixité
- `Team.gender == TeamGender.mixte` impose `minWomenOnCourt` (par défaut la moitié des joueurs sur le terrain). Vérifié au `StartSet`, à chaque remplacement et à l'entrée du libero.

## Composition (E04)
- `StartSet` porte aussi `captainId` et `system` (`GameSystem` : 5-1, 4-2, 6-2) : ils décrivent la composition sans changer le jeu.
- `validateLineup` bloque (taille, doublon, libero dans le six, mixité). `lineupWarnings` alerte sans bloquer, en 6x6 seulement : nombre de passeuses (poste `Role.passeur`) différent du système ; en 4-2 et 6-2, passeuses qui ne sont pas opposées (trois postes d'écart) ; joueuse de poste libero placée en zone avant (postes 2, 3, 4).
- Premier service : le coach le choisit au set 1 et au set décisif (tirage au sort) ; il alterne aux autres sets.

## Catégories
- `AgeCategory` : M7 (baby-volley), M9, M11, M13, M15, M18, M21, Seniors, Vétérans, Loisir. `suggestedFormat` n'est qu'une valeur par défaut à la création d'équipe ; le coach choisit le format et les règles.

## Statistiques (`computeStats`)
- Side-out % = échanges gagnés quand l'adversaire sert ; break % = échanges gagnés sur notre service.
- Points par joueuse : ace, attaque, contre gagnants. Fautes : action non « scoring » sur un échange perdu (hors faute adverse).
- Bilan par rotation ; `weakestRotation` alimente le bloc « À retenir » du résumé (E10).

## En cas de doute
Proposer un paramètre plutôt qu'une règle codée en dur, et le signaler à Yann (coach) qui tranche.
