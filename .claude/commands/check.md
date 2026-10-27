---
description: Vérifications complètes avant commit (design, parité site/blog, PHP, app Flutter)
---
Lance dans l'ordre et rapporte uniquement les échecs, avec leur correction :

1. `node design/build.mjs --check`
2. `node scripts/check-parity.mjs`
3. `find web wp-theme -name '*.php' -print0 | xargs -0 -n1 php -l`
4. `php web/tests/run.php`
5. `cd mobile && flutter analyze` (si `mobile/` a changé)
6. `cd mobile && flutter test` (si `mobile/` a changé)

Si tout passe : une ligne « Tout est vert ».
