# Temps Mort — studio de développement

Application de coaching volley (nom de travail « Temps Mort », marque d'Hasteria SASU) : stats en match, rotation automatique, tableau tactique au doigt, convocations. Tablette d'abord, smartphone aussi, **hors ligne d'abord**.

Ce dépôt unique contient les trois livrables et ce qui les relie :

| Dossier | Quoi | Techno | Où ça tourne |
|---|---|---|---|
| `mobile/` | App native iOS + Android | Kotlin Multiplatform (`shared/`), Jetpack Compose (`androidApp/`), SwiftUI (`iosApp/`) | Stores |
| `web/` | Site vitrine + inscription bêta | PHP 8.3 sans framework, MariaDB, Apache `.htaccess` | o2switch `~/public_html` + `~/tempsmort-app` |
| `wp-theme/temps-mort/` | Thème du blog, identique au site | Thème WordPress classique + `theme.json` | o2switch `~/public_html/blog` |
| `design/` | Source unique du design | `tokens.json`, `css/base.css`, polices, maquettes | Génère CSS, Kotlin, Swift, theme.json |

## Règles d'or

1. **Le design a une seule source** : `design/tokens.json` et `design/css/base.css`. Ne jamais éditer les fichiers générés (en-tête « GÉNÉRÉ par design/build.mjs »). Après modification : `node design/build.mjs` (le hook le fait automatiquement).
2. **Site et blog sont identiques** : l'en-tête, le pied de page et le formulaire bêta existent en double (`web/app/templates/partials/*.php` et `wp-theme/temps-mort/{header,footer}.php`, `template-parts/beta.php`). Toute modification se fait des deux côtés ; `node scripts/check-parity.mjs` doit passer.
3. **Les règles du volley vivent dans `mobile/shared/`** et nulle part ailleurs. Les écrans Android et iOS ne contiennent aucune règle : ils appellent `MatchSession`. Toute règle nouvelle arrive avec son test dans `shared/src/commonTest`. Voir la skill `volley-rules`.
4. **Hors ligne d'abord** : un match se joue sans réseau. Le match est une liste d'événements (`MatchEvent`) ; l'état se recalcule en les rejouant ; annuler = retirer le dernier.
5. **Mineures** : la plupart des joueuses sont mineures. Minimum de données (prénom, numéro, genre si équipe mixte), aucune photo par défaut, hébergement en France, suppression sur demande.
6. **Accessibilité terrain** : cibles tactiles ≥ 48 dp/pt (56 pour les actions de match), contrastes AA, rien qui ne repose sur la couleur seule.
7. **o2switch = hébergement mutualisé** : PHP natif, pas de Composer obligatoire, pas de Node en production, pas de démon. Le code applicatif reste hors de `public_html`.

## Commandes utiles

```bash
node design/build.mjs            # régénère tokens CSS/Kotlin/Swift, theme.json, polices
npm run check                    # tokens à jour + parité site/blog + tests PHP
npm run dev:web                  # site sur http://localhost:8080 (sans base : pages statiques)
docker compose up -d             # site + WordPress /blog + MariaDB, comme sur o2switch
cd mobile && ./gradlew :shared:jvmTest          # tests du moteur de match
cd mobile && ./gradlew :androidApp:installDebug # app Android sur l'appareil branché
cd mobile/iosApp && xcodegen && open TempsMort.xcodeproj   # app iOS (Mac requis)
scripts/deploy-web.sh --dry-run  # simulation du déploiement du site
scripts/deploy-theme.sh          # déploiement du thème du blog
```

## Où trouver quoi

- Backlog V1/V2/V3 (83 fonctionnalités, 9 modules) : doc « Fonctionnalités V1 / V2 / V3 » sur claude.ai — résumé dans `docs/roadmap.md`.
- Maquettes : `design/maquettes/*.dc.html` (écrans E04, E05, E07, E08, E10 tablette et smartphone ; site Accueil et Tarifs).
- Tarifs et acquisition : docs « Temps Mort : grille tarifaire » et « Temps Mort : acquisition par le blog et Facebook » sur claude.ai ; sujets du blog dans `marketing/sujets.md`.
- Architecture et choix techniques : `docs/architecture.md`. Déploiement : `docs/deploiement-o2switch.md`. Mobile et stores : `docs/mobile.md`.

## Conventions

- Langue : interface, commentaires et docs en français ; identifiants de code en anglais.
- Commits : `type(portée): message` en français, ex. `feat(shared): remplacement libero automatique`. Portées : `shared`, `android`, `ios`, `web`, `blog`, `design`, `infra`.
- Git : Claude gère les commits, branches et push. Une branche par fonctionnalité (`feat/E05-annulation`), PR vers `main`, CI verte avant merge.
- PHP : `declare(strict_types=1)`, échapper toute sortie avec `e()` (site) ou `esc_*()` (WordPress), requêtes préparées uniquement.
- Pas de dépendance externe chargée depuis un CDN (RGPD) : polices et scripts auto-hébergés.

## Agents et commandes du studio

Agents (`.claude/agents/`) : `mobile-dev`, `web-dev`, `wp-theme-dev`, `volley-rules-expert`, `design-guardian`, `reviewer`, `redacteur-blog`, `community-manager`.
Commandes (`.claude/commands/`) : `/feature`, `/check`, `/tokens`, `/deploy-web`, `/deploy-blog`, `/release-mobile`, `/article`, `/posts-facebook`, `/bilan-marketing`.
Skills (`.claude/skills/`) : `volley-rules`, `design-system`, `o2switch-deploy`, `ligne-editoriale`.

## Marketing

L'acquisition passe par le blog et la page Facebook : voir `marketing/README.md`. Le marketing compte autant que le code : un sujet du blog sans brouillon est une tâche au même titre qu'un écran.
