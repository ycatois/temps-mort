#!/usr/bin/env node
// Vérifie que l'en-tête, le pied de page et le formulaire bêta ont la même structure
// sur le site (web/) et dans le thème WordPress (wp-theme/) : mêmes balises, mêmes classes, même ordre.
import { readFileSync } from 'node:fs';

const pairs = [
  ['En-tête', 'web/app/templates/partials/header.php', 'wp-theme/temps-mort/header.php', /<header class="site-header">[\s\S]*?<\/header>/],
  ['Pied de page', 'web/app/templates/partials/footer.php', 'wp-theme/temps-mort/footer.php', /<footer class="site-footer">[\s\S]*?<\/footer>/],
  ['Formulaire bêta', 'web/app/templates/partials/beta.php', 'wp-theme/temps-mort/template-parts/beta.php', /<section id="beta"[\s\S]*?<\/section>/],
];

// Structure = suite « balise.classes » en ignorant le PHP et les attributs dynamiques.
const shape = (html) => [...html.replace(/<\?(php|=)[\s\S]*?\?>/g, '').matchAll(/<([a-z0-9]+)\b([^>]*)>/gi)]
  .map(([, tag, attrs]) => `${tag}${(attrs.match(/class="([^"]*)"/)?.[1] ?? '').split(/\s+/).filter(Boolean).map((c) => '.' + c).join('')}`);

let ko = 0;
for (const [label, a, b, re] of pairs) {
  const sa = shape(readFileSync(a, 'utf8').match(re)?.[0] ?? '');
  const sb = shape(readFileSync(b, 'utf8').match(re)?.[0] ?? '');
  if (sa.length && JSON.stringify(sa) === JSON.stringify(sb)) { console.log(`✓ ${label}`); continue; }
  ko++;
  const i = sa.findIndex((x, k) => x !== sb[k]);
  console.error(`✗ ${label} diffère (élément ${i}) : site « ${sa[i]} » / blog « ${sb[i]} »`);
}
process.exit(ko ? 1 : 0);
