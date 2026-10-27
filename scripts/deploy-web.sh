#!/usr/bin/env bash
# Déploie le site PHP sur o2switch : web/public → ~/public_html, web/app → ~/tempsmort-app (hors web).
# Usage : scripts/deploy-web.sh [--dry-run]
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/deploy.env
DRY=${1:-}
SSH="ssh -p ${O2_PORT:-22}"

echo "▸ Vérifications"
node design/build.mjs --check
php web/tests/run.php > /dev/null && echo "  tests PHP OK"
for f in $(find web -name '*.php'); do php -l "$f" > /dev/null; done && echo "  syntaxe PHP OK"

echo "▸ Fichiers publics → ~/$O2_PUBLIC (le dossier blog/ n'est jamais touché)"
rsync -az --delete $DRY -e "$SSH" \
  --exclude 'blog/' --exclude '.well-known/' --exclude 'cgi-bin/' \
  web/public/ "$O2_USER@$O2_HOST:$O2_PUBLIC/"

echo "▸ Application → ~/$O2_APP"
rsync -az --delete $DRY -e "$SSH" \
  --exclude '.env' --exclude 'var/log/*.log' \
  web/app/ "$O2_USER@$O2_HOST:$O2_APP/"

if [ -z "$DRY" ]; then
  echo "▸ Migrations MariaDB"
  $SSH "$O2_USER@$O2_HOST" "php ~/$O2_APP/bin/migrate.php"
fi
echo "✓ Site déployé"
