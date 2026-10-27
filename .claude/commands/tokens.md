---
description: Modifier le design (couleur, police, rayon…) et propager partout
argument-hint: <changement souhaité>
---
Changement demandé : $ARGUMENTS

1. Modifie uniquement `design/tokens.json` (ou `design/css/base.css` pour un composant commun site + blog).
2. `node design/build.mjs` : régénère CSS du site et du blog, `theme.json`, `mobile/lib/ui/theme/tokens.dart`, polices.
3. Vérifie le contraste AA des couples texte/fond touchés.
4. Captures avant/après du site et du blog (1440 et 390 px) ; signale les écrans d'app concernés.
5. Commit `style(design): …` avec tous les fichiers générés.
