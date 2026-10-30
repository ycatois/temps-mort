<?php
declare(strict_types=1);

// Tests de l'API de l'app (compte et synchro), inclus par run.php.
use TempsMort\Api\Accounts;
use TempsMort\Api\Documents;
use TempsMort\Api\RateLimiter;
use TempsMort\Controller\ApiController;
use TempsMort\Mail\MemoryMailer;
use TempsMort\Response;
use TempsMort\Router;

/** Équivalent SQLite de database/migrations/002_api_comptes_synchro.sql. */
function apiDb(): PDO {
    $pdo = new PDO('sqlite::memory:', null, null, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC]);
    $pdo->exec('CREATE TABLE coaches (id INTEGER PRIMARY KEY AUTOINCREMENT, email TEXT UNIQUE NOT NULL, password_hash TEXT NOT NULL,
        rev INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL)');
    $pdo->exec('CREATE TABLE devices (id INTEGER PRIMARY KEY AUTOINCREMENT, coach_id INTEGER NOT NULL, token_hash TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL, created_at TEXT NOT NULL, last_seen_at TEXT NOT NULL)');
    $pdo->exec('CREATE TABLE reset_codes (email TEXT PRIMARY KEY, code_hash TEXT NOT NULL, expires_at TEXT NOT NULL, attempts INTEGER NOT NULL DEFAULT 0)');
    $pdo->exec('CREATE TABLE rate_limits (id INTEGER PRIMARY KEY AUTOINCREMENT, bucket TEXT NOT NULL, created_at TEXT NOT NULL)');
    $pdo->exec('CREATE TABLE documents (coach_id INTEGER NOT NULL, id TEXT NOT NULL, kind TEXT NOT NULL, rev INTEGER NOT NULL,
        deleted INTEGER NOT NULL DEFAULT 0, data TEXT NULL, updated_at TEXT NOT NULL, PRIMARY KEY (coach_id, id))');
    return $pdo;
}

final class ApiHarness
{
    public int $now;
    public MemoryMailer $mailer;
    public ApiController $api;
    public PDO $pdo;

    public function __construct()
    {
        $this->now = strtotime('2026-11-14 10:00:00');
        $this->pdo = apiDb();
        $this->mailer = new MemoryMailer();
        $clock = fn (): int => $this->now;
        $this->api = new ApiController(
            new Accounts($this->pdo, $this->mailer, new RateLimiter($this->pdo, $clock), str_repeat('s', 32), $clock),
            new Documents($this->pdo, $clock),
        );
    }

    /** @return array{0:int,1:array<string,mixed>} */
    public function call(string $action, array $body = [], ?string $token = null, string $ip = '203.0.113.9'): array
    {
        $server = ['TM_RAW_BODY' => json_encode($body), 'REMOTE_ADDR' => $ip];
        if ($token !== null) { $server['HTTP_AUTHORIZATION'] = 'Bearer ' . $token; }
        $r = $this->api->$action([], $server);
        return [$r->status, json_decode($r->body, true)];
    }

    public function register(string $email = 'coach@club.fr', string $password = 'un mot de passe solide'): string
    {
        [, $out] = $this->call('register', ['email' => $email, 'password' => $password, 'deviceName' => 'Tablette']);
        return $out['token'];
    }

    /** @return array<string,mixed> */
    public function sync(string $token, int $lastRev, array $changes = []): array
    {
        return $this->call('sync', ['lastRev' => $lastRev, 'changes' => $changes], $token)[1];
    }
}

$team = fn (string $name, int $base = 0) => ['id' => 't1', 'kind' => 'team', 'baseRev' => $base, 'data' => ['id' => 't1', 'name' => $name, 'players' => [['id' => 'p1', 'firstName' => 'Lucie', 'number' => 7]]]];
$events = fn (int $n, int $base = 0) => ['id' => 'events:m1', 'kind' => 'events', 'baseRev' => $base, 'data' => array_fill(0, $n, ['type' => 'rally', 'winner' => 'us'])];

echo "API · routeur\n";
$r = new Router('');
$r->delete('/api/v1/account', fn () => new Response('supprimé'));
check('DELETE routé', $r->dispatch('DELETE', '/api/v1/account')->body === 'supprimé');
check('GET sur une route DELETE : 405', $r->dispatch('GET', '/api/v1/account')->status === 405);

echo "API · compte\n";
$h = new ApiHarness();
[$status, $out] = $h->call('register', ['email' => ' Coach@Club.fr ', 'password' => 'un mot de passe solide', 'deviceName' => 'Tablette']);
check('inscription : 201 et jeton', $status === 201 && strlen($out['token']) >= 40);
$stored = $h->pdo->query('SELECT email, password_hash FROM coaches')->fetch();
check('adresse en minuscules, mot de passe haché', $stored['email'] === 'coach@club.fr' && password_verify('un mot de passe solide', $stored['password_hash'])
    && !str_contains($stored['password_hash'], 'solide'));
check('jeton stocké seulement en empreinte', $h->pdo->query('SELECT token_hash FROM devices')->fetchColumn() === hash('sha256', $out['token']));
check('adresse déjà prise : 409', $h->call('register', ['email' => 'coach@club.fr', 'password' => 'un mot de passe solide'])[0] === 409);
[$status, $out] = $h->call('register', ['email' => 'autre@club.fr', 'password' => 'court']);
check('mot de passe trop court : 400 et message', $status === 400 && $out['error']['code'] === 'weak_password' && str_contains($out['error']['message'], '12'));
check('adresse invalide : 400', $h->call('register', ['email' => 'pas-une-adresse', 'password' => 'un mot de passe solide'])[1]['error']['code'] === 'bad_email');
check('JSON illisible : 400', $h->api->register([], ['TM_RAW_BODY' => '{pas du json'])->status === 400);

[$status, $out] = $h->call('login', ['email' => 'coach@club.fr', 'password' => 'un mot de passe solide', 'deviceName' => 'Téléphone']);
check('connexion : jeton d\'un second appareil', $status === 200 && (int) $h->pdo->query('SELECT COUNT(*) FROM devices')->fetchColumn() === 2);
$wrong = $h->call('login', ['email' => 'coach@club.fr', 'password' => 'mauvais mot de passe']);
$unknown = $h->call('login', ['email' => 'inconnu@club.fr', 'password' => 'mauvais mot de passe']);
check('mauvais mot de passe ou adresse inconnue : même réponse 401', $wrong[0] === 401 && $wrong === $unknown);
// 10 essais faux au plus par quart d'heure : 1 déjà fait, 9 de plus, le suivant est refusé même juste.
for ($i = 0; $i < 9; $i++) { $h->call('login', ['email' => 'coach@club.fr', 'password' => 'mauvais mot de passe']); }
check('trop de tentatives : 429', $h->call('login', ['email' => 'coach@club.fr', 'password' => 'un mot de passe solide'])[0] === 429);
$h->now += 901;
check('un quart d\'heure plus tard, la connexion repasse', $h->call('login', ['email' => 'coach@club.fr', 'password' => 'un mot de passe solide'])[0] === 200);

echo "API · synchro\n";
$h = new ApiHarness();
$tablet = $h->register();
[, $login] = $h->call('login', ['email' => 'coach@club.fr', 'password' => 'un mot de passe solide', 'deviceName' => 'Téléphone']);
$phone = $login['token'];
check('sans jeton : 401', $h->call('sync', ['lastRev' => 0])[0] === 401);
check('jeton inconnu : 401', $h->call('sync', ['lastRev' => 0], 'faux')[0] === 401);

$out = $h->sync($tablet, 0, [$team('M15 filles'), $events(3)]);
check('la tablette pousse : révisions attribuées, rien à tirer', $out['rev'] === 2 && $out['pushed'] === ['t1' => 1, 'events:m1' => 2] && $out['changes'] === []);
$out = $h->sync($phone, 0);
check('le téléphone tire les deux documents', count($out['changes']) === 2 && $out['changes'][0]['data']['name'] === 'M15 filles' && $out['rev'] === 2);
check('accents conservés', $out['changes'][0]['data']['players'][0]['firstName'] === 'Lucie');
check('rien de neuf après la dernière révision', $h->sync($phone, 2)['changes'] === []);

// Le téléphone renomme l'équipe en connaissant la révision 1 ; la tablette, en retard, la renomme aussi.
$h->sync($phone, 2, [$team('M15 F', 1)]);
$out = $h->sync($tablet, 2, [$team('M15 Filles 2026', 1)]);
check('conflit sur une équipe : la dernière modification gagne, signalé', $out['conflicts'] === ['t1'] && isset($out['pushed']['t1']));
check('le téléphone reçoit le nom de la tablette', $h->sync($phone, 3)['changes'][0]['data']['name'] === 'M15 Filles 2026');

// Événements d'un match : le journal le plus long l'emporte.
$h->sync($phone, 0, [$events(10, 2)]);
$out = $h->sync($tablet, 4, [$events(5, 2)]);
check('conflit sur un match : le journal le plus long reste', $out['conflicts'] === ['events:m1'] && !isset($out['pushed']['events:m1'])
    && count($out['changes'][0]['data']) === 10);

// Suppression (RGPD) : le contenu disparaît du serveur, la marque reste.
$out = $h->sync($tablet, 5, [['id' => 't1', 'kind' => 'team', 'baseRev' => 4, 'deleted' => true]]);
$row = $h->pdo->query("SELECT deleted, data FROM documents WHERE id = 't1'")->fetch();
check('pierre tombale : contenu effacé', (int) $row['deleted'] === 1 && $row['data'] === null);
$pulled = $h->sync($phone, 5)['changes'];
check('l\'autre appareil apprend la suppression', $pulled[0]['id'] === 't1' && $pulled[0]['deleted'] === true && $pulled[0]['data'] === null);

check('identifiant invalide : 400', $h->call('sync', ['lastRev' => 0, 'changes' => [['id' => '../x', 'kind' => 'team', 'data' => []]]], $tablet)[0] === 400);
check('nature inconnue : 400', $h->call('sync', ['lastRev' => 0, 'changes' => [['id' => 'x', 'kind' => 'photo', 'data' => []]]], $tablet)[0] === 400);
check('changement de nature : 400', $h->call('sync', ['lastRev' => 0, 'changes' => [['id' => 'events:m1', 'kind' => 'team', 'baseRev' => 9, 'data' => []]]], $tablet)[0] === 400);
check('lastRev invalide : 400', $h->call('sync', ['lastRev' => 'x'], $tablet)[0] === 400);
$before = $h->sync($tablet, 0)['rev'];
$h->call('sync', ['lastRev' => 0, 'changes' => [$team('A'), ['id' => 'bad id', 'kind' => 'team', 'data' => []]]], $tablet);
check('envoi refusé : rien n\'est écrit', $h->sync($tablet, 0)['rev'] === $before);

$other = $h->register('autre@club.fr');
check('chaque coach ne voit que ses documents', $h->sync($other, 0)['changes'] === []);
$h->sync($other, 0, [$team('Seniors')]);
$mine = array_values(array_filter($h->sync($tablet, 0)['changes'], fn ($c) => $c['id'] === 't1'));
check('même identifiant chez un autre coach : aucun mélange', $mine[0]['deleted'] === true);

echo "API · mot de passe oublié\n";
$h = new ApiHarness();
$old = $h->register();
[$status] = $h->call('resetCode', ['email' => 'inconnu@club.fr']);
check('adresse inconnue : même réponse, aucun e-mail', $status === 200 && $h->mailer->sent === []);
$h->call('resetCode', ['email' => 'coach@club.fr']);
check('e-mail envoyé avec un code à 6 chiffres', count($h->mailer->sent) === 1 && preg_match('/\b(\d{6})\b/', $h->mailer->sent[0]['body'], $m) === 1);
$code = $m[1];
$wrongCode = $code === '000000' ? '111111' : '000000';
check('code faux : 400', $h->call('reset', ['email' => 'coach@club.fr', 'code' => $wrongCode, 'newPassword' => 'nouveau mot de passe'])[0] === 400);
[$status, $out] = $h->call('reset', ['email' => 'coach@club.fr', 'code' => $code, 'newPassword' => 'nouveau mot de passe', 'deviceName' => 'Tablette']);
check('bon code : nouveau mot de passe et nouveau jeton', $status === 200 && $h->sync($out['token'], 0)['rev'] === 0);
check('les autres appareils sont déconnectés', $h->call('sync', ['lastRev' => 0], $old)[0] === 401);
check('le code ne sert qu\'une fois', $h->call('reset', ['email' => 'coach@club.fr', 'code' => $code, 'newPassword' => 'encore un autre mot'])[0] === 400);
check('connexion avec le nouveau mot de passe', $h->call('login', ['email' => 'coach@club.fr', 'password' => 'nouveau mot de passe'])[0] === 200);

$h->call('resetCode', ['email' => 'coach@club.fr']);
preg_match('/\b(\d{6})\b/', end($h->mailer->sent)['body'], $m);
$h->now += 601;
check('code expiré après 10 minutes', $h->call('reset', ['email' => 'coach@club.fr', 'code' => $m[1], 'newPassword' => 'nouveau mot de passe'])[0] === 400);
$h->call('resetCode', ['email' => 'coach@club.fr']);
preg_match('/\b(\d{6})\b/', end($h->mailer->sent)['body'], $m);
for ($i = 0; $i < 5; $i++) {
    $h->call('reset', ['email' => 'coach@club.fr', 'code' => $m[1] === '000000' ? '111111' : '000000', 'newPassword' => 'nouveau mot de passe']);
}
check('après 5 codes faux, même le bon est refusé', $h->call('reset', ['email' => 'coach@club.fr', 'code' => $m[1], 'newPassword' => 'nouveau mot de passe'])[0] === 400);
check('4e demande de code dans l\'heure : 429', $h->call('resetCode', ['email' => 'coach@club.fr'])[0] === 429);

echo "API · déconnexion et suppression du compte\n";
$h = new ApiHarness();
$token = $h->register();
$h->sync($token, 0, [$team('M15')]);
check('déconnexion : le jeton ne marche plus', $h->call('logout', [], $token)[0] === 200 && $h->call('sync', ['lastRev' => 0], $token)[0] === 401);
[, $login] = $h->call('login', ['email' => 'coach@club.fr', 'password' => 'un mot de passe solide']);
check('suppression : mot de passe exigé', $h->call('deleteAccount', ['password' => 'mauvais mot de passe'], $login['token'])[0] === 401);
check('suppression du compte : 200', $h->call('deleteAccount', ['password' => 'un mot de passe solide'], $login['token'])[0] === 200);
$left = static fn (string $table) => (int) $h->pdo->query("SELECT COUNT(*) FROM $table")->fetchColumn();
check('compte, appareils et documents effacés', $left('coaches') === 0 && $left('devices') === 0 && $left('documents') === 0);

echo "API · requêtes SQL\n";
// SQLite accepte un paramètre nommé répété dans une requête ; MariaDB (requêtes préparées natives) le refuse.
$repeated = [];
foreach (new RecursiveIteratorIterator(new RecursiveDirectoryIterator(dirname(__DIR__) . '/app/src')) as $file) {
    if ($file->getExtension() !== 'php') { continue; }
    preg_match_all("/'((?:SELECT|INSERT|UPDATE|DELETE)[^']*)'/", (string) file_get_contents($file->getPathname()), $sql);
    foreach ($sql[1] as $query) {
        preg_match_all('/(?<!:):([a-z_]+)/', $query, $names);
        if (count($names[1]) !== count(array_unique($names[1]))) { $repeated[] = $file->getFilename() . ' : ' . $query; }
    }
}
check('aucun paramètre nommé répété dans une requête' . ($repeated ? ' (' . implode(' | ', $repeated) . ')' : ''), $repeated === []);

echo "API · corrections de la relecture\n";
$h = new ApiHarness();
$tablet = $h->register();
[, $login] = $h->call('login', ['email' => 'coach@club.fr', 'password' => 'un mot de passe solide', 'deviceName' => 'Téléphone']);
$phone = $login['token'];
$h->sync($tablet, 0, [$team('M15')]);                                        // rev 1
$h->sync($tablet, 1, [['id' => 't1', 'kind' => 'team', 'baseRev' => 1, 'deleted' => true]]);   // rev 2 : supprimée (RGPD)
$out = $h->sync($phone, 1, [$team('M15 renommée hors ligne', 1)]);          // le téléphone ne le sait pas
check('une modification restée hors ligne ne ressuscite pas une suppression', $out['conflicts'] === ['t1'] && !isset($out['pushed']['t1'])
    && $h->pdo->query("SELECT data FROM documents WHERE id = 't1'")->fetchColumn() === null);
check('le téléphone reçoit la suppression', $out['changes'][0]['id'] === 't1' && $out['changes'][0]['deleted'] === true);
$out = $h->sync($phone, 2, [$team('Encore', 1)]);
check('conflit perdu : la version du serveur est renvoyée même déjà connue', $out['changes'][0]['id'] === 't1' && $out['changes'][0]['rev'] === 2);

$h = new ApiHarness();
for ($i = 1; $i <= 5; $i++) { $h->register("c$i@club.fr"); }
check('6e compte créé depuis le même réseau dans l\'heure : 429',
    $h->call('register', ['email' => 'c6@club.fr', 'password' => 'un mot de passe solide'])[0] === 429);
check('depuis un autre réseau, l\'inscription passe',
    $h->call('register', ['email' => 'c6@club.fr', 'password' => 'un mot de passe solide'], ip: '198.51.100.20')[0] === 201);

$h = new ApiHarness();
$h->register();
for ($i = 0; $i < 11; $i++) { $h->call('login', ['email' => 'coach@club.fr', 'password' => 'mauvais mot de passe'], ip: '192.0.2.66'); }
check('un tiers bloqué sur son réseau…', $h->call('login', ['email' => 'coach@club.fr', 'password' => 'un mot de passe solide'], ip: '192.0.2.66')[0] === 429);
check('… ne bloque pas le coach ailleurs', $h->call('login', ['email' => 'coach@club.fr', 'password' => 'un mot de passe solide'])[0] === 200);

$h->call('resetCode', ['email' => 'coach@club.fr']);
[, $login] = $h->call('login', ['email' => 'coach@club.fr', 'password' => 'un mot de passe solide']);
$h->call('deleteAccount', ['password' => 'un mot de passe solide'], $login['token']);
check('suppression du compte : le code en attente part aussi', (int) $h->pdo->query('SELECT COUNT(*) FROM reset_codes')->fetchColumn() === 0);

$h = new ApiHarness();
$small = new ApiController(
    new Accounts($h->pdo, $h->mailer, new RateLimiter($h->pdo, fn () => $h->now), str_repeat('s', 32), fn () => $h->now),
    new Documents($h->pdo, fn () => $h->now, maxDocuments: 2),
);
$token = $h->register();
$quota = fn (array $changes) => $small->sync([], ['TM_RAW_BODY' => json_encode(['lastRev' => 0, 'changes' => $changes]), 'HTTP_AUTHORIZATION' => "Bearer $token"]);
$r = $quota([$team('A'), $events(1)]);
check('sous le plafond : accepté', $r->status === 200);
$r = $quota([['id' => 'x', 'kind' => 'play', 'baseRev' => 0, 'data' => ['a' => 1]]]);
check('au-delà du plafond de documents : 507, rien d\'écrit', $r->status === 507
    && (int) $h->pdo->query("SELECT COUNT(*) FROM documents WHERE id = 'x'")->fetchColumn() === 0);
