<?php
declare(strict_types=1);

/** Échappement HTML : à utiliser pour toute donnée affichée dans un gabarit. */
function e(mixed $value): string
{
    return htmlspecialchars((string) $value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

/** URL interne tenant compte d'un éventuel sous-dossier (APP_BASE_PATH). */
function url(array $config, string $path = '/'): string
{
    return ($config['base_path'] ?? '') . $path;
}

/** Version d'un fichier statique pour casser le cache après déploiement. */
function asset(array $config, string $path): string
{
    $file = dirname(__DIR__, 2) . '/public/' . $path;
    if (!is_file($file)) { $file = ($_SERVER['DOCUMENT_ROOT'] ?? '') . '/' . $path; }
    $v = is_file($file) ? (string) filemtime($file) : '1';
    return url($config, '/' . $path) . '?v=' . $v;
}

/** Prix TTC formaté à la française, ou « [PRIX] » tant qu'il n'est pas fixé. */
function price(?float $amount): string
{
    if ($amount === null) { return '[PRIX]'; }
    $decimals = floor($amount) == $amount ? 0 : 2;
    return number_format($amount, $decimals, ',', "\u{202F}");
}
