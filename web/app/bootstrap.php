<?php
declare(strict_types=1);

use TempsMort\Controller\BetaController;
use TempsMort\Controller\PageController;
use TempsMort\Database;
use TempsMort\Env;
use TempsMort\Kernel;
use TempsMort\Router;
use TempsMort\View;

define('APP_DIR', __DIR__);

spl_autoload_register(static function (string $class): void {
    $prefix = 'TempsMort\\';
    if (strncmp($class, $prefix, strlen($prefix)) !== 0) { return; }
    $file = __DIR__ . '/src/' . str_replace('\\', '/', substr($class, strlen($prefix))) . '.php';
    if (is_file($file)) { require $file; }
});

require __DIR__ . '/src/helpers.php';

Env::load(__DIR__ . '/.env');
$config = require __DIR__ . '/config/app.php';

if ($config['debug']) {
    ini_set('display_errors', '1');
    error_reporting(E_ALL);
} else {
    ini_set('display_errors', '0');
    ini_set('log_errors', '1');
    ini_set('error_log', __DIR__ . '/var/log/php-error.log');
}
date_default_timezone_set('Europe/Paris');

$view = new View(__DIR__ . '/templates', $config);
$db = new Database($config['db']);

$router = new Router($config['base_path']);
$pages = new PageController($view, $config);
$beta = new BetaController($db, $config);

$router->get('/', [$pages, 'home']);
$router->get('/tarifs', [$pages, 'pricing']);
$router->get('/mentions-legales', [$pages, 'legal']);
$router->get('/confidentialite', [$pages, 'privacy']);
$router->post('/beta', [$beta, 'subscribe']);
$router->notFound([$pages, 'notFound']);

return new Kernel($router);
