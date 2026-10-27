#!/usr/bin/env bash
# Déploie le thème WordPress du blog : wp-theme/temps-mort → ~/public_html/blog/wp-content/themes/temps-mort
# Usage : scripts/deploy-theme.sh [--dry-run]
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/deploy.env
DRY=${1:-}

node design/build.mjs --check
for f in $(find wp-theme -name '*.php'); do php -l "$f" > /dev/null; done && echo "  syntaxe PHP OK"

rsync -az --delete $DRY -e "ssh -p ${O2_PORT:-22}" \
  wp-theme/temps-mort/ "$O2_USER@$O2_HOST:$O2_BLOG/wp-content/themes/temps-mort/"
echo "✓ Thème déployé (à activer une fois dans Apparence > Thèmes)"
