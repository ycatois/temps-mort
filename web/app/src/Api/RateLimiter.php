<?php
declare(strict_types=1);

namespace TempsMort\Api;

use PDO;

/** Limite de tentatives par « seau » (ex. connexions d'une adresse) sur une fenêtre glissante. */
final class RateLimiter
{
    /** @param \Closure():int $clock */
    public function __construct(private readonly PDO $pdo, private readonly \Closure $clock) {}

    /** Enregistre une tentative et dit si elle reste sous la limite de [$max] par [$seconds] secondes. */
    public function hit(string $bucket, int $max, int $seconds): bool
    {
        $key = hash('sha256', $bucket);
        $now = ($this->clock)();
        // Purge au fil de l'eau : au-delà d'un jour, une tentative n'a plus d'intérêt.
        $this->pdo->prepare('DELETE FROM rate_limits WHERE created_at < :old')->execute(['old' => date('Y-m-d H:i:s', $now - 86400)]);

        // D'abord enregistrer, ensuite compter : des requêtes envoyées en même temps se voient les unes
        // les autres et ne passent pas toutes sous la limite.
        $this->pdo->prepare('INSERT INTO rate_limits (bucket, created_at) VALUES (:b, :now)')
            ->execute(['b' => $key, 'now' => date('Y-m-d H:i:s', $now)]);
        $count = $this->pdo->prepare('SELECT COUNT(*) FROM rate_limits WHERE bucket = :b AND created_at >= :since');
        $count->execute(['b' => $key, 'since' => date('Y-m-d H:i:s', $now - $seconds)]);
        return (int) $count->fetchColumn() <= $max;
    }

    /** Efface les tentatives d'un seau (connexion réussie). */
    public function clear(string $bucket): void
    {
        $this->pdo->prepare('DELETE FROM rate_limits WHERE bucket = :b')->execute(['b' => hash('sha256', $bucket)]);
    }
}
