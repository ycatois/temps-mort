<?php
declare(strict_types=1);

namespace TempsMort\Controller;

use TempsMort\BetaSignups;
use TempsMort\Database;
use TempsMort\Response;

/**
 * POST /beta — inscription à la bêta depuis le site ou le blog.
 * Pas de session : protection par contrôle d'origine (même hôte), champ piège et limite par IP.
 * Répond toujours par une redirection (PRG) avec ?beta=ok|invalid|limit|error.
 */
final class BetaController
{
    /** @param array<string,mixed> $config */
    public function __construct(private readonly Database $db, private readonly array $config) {}

    /** @param array<string,mixed> $post @param array<string,mixed> $server */
    public function subscribe(array $post, array $server): Response
    {
        $back = $this->returnPath((string) ($post['return'] ?? '/'));
        $go = fn (string $status) => Response::redirect($this->withStatus($back, $status) . '#beta');

        if (!$this->sameOrigin($server)) { return $go('error'); }
        if (trim((string) ($post['website'] ?? '')) !== '') { return $go('ok'); } // robot : on ne dit rien

        $email = strtolower(trim((string) ($post['email'] ?? '')));
        if ($email === '' || strlen($email) > 190 || filter_var($email, FILTER_VALIDATE_EMAIL) === false) {
            return $go('invalid');
        }

        $source = in_array($post['source'] ?? '', ['site', 'blog'], true) ? $post['source'] : 'site';
        $ipHash = hash('sha256', ($server['REMOTE_ADDR'] ?? '') . '|' . date('Y-m-d'));

        try {
            $signups = new BetaSignups($this->db->pdo());
            if ($signups->countRecentByIp($ipHash) >= (int) $this->config['beta_rate_limit']) { return $go('limit'); }
            $signups->add($email, $source, $ipHash);
        } catch (\PDOException $e) {
            error_log('beta signup: ' . $e->getMessage());
            return $go('error');
        }
        // Même réponse pour une adresse déjà inscrite : on ne révèle pas qui est inscrit.
        return $go('ok');
    }

    /** @param array<string,mixed> $server */
    private function sameOrigin(array $server): bool
    {
        $host = strtolower((string) ($server['HTTP_HOST'] ?? ''));
        $origin = (string) ($server['HTTP_ORIGIN'] ?? $server['HTTP_REFERER'] ?? '');
        if ($origin === '' || $host === '') { return false; }
        return strtolower((string) parse_url($origin, PHP_URL_HOST)) . (parse_url($origin, PHP_URL_PORT) ? ':' . parse_url($origin, PHP_URL_PORT) : '') === $host;
    }

    /** N'accepte qu'un chemin relatif du même site (pas de redirection ouverte). */
    private function returnPath(string $path): string
    {
        if (!str_starts_with($path, '/') || str_starts_with($path, '//') || str_contains($path, '\\')) { return '/'; }
        return strtok($path, '#') ?: '/';
    }

    private function withStatus(string $path, string $status): string
    {
        $path = preg_replace('/([?&])beta=[^&]*(&|$)/', '$1', $path) ?? $path;
        $path = rtrim($path, '?&');
        return $path . (str_contains($path, '?') ? '&' : '?') . 'beta=' . $status;
    }
}
