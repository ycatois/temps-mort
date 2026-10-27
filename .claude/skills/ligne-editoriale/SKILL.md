---
name: ligne-editoriale
description: Ligne éditoriale Temps Mort pour le blog et Facebook (cibles, piliers, ton, gabarit d'article, règles sur les mineures et la feuille de match officielle). À lire avant d'écrire un article, un post Facebook ou une fiche à télécharger.
---
# Ligne éditoriale Temps Mort

Référence complète : doc « Temps Mort : acquisition par le blog et Facebook » (claude.ai). Liste des sujets et état : `marketing/sujets.md`.

## Pour qui on écrit
- Cœur de cible : le coach bénévole d'une équipe jeune, seul sur le banc, qui cherche une réponse pratique.
- Aussi : coachs seniors et loisir, coachs 4x4 / 2x2 / mixte, responsables techniques de club, parents qui aident, coachs en formation.
- Ce sont des adultes. On n'écrit jamais pour les joueuses mineures et on ne les cible jamais en publicité.

## Les cinq piliers (part des articles)
1. Rotations et systèmes (25 %) : rotations, 5-1, 4-2, 6-2, réception, libero.
2. Coacher en match (25 %) : temps morts, remplacements, stats utiles, debrief.
3. Jeunes et formats (25 %) : M7 à M13, 4x4, 2x2, mixité, temps de jeu.
4. Vie d'équipe et club (15 %) : convocations, parents, bénévolat, exercices.
5. Coulisses (10 %) : le journal du coach qui construit l'app, les retours de bêta.

## Le ton
- De coach à coach, à la première personne (Yann, coach d'une équipe féminine jeune). Exemples vécus, jamais de prénom ni de photo de joueuse.
- Vouvoiement sur le blog ; tutoiement possible dans un groupe Facebook où c'est l'usage.
- Phrases courtes (moins de 25 mots), aucun jargon non expliqué, un schéma plutôt qu'un long paragraphe.
- Pas de superlatifs marketing (« révolutionnaire », « ultime »). On montre, on ne vante pas.

## Gabarit d'un article de blog
1. Titre = la question telle qu'un coach la tape dans Google (60 caractères max).
2. Chapô : la réponse en 3 lignes.
3. 1 ou 2 schémas du tableau tactique de l'app, avec légende et texte alternatif.
4. Corps : 900 à 1 500 mots, intertitres sous forme de questions, listes quand c'est une suite d'étapes.
5. Bonus : une fiche PDF à télécharger (contre un email, inscription bêta avec consentement explicite).
6. Le bloc bêta est déjà en bas de chaque article dans le thème : ne pas en ajouter un second.
7. Deux liens internes vers des articles voisins ; liens externes vers les règlements officiels (FFVolley, FIVB).
8. Méta-description de 150 caractères, slug court sans mots vides.

Fichier : `marketing/articles/NN-slug.md` avec en-tête :
```
---
numero: 7
titre: Quelles stats suivre quand on coache seul ?
slug: stats-volley-coach-seul
pilier: Coacher en match
requete: statistiques volley match
meta: <150 caractères>
statut: brouillon | relu | publié
publie_le:
---
```

## Règles non négociables
- **Image des mineures** : aucune photo identifiable sans accord écrit des deux parents (loi n° 2024-120). Par défaut : schémas, écrans de l'app, le coach.
- **Feuille de match** : la feuille de match électronique FFVolley est obligatoire en 6x6 et 4x4 (RGES, art. 19.1). Temps Mort est « le carnet du coach », à côté de la feuille officielle, jamais à sa place.
- **Règles du volley** : vérifier tout point de règlement dans la skill `volley-rules` et le règlement officiel ; citer la source.
- **Pas de faux** : aucun témoignage, chiffre ou avis inventé. Une donnée = une source.
- **Logos** : pas de logo FFVolley, ligue ou club sans autorisation.
- **Facebook** : respecter les règles d'autopromotion de chaque groupe ; aider d'abord.

## Facebook : rythme de base
- Lundi : le schéma de la semaine (image).
- Mercredi : l'article de la semaine (lien en premier commentaire si la portée chute).
- Samedi soir ou dimanche : une question ou un sondage aux coachs.
- 2 fois par mois : une vidéo courte (20 à 30 s) de démonstration ou de coulisses.
Chaque lien porte `?utm_source=facebook&utm_medium=social&utm_campaign=<slug>`.
