# Architecture

## Vue d'ensemble

```
                 design/tokens.json + css/base.css + polices
                                   │  node design/build.mjs
        ┌──────────────────────────┼───────────────────────────────┐
        ▼                          ▼                               ▼
  web/public/assets      wp-theme/temps-mort/assets       mobile/…/Tokens.kt, Tokens.swift
  (site PHP)             + theme.json (blog WordPress)    + polices TTF (apps natives)

  ┌─────────── o2switch (mutualisé) ───────────┐        ┌──────────── Appareils ────────────┐
  │ ~/public_html        site vitrine (PHP)    │        │ Android (Compose)   iOS (SwiftUI) │
  │ ~/public_html/blog   WordPress + thème     │        │        └──── shared (KMP) ────┘    │
  │ ~/tempsmort-app      code PHP hors web     │        │ moteur de match, règles, stats    │
  │ MariaDB              inscriptions bêta…    │        │ stockage local, hors ligne        │
  └────────────────────────────────────────────┘        └───────────────────────────────────┘
                      ▲                                          │
                      └──────────── synchro (V1-TEC-03, à venir) ┘
```

## Choix techniques et raisons

### App mobile : natif avec Kotlin Multiplatform
- **Natif demandé** : interface Jetpack Compose sur Android et SwiftUI sur iOS, aucune vue web.
- **Une seule source pour les règles** : rotation, libero, remplacements, sets, mixité et stats sont dans `mobile/shared` (Kotlin commun), compilé en bibliothèque Android et en framework iOS (`Shared.framework`). Les deux apps ne peuvent pas diverger sur une règle.
- Alternative écartée : deux apps 100 % séparées (Swift + Kotlin) = règles écrites et testées deux fois. Flutter écarté : rendu non natif.
- Contrainte : l'app iOS se compile sur un Mac (Xcode). Le module partagé et l'app Android se développent sous Windows/WSL ou Linux.

### Match = journal d'événements
- `MatchEvent` (StartSet, Rally, Substitution, LiberoIn/Out, Timeout) est la seule chose stockée.
- L'état (score, rotation, service, compteurs) est recalculé par `MatchEngine.replay()`.
- Avantages : annulation illimitée (V1-MAT-08), reprise après fermeture (V1-TEC-02), synchronisation simple (on envoie des événements), stats recalculables à volonté.
- À venir : persistance locale (SQLDelight, commun aux deux plateformes) et synchro vers une API.

### Site : PHP natif + MariaDB
- o2switch est un hébergement mutualisé : PHP et MariaDB y sont natifs, sans démon ni Node.
- Pas de framework ni de Composer obligatoire : un front controller (`public/index.php`), un routeur, des gabarits PHP. Le code applicatif (`app/`) est déployé hors de `public_html`.
- Sécurité : CSP stricte (aucun script ou style externe ou inline), HTTPS forcé, requêtes préparées, contrôle d'origine sur les formulaires, redirection après POST.

### Blog : WordPress dans /blog avec un thème maison
- Même domaine que le site, sous-dossier `/blog` : bon pour le référencement et pour partager le formulaire bêta.
- Thème classique (PHP) plutôt que bloc (FSE) : l'en-tête et le pied sont le même balisage que le site, vérifié par `scripts/check-parity.mjs`.
- `theme.json` est généré depuis les tokens : l'éditeur ne propose que les couleurs et polices de la marque.

### Où vivra l'API de synchro ?
Pas décidé. Deux options :
1. **o2switch** (PHP + MariaDB, dans `web/app`, routes `/api/…`) : simple, hébergé en France, suffisant pour la V1.
2. **VPS OVH** (Docker) : nécessaire si temps réel (V2 : saisie par un parent, coach adjoint) ou charge importante.
Recommandation : démarrer en option 1 avec une API versionnée (`/api/v1`) pour pouvoir déménager sans changer l'app.

## Arborescence

```
.
├── CLAUDE.md                 consignes du studio pour Claude Code
├── .claude/                  agents, commandes, skills, hooks, permissions
├── design/                   tokens.json, css/base.css, polices, maquettes, build.mjs
├── mobile/
│   ├── shared/               Kotlin Multiplatform : domain/ (Team, MatchEngine, Stats…) + tests
│   ├── androidApp/           Jetpack Compose
│   └── iosApp/               SwiftUI + project.yml (XcodeGen)
├── web/
│   ├── public/               racine web → ~/public_html
│   ├── app/                  code PHP → ~/tempsmort-app
│   └── tests/run.php         tests sans dépendance
├── wp-theme/temps-mort/      thème du blog → ~/public_html/blog/wp-content/themes/
├── scripts/                  déploiement o2switch, contrôle de parité, hook
├── docker/ + docker-compose.yml   copie locale de l'hébergement
└── docs/                     architecture, déploiement, mobile, feuille de route
```
