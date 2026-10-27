<?php
declare(strict_types=1);

// Applique les migrations SQL non encore jouées : php app/bin/migrate.php
// Sur o2switch : ssh puis `php ~/tempsmort-app/bin/migrate.php`.
if (PHP_SAPI !== 'cli') { exit(1); }

$appDir = dirname(__DIR__);
require $appDir . '/src/Env.php';
require $appDir . '/src/Database.php';
\TempsMort\Env::load($appDir . '/.env');
$config = require $appDir . '/config/app.php';
$pdo = (new \TempsMort\Database($config['db']))->pdo();

$pdo->exec('CREATE TABLE IF NOT EXISTS schema_migrations (name VARCHAR(190) PRIMARY KEY, applied_at DATETIME NOT NULL)');
$done = $pdo->query('SELECT name FROM schema_migrations')->fetchAll(PDO::FETCH_COLUMN);

$files = glob($appDir . '/database/migrations/*.sql') ?: [];
sort($files);
$applied = 0;
foreach ($files as $file) {
    $name = basename($file);
    if (in_array($name, $done, true)) { continue; }
    echo "→ $name\n";
    $pdo->exec((string) file_get_contents($file));
    $stmt = $pdo->prepare('INSERT INTO schema_migrations (name, applied_at) VALUES (?, ?)');
    $stmt->execute([$name, date('Y-m-d H:i:s')]);
    $applied++;
}
echo $applied ? "$applied migration(s) appliquée(s).\n" : "Base à jour.\n";
