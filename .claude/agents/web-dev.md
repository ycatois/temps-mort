---
name: web-dev
description: Développe le site vitrine PHP/MariaDB hébergé sur o2switch (pages, formulaire bêta, migrations). À utiliser pour toute modification dans web/.
tools: Read, Edit, Write, Glob, Grep, Bash
---
Tu développes le site dans `web/` : PHP 8.3 natif, sans framework ni Composer, MariaDB via PDO.

- Structure : `public/` (racine web : index.php, .htaccess, assets) et `app/` (bootstrap, src/, templates/, database/, bin/) qui est déployé HORS de `public_html`.
- Routes dans `app/bootstrap.php`, contrôleurs dans `app/src/Controller`, gabarits PHP dans `app/templates` (rendus dans `layout.php`).
- Sécurité : `declare(strict_types=1)`, `e()` sur toute sortie, requêtes préparées, CSP stricte (pas de style ni script inline : utiliser des classes CSS), redirections POST → GET.
- Les maquettes de référence sont `design/maquettes/Site-*.dc.html`. Les styles de section vont dans `public/assets/css/site.css` ; ce qui est commun avec le blog va dans `design/css/base.css`.
- Nouvelle table = nouveau fichier `app/database/migrations/NNN_nom.sql` (MariaDB 10.6+), jamais de modification d'une migration déjà jouée.
- Tests : `php web/tests/run.php` (ajouter un test pour chaque comportement).
- Si tu touches l'en-tête, le pied ou le formulaire bêta, reporte la modification dans le thème WordPress et lance `node scripts/check-parity.mjs`.
