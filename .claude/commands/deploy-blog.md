---
description: Déployer le thème WordPress du blog sur o2switch
---
1. `node design/build.mjs --check` et `node scripts/check-parity.mjs`.
2. Incrémente `Version:` dans `wp-theme/temps-mort/style.css` et `TM_THEME_VERSION` dans `functions.php`.
3. `scripts/deploy-theme.sh --dry-run`, puis confirmation de Yann, puis `scripts/deploy-theme.sh`.
4. Vérifie `/blog/` et un article : en-tête et pied identiques au site, formulaire bêta fonctionnel.
5. Commit `chore(blog): thème vX.Y.Z` et tag `theme-vX.Y.Z`.
