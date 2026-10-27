#!/usr/bin/env node
// Génère toutes les déclinaisons du design à partir de design/tokens.json et design/css/base.css.
//   node design/build.mjs          → écrit les fichiers
//   node design/build.mjs --check  → échoue si un fichier généré n'est pas à jour (CI)
import { readFileSync, writeFileSync, mkdirSync, readdirSync, existsSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const check = process.argv.includes('--check');
const tokens = JSON.parse(readFileSync(join(root, 'design/tokens.json'), 'utf8'));
const HEADER = 'GÉNÉRÉ par design/build.mjs depuis design/tokens.json — ne pas modifier à la main.';

const camel = (s) => s.replace(/-([a-z0-9])/g, (_, c) => c.toUpperCase());
const pascal = (s) => camel(s).replace(/^./, (c) => c.toUpperCase());
const colors = Object.entries(tokens.color).map(([k, v]) => [k, v.value.toUpperCase(), v.role]);
const fontStack = (f) => `"${f.family}", ${f.fallback}`;

const outputs = new Map(); // chemin relatif → contenu (string ou Buffer)

// ---------- CSS ----------
const css = [
  `/* ${HEADER} */`,
  ':root {',
  ...colors.map(([k, v, role]) => `  --c-${k}: ${v}; /* ${role} */`),
  `  --font-display: ${fontStack(tokens.font.display)};`,
  `  --font-body: ${fontStack(tokens.font.body)};`,
  ...Object.entries(tokens.radius).map(([k, v]) => `  --r-${k}: ${v}px;`),
  ...Object.entries(tokens.space).map(([k, v]) => `  --s-${k}: ${v}px;`),
  `  --container: ${tokens.layout.container}px;`,
  `  --container-narrow: ${tokens.layout['container-narrow']}px;`,
  `  --gutter: ${tokens.layout.gutter}px;`,
  `  --touch-min: ${tokens.touch['min-target']}px;`,
  `  --touch-primary: ${tokens.touch['primary-target']}px;`,
  '}',
  '',
].join('\n');
const baseCss = readFileSync(join(root, 'design/css/base.css'));
const fonts = readdirSync(join(root, 'design/fonts')).filter((f) => f.endsWith('.woff2') || f === 'OFL.txt');

for (const target of ['web/public/assets', 'wp-theme/temps-mort/assets']) {
  outputs.set(`${target}/css/tokens.css`, css);
  outputs.set(`${target}/css/base.css`, baseCss);
  for (const f of fonts) outputs.set(`${target}/fonts/${f}`, readFileSync(join(root, 'design/fonts', f)));
}

// Polices TTF pour les apps natives (Android : res/font, iOS : bundle déclaré dans Info.plist)
for (const f of readdirSync(join(root, 'design/fonts/ttf')).filter((f) => f.endsWith('.ttf'))) {
  const data = readFileSync(join(root, 'design/fonts/ttf', f));
  outputs.set(`mobile/androidApp/src/main/res/font/${f}`, data);
  outputs.set(`mobile/iosApp/iosApp/Fonts/${f}`, data);
}

// ---------- WordPress theme.json ----------
const fontFaces = (font, slugPrefix) => font.weights.map((w) => ({
  fontFamily: font.family, fontStyle: 'normal', fontWeight: String(w),
  src: [`file:./assets/fonts/${slugPrefix}-latin-${w}-normal.woff2`],
}));
const themeJson = {
  $schema: 'https://schemas.wp.org/trunk/theme.json',
  version: 3,
  title: `${HEADER}`,
  settings: {
    appearanceTools: false,
    color: {
      custom: false, customGradient: false, defaultPalette: false, defaultGradients: false,
      palette: colors.map(([k, v]) => ({ slug: k, color: v, name: k })),
    },
    typography: {
      customFontSize: false, defaultFontSizes: false,
      fontFamilies: [
        { slug: 'display', name: tokens.font.display.family, fontFamily: fontStack(tokens.font.display), fontFace: fontFaces(tokens.font.display, 'barlow-condensed') },
        { slug: 'body', name: tokens.font.body.family, fontFamily: fontStack(tokens.font.body), fontFace: fontFaces(tokens.font.body, 'barlow') },
      ],
      fontSizes: [
        { slug: 'small', name: 'Petit', size: '15px' },
        { slug: 'medium', name: 'Normal', size: '18px' },
        { slug: 'large', name: 'Grand', size: '24px' },
        { slug: 'x-large', name: 'Titre', size: 'clamp(30px, 3.5vw, 44px)' },
      ],
    },
    layout: { contentSize: '720px', wideSize: `${tokens.layout.container}px` },
    spacing: { units: ['px', 'em', 'rem', '%'] },
  },
  styles: {
    color: { background: 'var(--wp--preset--color--ground)', text: 'var(--wp--preset--color--text)' },
    typography: { fontFamily: 'var(--wp--preset--font-family--body)', fontSize: '18px', lineHeight: '1.65' },
    elements: {
      link: { color: { text: 'var(--wp--preset--color--accent)' } },
      heading: { typography: { fontFamily: 'var(--wp--preset--font-family--display)', fontWeight: '700', lineHeight: '1.05' }, color: { text: 'var(--wp--preset--color--navy)' } },
      button: { color: { background: 'var(--wp--preset--color--yellow)', text: 'var(--wp--preset--color--navy)' }, border: { radius: `${tokens.radius.md}px` }, typography: { fontWeight: '700' } },
    },
  },
};
outputs.set('wp-theme/temps-mort/theme.json', JSON.stringify(themeJson, null, 2) + '\n');

// ---------- Android (Jetpack Compose) ----------
outputs.set('mobile/androidApp/src/main/kotlin/fr/hasteria/tempsmort/android/ui/theme/Tokens.kt', [
  `// ${HEADER}`,
  'package fr.hasteria.tempsmort.android.ui.theme',
  '',
  'import androidx.compose.ui.graphics.Color',
  'import androidx.compose.ui.unit.dp',
  '',
  'object TmColor {',
  ...colors.map(([k, v, role]) => `    /** ${role} */\n    val ${pascal(k)} = Color(0xFF${v.slice(1)})`),
  '}',
  '',
  'object TmRadius {',
  ...Object.entries(tokens.radius).filter(([k]) => k !== 'pill').map(([k, v]) => `    val ${pascal(k)} = ${v}.dp`),
  '}',
  '',
  'object TmTouch {',
  `    val MinTarget = ${tokens.touch['min-target']}.dp`,
  `    val PrimaryTarget = ${tokens.touch['primary-target']}.dp`,
  '}',
  '',
].join('\n'));

// ---------- iOS (SwiftUI) ----------
const rgb = (hex) => [1, 3, 5].map((i) => (parseInt(hex.slice(i, i + 2), 16) / 255).toFixed(4));
outputs.set('mobile/iosApp/iosApp/Theme/Tokens.swift', [
  `// ${HEADER}`,
  'import SwiftUI',
  '',
  'enum TmColor {',
  ...colors.map(([k, v, role]) => { const [r, g, b] = rgb(v); return `    /// ${role}\n    static let ${camel(k)} = Color(red: ${r}, green: ${g}, blue: ${b})`; }),
  '}',
  '',
  'enum TmRadius {',
  ...Object.entries(tokens.radius).filter(([k]) => k !== 'pill').map(([k, v]) => `    static let ${k}: CGFloat = ${v}`),
  '}',
  '',
  'enum TmTouch {',
  `    static let minTarget: CGFloat = ${tokens.touch['min-target']}`,
  `    static let primaryTarget: CGFloat = ${tokens.touch['primary-target']}`,
  '}',
  '',
].join('\n'));

// ---------- Écriture / vérification ----------
let stale = [];
for (const [rel, content] of outputs) {
  const abs = join(root, rel);
  const buf = Buffer.isBuffer(content) ? content : Buffer.from(content);
  if (check) {
    if (!existsSync(abs) || !readFileSync(abs).equals(buf)) stale.push(rel);
    continue;
  }
  mkdirSync(dirname(abs), { recursive: true });
  writeFileSync(abs, buf);
}
if (check) {
  if (stale.length) { console.error('Fichiers générés pas à jour :\n  ' + stale.join('\n  ') + '\nLancer : node design/build.mjs'); process.exit(1); }
  console.log(`OK : ${outputs.size} fichiers à jour.`);
} else {
  console.log(`${outputs.size} fichiers générés.`);
}
