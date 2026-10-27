# Déploiement sur o2switch

Le détail opérationnel (pour Claude comme pour vous) est dans la skill `.claude/skills/o2switch-deploy/SKILL.md`. Résumé :

## Disposition

| Local | Serveur |
|---|---|
| `web/public/` | `~/public_html/` |
| `web/app/` | `~/tempsmort-app/` (hors web, contient `.env`) |
| WordPress (installé une fois) | `~/public_html/blog/` |
| `wp-theme/temps-mort/` | `~/public_html/blog/wp-content/themes/temps-mort/` |

## Une seule fois

1. cPanel : base `<compte>_tempsmort` + utilisateur ; base `<compte>_blog` pour WordPress.
2. cPanel : autoriser votre IP pour SSH, déposer votre clé publique. PHP 8.3 avec `pdo_mysql`.
3. AutoSSL actif sur le domaine et `www`.
4. Sur le serveur : `~/tempsmort-app/.env` d'après `web/app/.env.example`.
5. Installer WordPress dans `public_html/blog`, puis `scripts/deploy-theme.sh` et activer le thème « Temps Mort ».
6. Sur votre poste (WSL) : `cp scripts/deploy.env.example scripts/deploy.env` et compléter.

## À chaque mise en production

```bash
npm run check
scripts/deploy-web.sh --dry-run     # ce qui va changer
scripts/deploy-web.sh               # copie + migrations MariaDB
scripts/deploy-theme.sh             # si le thème a changé
```

Ou dans Claude Code : `/deploy-web` et `/deploy-blog` (Claude demande confirmation avant d'envoyer).

## En local, comme sur le serveur

```bash
docker compose up -d
docker compose exec web php /var/www/site/app/bin/migrate.php
# http://localhost:8080        site
# http://localhost:8080/blog/  WordPress (assistant d'installation au premier lancement, puis activer le thème)
```
Sans Docker : WAMP avec un virtual host dont la racine est `web/public`, WordPress copié dans `web/public/blog`, et `web/app/.env` pointant vers la MariaDB de WAMP.
