---
description: Déployer le site vitrine sur o2switch
---
Lis la skill `o2switch-deploy`, puis :

1. Vérifie que la branche est `main`, à jour et propre (`git status`).
2. `scripts/deploy-web.sh --dry-run` et montre la liste des fichiers qui changeront.
3. Demande confirmation explicite à Yann avant le vrai déploiement.
4. `scripts/deploy-web.sh` (copie public → ~/public_html sans toucher à /blog, app → ~/tempsmort-app, migrations).
5. Contrôle : `curl -sI https://<domaine>/` et `/tarifs` en 200, `/blog/` toujours en 200, en-têtes de sécurité présents.
6. Tag git `web-AAAA-MM-JJ` et push du tag.
