<?php
declare(strict_types=1);

// Tests sans dépendance (o2switch n'a pas besoin de Composer) : php web/tests/run.php
use TempsMort\BetaSignups;
use TempsMort\Controller\BetaController;
use TempsMort\Database;
use TempsMort\Response;
use TempsMort\Router;

$app = dirname(__DIR__) . '/app';
spl_autoload_register(static function (string $c) use ($app): void {
    if (str_starts_with($c, 'TempsMort\\')) { require $app . '/src/' . str_replace('\\', '/', substr($c, 10)) . '.php'; }
});
require $app . '/src/helpers.php';

$failed = 0; $passed = 0;
function check(string $name, bool $ok): void {
    global $failed, $passed;
    $ok ? $passed++ : $failed++;
    echo ($ok ? "  ✓ " : "  ✗ ") . $name . "\n";
}

function memoryDb(): Database {
    $pdo = new PDO('sqlite::memory:', null, null, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
    // Équivalent SQLite de database/migrations/001_beta_signups.sql
    $pdo->exec('CREATE TABLE beta_signups (id INTEGER PRIMARY KEY, email TEXT UNIQUE NOT NULL, source TEXT NOT NULL,
        consent_text TEXT NOT NULL, ip_hash TEXT NOT NULL, unsubscribe_token TEXT NOT NULL, created_at TEXT NOT NULL, unsubscribed_at TEXT NULL)');
    return Database::fromPdo($pdo);
}

$config = ['beta_rate_limit' => 3];
$server = ['HTTP_HOST' => 'www.exemple.fr', 'HTTP_ORIGIN' => 'https://www.exemple.fr', 'REMOTE_ADDR' => '203.0.113.7'];
$loc = static fn (Response $r) => $r->headers['Location'] ?? '';

echo "Router\n";
$r = new Router('');
$r->get('/', fn () => new Response('home'));
$r->get('/tarifs', fn () => new Response('tarifs'));
$r->post('/beta', fn () => new Response('beta'));
$r->notFound(fn () => new Response('404', 404));
check('route racine', $r->dispatch('GET', '/')->body === 'home');
check('slash final toléré', $r->dispatch('GET', '/tarifs/')->body === 'tarifs');
check('query string ignorée', $r->dispatch('GET', '/tarifs?x=1')->body === 'tarifs');
check('HEAD traité comme GET', $r->dispatch('HEAD', '/')->body === 'home');
check('404', $r->dispatch('GET', '/nope')->status === 404);
check('405 sur mauvaise méthode', $r->dispatch('GET', '/beta')->status === 405);
$sub = new Router('/site');
$sub->get('/tarifs', fn () => new Response('ok'));
check('sous-dossier (APP_BASE_PATH)', $sub->dispatch('GET', '/site/tarifs')->body === 'ok');

echo "Inscription bêta\n";
$db = memoryDb();
$c = new BetaController($db, $config);
check('email valide → ok', str_contains($loc($c->subscribe(['email' => 'Coach@Club.fr'], $server)), 'beta=ok'));
$stored = $db->pdo()->query('SELECT email, source FROM beta_signups')->fetchAll(PDO::FETCH_ASSOC);
check('stocké en minuscules', $stored === [['email' => 'coach@club.fr', 'source' => 'site']]);
check('doublon → même réponse ok', str_contains($loc($c->subscribe(['email' => 'coach@club.fr'], $server)), 'beta=ok'));
check('doublon non réinséré', (int) $db->pdo()->query('SELECT COUNT(*) FROM beta_signups')->fetchColumn() === 1);
check('email invalide', str_contains($loc($c->subscribe(['email' => 'pas-un-email'], $server)), 'beta=invalid'));
check('champ piège → ok silencieux sans stockage', str_contains($loc($c->subscribe(['email' => 'bot@x.fr', 'website' => 'spam'], $server)), 'beta=ok')
    && (int) $db->pdo()->query("SELECT COUNT(*) FROM beta_signups WHERE email='bot@x.fr'")->fetchColumn() === 0);
check('autre origine refusée', str_contains($loc($c->subscribe(['email' => 'a@b.fr'], ['HTTP_ORIGIN' => 'https://evil.test'] + $server)), 'beta=error'));
check('sans origine ni referer refusé', str_contains($loc($c->subscribe(['email' => 'a@b.fr'], ['HTTP_HOST' => 'www.exemple.fr'])), 'beta=error'));
check('referer du blog accepté', str_contains($loc($c->subscribe(['email' => 'blog@club.fr', 'source' => 'blog', 'return' => '/blog/mon-article/'],
    ['HTTP_HOST' => 'www.exemple.fr', 'HTTP_REFERER' => 'https://www.exemple.fr/blog/mon-article/', 'REMOTE_ADDR' => '198.51.100.1'])), '/blog/mon-article/?beta=ok#beta'));
check('pas de redirection ouverte', str_starts_with($loc($c->subscribe(['email' => 'x@y.fr', 'return' => '//evil.test'], ['REMOTE_ADDR' => '198.51.100.2'] + $server)), '/?beta='));
// Limite = 3 inscriptions enregistrées par IP et par heure (coach@ + l1 + l2, puis refus)
$c->subscribe(['email' => 'l1@x.fr'], $server);
check('3e inscription acceptée', str_contains($loc($c->subscribe(['email' => 'l2@x.fr'], $server)), 'beta=ok'));
check('4e inscription bloquée', str_contains($loc($c->subscribe(['email' => 'l3@x.fr'], $server)), 'beta=limit'));

echo "Aides\n";
check('prix non fixé', price(null) === '[PRIX]');
check('prix entier', price(9.0) === '9');
check('prix décimal', price(7.2) === '7,20');
check('échappement', e('<a href="x">') === '&lt;a href=&quot;x&quot;&gt;');

require __DIR__ . '/api.php';

echo "\n$passed réussi(s), $failed échec(s)\n";
exit($failed ? 1 : 0);
