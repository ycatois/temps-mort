<?php
declare(strict_types=1);

use TempsMort\Api\Accounts;
use TempsMort\Api\Documents;
use TempsMort\Api\RateLimiter;
use TempsMort\Controller\ApiController;
use TempsMort\Controller\BetaController;
use TempsMort\Controller\PageController;
use TempsMort\Database;
use TempsMort\Env;
use TempsMort\Kernel;
use TempsMort\Mail\PhpMailer;
use TempsMort\Mail\SmtpMailer;
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

// API de l'app mobile (compte et synchro). Objets créés à la demande : le site n'ouvre pas la base pour rien.
$api = static function (string $action) use ($db, $config): callable {
    return static function (array $post, array $server) use ($action, $db, $config) {
        if (strlen($config['secret']) < 32) {
            error_log('APP_SECRET manquant ou trop court : API désactivée');
            return new \TempsMort\Response('{"error":{"code":"not_configured","message":"Service indisponible."}}', 503,
                ['Content-Type' => 'application/json; charset=utf-8']);
        }
        $pdo = $db->pdo();
        $clock = static fn (): int => time();
        $mail = $config['mail'];
        $mailer = $mail['smtp_host'] !== '' ? new SmtpMailer($mail['smtp_host'], $mail['smtp_port'], $mail['from']) : new PhpMailer($mail['from']);
        $controller = new ApiController(
            new Accounts($pdo, $mailer, new RateLimiter($pdo, $clock), $config['secret'], $clock),
            new Documents($pdo, $clock),
        );
        return $controller->$action($post, $server);
    };
};
$router->post('/api/v1/auth/register', $api('register'));
$router->post('/api/v1/auth/login', $api('login'));
$router->post('/api/v1/auth/reset-code', $api('resetCode'));
$router->post('/api/v1/auth/reset', $api('reset'));
$router->post('/api/v1/auth/logout', $api('logout'));
$router->post('/api/v1/sync', $api('sync'));
$router->delete('/api/v1/account', $api('deleteAccount'));

$router->notFound([$pages, 'notFound']);

return new Kernel($router);
