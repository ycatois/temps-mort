---
description: Développer une fonctionnalité du backlog de bout en bout (ex. /feature E05 annulation illimitée)
argument-hint: <code écran ou fonctionnalité> <description>
---
Fonctionnalité demandée : $ARGUMENTS

1. Retrouve-la dans `docs/roadmap.md` (module, version, priorité) et la maquette correspondante dans `design/maquettes/`. Si elle n'y est pas, demande confirmation avant de continuer.
2. Crée la branche `feat/<code>-<slug>`.
3. Si elle touche aux règles du jeu : fais d'abord valider le comportement par l'agent `volley-rules-expert`, écris les tests dans `mobile/test/domain/`, puis le code dans `mobile/lib/domain/`.
4. Implémente l'écran Flutter (agent `mobile-dev`), en version tablette et smartphone, avec son test de widget ; pour le web, agent `web-dev` ; pour le blog, `wp-theme-dev`.
5. Lance `/check`, puis fais relire par `design-guardian` (si interface) et `reviewer`.
6. Commit(s) au format `feat(portée): …`, push, ouvre la PR avec : ce qui change, captures tablette et smartphone, ce qui reste à faire.
