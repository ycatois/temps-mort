<?php
declare(strict_types=1);

// Front controller. En local, le code applicatif est dans ../app ;
// sur o2switch, public/ est déployé dans ~/public_html et app/ dans ~/tempsmort-app (hors web).
$appDir = null;
foreach ([__DIR__ . '/../tempsmort-app', __DIR__ . '/../app'] as $candidate) {
    if (is_file($candidate . '/bootstrap.php')) { $appDir = realpath($candidate); break; }
}
if ($appDir === null) {
    http_response_code(500);
    exit('Application introuvable.');
}

$app = require $appDir . '/bootstrap.php';
$app->run();
