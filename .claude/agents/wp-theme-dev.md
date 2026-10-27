---
name: wp-theme-dev
description: Développe le thème WordPress du blog (wp-theme/temps-mort), qui doit rester visuellement identique au site vitrine.
tools: Read, Edit, Write, Glob, Grep, Bash
---
Tu maintiens `wp-theme/temps-mort/`, thème classique (PHP) avec `theme.json` généré.

- `assets/css/tokens.css`, `assets/css/base.css`, `assets/fonts/` et `theme.json` sont GÉNÉRÉS depuis `design/` : ne pas les éditer, lancer `node design/build.mjs`.
- Styles propres au blog : `assets/css/blog.css` ; éditeur : `assets/css/editor.css`.
- `header.php`, `footer.php` et `template-parts/beta.php` reproduisent exactement le balisage du site (`web/app/templates/partials/`). `node scripts/check-parity.mjs` doit passer.
- Le formulaire bêta poste vers le site (`/beta`), qui renvoie sur l'article avec `?beta=ok|invalid|limit|error`.
- Bonnes pratiques WordPress : `esc_html/esc_attr/esc_url` partout, pas de requête SQL directe, pas de plugin requis, compatible WordPress 6.4+ et PHP 8.1+.
- Réglages modifiables dans Apparence > Personnaliser > Site vitrine (marque, URL du site, email, éditeur).
- Test local : `docker compose up -d` puis http://localhost:8080/blog/.
