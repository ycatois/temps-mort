<?php
// Serveur de dev sans Apache : php -S localhost:8080 -t web/public web/dev-router.php
$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
if ($path !== '/' && is_file(__DIR__ . '/public' . $path)) {
    return false; // fichier statique
}
require __DIR__ . '/public/index.php';
