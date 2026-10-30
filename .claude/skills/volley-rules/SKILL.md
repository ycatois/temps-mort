---
name: volley-rules
description: Règles du volley-ball modélisées dans le moteur Temps Mort (rotation, service, libero, remplacements, sets, 6x6/4x4/2x2, mixité, catégories). À lire avant de modifier mobile/lib/domain ou d'écrire un écran de match.
---
# Règles modélisées

Code : `mobile/lib/domain/` (Dart pur). Tests : `mobile/test/domain/match_engine_test.dart` (`flutter test`).

## Modèle
- Un match = liste de `MatchEvent` : `StartSet`, `Rally`, `Substitution`, `LiberoIn`, `LiberoOut`, `TimeoutTaken`, `Touch`.
- `Touch` (saisie complète) : geste en jeu d'une joueuse sur le terrain (`TouchKind` : service en jeu, réception 3/2/1, attaque en jeu, contre touché, défense réussie). Il ne change ni score ni rotation ; il est gardé dans `MatchState.touches`. Les gestes qui terminent l'échange restent des `Rally` (réception ratée = réception notée 0).
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
- Second libero (`StartSet.secondLiberoId`) : sur le banc, jamais dans la composition, jamais remplaçant. `LiberoSwap` échange les deux liberos (sur le terrain si le libero y est, sinon pour les prochaines entrées), sans compter de remplacement. Volontairement non contrôlé (décision de Yann, 2026-10-30, app pour amateurs et loisir) : l'échange de jeu obligatoire entre deux changements de libero.

## Joueuses présentes (`validateSquad`, `Team.withSquad`)
- 14 au plus en 6x6, liberos compris (`maxSquad`) ; pas de limite connue en 4x4 et 2x2. Assez de joueuses pour le terrain, et de femmes en mixte.
- L'équipe du match est réduite aux présentes (`MatchRecord.teamFor`) : le moteur ne voit pas les absentes. `playersInvolved` donne les joueuses déjà apparues, qu'on ne peut plus retirer.
- Volontairement libre (décision de Yann, 2026-10-30) : FIVB impose deux liberos au-delà de 12 inscrites ; l'app ne l'impose pas.

## Esprit des règles
L'app vise les clubs amateurs et le loisir, pas le haut niveau : une règle FIVB stricte qui gênerait un championnat jeunes ou loisir n'est pas imposée, ou devient un paramètre désactivable. En cas de doute, demander à Yann.

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
- Bilan par rotation ; `weakestRotation` alimente le bloc « À retenir » du résumé (E10) et l'écran E07.
- `byPlayer` (`PlayerStats` : aces, attaques, contres gagnants ; fautes de service, d'attaque, de réception, autres). Une action gagnante n'est créditée que sur un point gagné, une faute que sur un point perdu.
- `origin` (`PointOrigin`) : points marqués, fautes adverses, sans détail ; `teamErrors` compte aussi les fautes saisies sans joueuse.
- Efficacité en attaque = (points − fautes et contrées) / tentatives, tentatives = points + fautes + attaques en jeu. Réception moyenne sur 0 à 3. Elles n'ont de sens que si la période contient des `Touch` (`MatchStats.fullInput`) : en saisie simple, les attaques en jeu manquent, ne pas les estimer.

## Résumé du match (`summarize`, E10)
- Meilleures joueuses : points, contres, aces ; réception seulement en saisie complète, avec au moins `minReceptionsForBest` réceptions. Égalité : moins de fautes, puis le plus petit numéro.
- À retenir : rotation au meilleur solde positif, rotation au pire solde (`weakestRotation`), fautes de service avec le set qui se détache (cité seulement s'il y a plusieurs sets concernés et pas d'égalité).
- Le texte est écrit par l'écran (`ui/summary/summary_text.dart`) : le moteur ne renvoie que des données.

## Tableau tactique (`tactics.dart`, E08)
- Coordonnées sur le terrain entier : x de 0 à 1 (gauche → droite vu depuis notre camp), y de 0 (fond adverse) à 1 (notre fond), filet en y = 0,5 ; marges hors terrain autorisées (`BoardPoint.marginX`, `marginY`) pour le serveur et la couverture.
- `courtPositions(format)` : place de chaque poste dans notre camp, dans l'ordre de la composition (index 0 = poste 1 = zone 1, arrière droit). La composition en cours du match étant déjà tournée, `TacticBoard.forLineup(format, state.lineup)` place les pions sur la rotation en cours.
- Pas de schéma de réception pré-construit (V1-TAC-08) tant que les placements par rotation en 4-2 et 5-1 n'ont pas été validés avec Yann.

## En cas de doute
Proposer un paramètre plutôt qu'une règle codée en dur, et le signaler à Yann (coach) qui tranche.
