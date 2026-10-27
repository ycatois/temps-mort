---
name: o2switch-deploy
description: Déploiement du site PHP/MariaDB et du blog WordPress sur l'hébergement mutualisé o2switch (SSH, rsync, cPanel, MariaDB, SSL). À lire avant tout déploiement ou toute question d'hébergement.
---
# Déployer sur o2switch

## Disposition sur le serveur
```
~/public_html/            ← web/public (index.php, .htaccess, assets)
~/public_html/blog/       ← WordPress (installé une fois via cPanel ou à la main) — jamais écrasé par le déploiement du site
~/public_html/blog/wp-content/themes/temps-mort/  ← wp-theme/temps-mort
~/tempsmort-app/          ← web/app (code, gabarits, migrations, .env) — hors web
```
`public/index.php` cherche l'application dans `../tempsmort-app` puis `../app`.

## Première mise en place (une fois, par Yann)
1. cPanel > Domaines : domaine principal pointé sur `public_html`.
2. cPanel > Bases de données MySQL : créer `<compte>_tempsmort`, un utilisateur, l'associer (tous privilèges). Idem `<compte>_blog` pour WordPress.
3. Accès SSH : autoriser son adresse IP dans l'outil SSH de cPanel (o2switch filtre les IP), ajouter sa clé publique.
4. SSL : certificat Let's Encrypt automatique (AutoSSL) sur le domaine et `www`.
5. Version PHP : 8.3 via « Sélecteur de version PHP », extensions `pdo_mysql`, `mbstring`, `intl`.
6. Créer `~/tempsmort-app/.env` à partir de `web/app/.env.example` (DB_DSN avec `host=localhost`).
7. Installer WordPress dans `public_html/blog` (Softaculous ou archive), puis copier le thème et l'activer.
8. Copier `scripts/deploy.env.example` en `scripts/deploy.env` sur le poste de Yann (hôte, utilisateur).

## Déploiements
- Site : `scripts/deploy-web.sh --dry-run` puis `scripts/deploy-web.sh` (vérifications, rsync public sans /blog, rsync app sans .env, migrations).
- Thème : `scripts/deploy-theme.sh`.
- Toujours depuis `main` propre, après `/check`, avec confirmation explicite de Yann.

## Points d'attention
- Mutualisé : pas de processus permanent, pas de Node en production ; tâches planifiées via cPanel > Tâches Cron (`php ~/tempsmort-app/bin/...`).
- Le `.htaccess` du site exclut `/blog` de la réécriture et de la CSP stricte ; WordPress garde son propre `.htaccess`.
- Emails transactionnels : Mailjet (pas le `mail()` du serveur) quand l'envoi arrivera.
- Sauvegardes : JetBackup o2switch + export MariaDB régulier vers le NAS.
