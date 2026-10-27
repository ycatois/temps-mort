# Temps Mort — studio

Le banc de touche dans la tablette : application de coaching volley (stats en direct, rotation automatique, tableau tactique au doigt), son site vitrine et son blog. Une marque d'Hasteria SASU. *« Temps Mort » est un nom de travail.*

## Ce que contient ce dépôt

- **`mobile/`** — app native iOS et Android. Règles du volley et moteur de match partagés en Kotlin Multiplatform, interfaces en Jetpack Compose et SwiftUI.
- **`web/`** — site vitrine PHP + MariaDB pour o2switch : accueil, tarifs, mentions légales, confidentialité, inscription à la bêta.
- **`wp-theme/temps-mort/`** — thème WordPress du blog (`/blog`), identique au site.
- **`design/`** — tokens, CSS commun, polices Barlow auto-hébergées, maquettes. Une commande décline tout vers les trois cibles.
- **`.claude/` + `CLAUDE.md`** — le studio : agents spécialisés, commandes (`/feature`, `/check`, `/deploy-web`…), skills (règles du volley, design system, déploiement o2switch), hook qui garde le design cohérent.

## Démarrage rapide

```bash
git clone <dépôt> temps-mort && cd temps-mort
npm run check                 # vérifie design, parité site/blog et tests PHP
npm run dev:web               # site sur http://localhost:8080
docker compose up -d          # ou : site + blog WordPress + MariaDB, comme sur o2switch
cd mobile && ./gradlew :shared:jvmTest   # tests du moteur de match
```

Puis ouvrir le dossier dans Claude Code : `CLAUDE.md` et `.claude/` sont chargés automatiquement. Exemple : `/feature E05 annulation illimitée`.

## Documentation

- [Architecture et choix techniques](docs/architecture.md)
- [App mobile : prérequis, lancement, publication](docs/mobile.md)
- [Déploiement o2switch](docs/deploiement-o2switch.md)
- [Feuille de route V1 / V2 / V3 avec état d'avancement](docs/roadmap.md)

## Licences

Code propriétaire Hasteria SASU. Polices Barlow et Barlow Condensed : SIL Open Font License 1.1 (`design/fonts/OFL.txt`).
