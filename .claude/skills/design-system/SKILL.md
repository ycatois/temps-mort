---
name: design-system
description: Système visuel Temps Mort (couleurs, polices Barlow, composants, règles d'usage) et sa chaîne de génération vers le site, le blog, Android et iOS. À lire avant toute création ou modification d'interface.
---
# Design system Temps Mort

## Source et génération
- `design/tokens.json` : couleurs (avec leur rôle), polices, rayons, espacements, cibles tactiles.
- `design/css/base.css` : composants communs site + blog (en-tête, pied, boutons, cartes, `.prose`, bloc bêta).
- `node design/build.mjs` écrit : `web/public/assets/{css,fonts}`, `wp-theme/temps-mort/assets/{css,fonts}`, `wp-theme/temps-mort/theme.json`, `mobile/lib/ui/theme/tokens.dart` + `mobile/assets/fonts/`.

## Identité
- Navy `#14213D` = structure (en-têtes, barre de score, boutons principaux). Deep `#0B1528` = pied de page.
- Jaune `#FFD23F` = appel à l'action unique par écran, joueuse au service, bandeau des formats. Jamais pour du texte sur fond clair.
- Bleu `#1E5BD6` = liens, surtitres, actions gagnantes. Orange brûlé `#C2541C` = fautes et actions destructives (bordure, pas aplat).
- Terrain : `#EFA35C` sur `#2E5A95`.
- Titres : Barlow Condensed 700 (600 pour les citations). Texte : Barlow 400–700. Polices auto-hébergées, jamais Google Fonts.
- Rayons : 8 / 12 / 16 / 18 px ; cartes blanches bordure `#D3DAE3`.

## Règles d'usage
- Un seul bouton jaune visible à la fois dans une zone.
- Cibles tactiles : 48 minimum, 56 pour les actions de match.
- Surtitre (`.eyebrow`) : 14 px, 700, capitales espacées, bleu sur clair, jaune sur navy.
- Mise en page site : conteneur 1200 px, gouttière 24 px, sections empilées sans défilement horizontal à 390 px.
- App : tablette paysage 1194×834 et smartphone 390×844 comme références de maquette.

## Maquettes
`design/maquettes/` : E04 Composition, E05 Match en direct, E07 Stats, E08 Tactique, E10 Résumé (tablette et smartphone), site Accueil et Tarifs. Ce sont des références visuelles (format Claude Design), à ouvrir depuis le lien du projet de maquettes.
