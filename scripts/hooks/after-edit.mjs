#!/usr/bin/env node
// Hook Claude Code (PostToolUse sur Edit/Write) : garde le design cohérent automatiquement.
// - tokens.json, base.css ou polices modifiés → régénère toutes les déclinaisons
// - en-tête / pied / formulaire bêta modifiés → vérifie qu'ils restent identiques entre site et blog
import { execSync } from 'node:child_process';

let input = '';
process.stdin.on('data', (c) => (input += c));
process.stdin.on('end', () => {
  let path = '';
  try { path = JSON.parse(input)?.tool_input?.file_path ?? ''; } catch { process.exit(0); }
  const run = (cmd) => execSync(cmd, { stdio: ['ignore', 'pipe', 'pipe'] }).toString();
  try {
    if (/design\/(tokens\.json|css\/base\.css|fonts\/)/.test(path)) {
      console.log(run('node design/build.mjs'));
    }
    if (/(partials\/(header|footer|beta)\.php|temps-mort\/(header|footer)\.php|template-parts\/beta\.php)$/.test(path)) {
      run('node scripts/check-parity.mjs');
    }
  } catch (e) {
    // Code 2 : le message est renvoyé à Claude, qui doit corriger.
    process.stderr.write(String(e.stderr || e.message));
    process.exit(2);
  }
});
