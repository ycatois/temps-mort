<?php
declare(strict_types=1);

namespace TempsMort;

use PDO;

final class BetaSignups
{
    public const CONSENT_TEXT = 'Un email au lancement, puis un par mois au plus. Désinscription en un clic.';

    public function __construct(private readonly PDO $pdo) {}

    public function countRecentByIp(string $ipHash): int
    {
        $stmt = $this->pdo->prepare('SELECT COUNT(*) FROM beta_signups WHERE ip_hash = :ip AND created_at >= :since');
        $stmt->execute(['ip' => $ipHash, 'since' => date('Y-m-d H:i:s', time() - 3600)]);
        return (int) $stmt->fetchColumn();
    }

    /** Ajoute l'adresse ; renvoie false si elle était déjà inscrite. */
    public function add(string $email, string $source, string $ipHash): bool
    {
        $exists = $this->pdo->prepare('SELECT 1 FROM beta_signups WHERE email = :email');
        $exists->execute(['email' => $email]);
        if ($exists->fetchColumn()) { return false; }

        $stmt = $this->pdo->prepare(
            'INSERT INTO beta_signups (email, source, consent_text, ip_hash, unsubscribe_token, created_at)
             VALUES (:email, :source, :consent, :ip, :token, :now)'
        );
        $stmt->execute([
            'email' => $email,
            'source' => $source,
            'consent' => self::CONSENT_TEXT,
            'ip' => $ipHash,
            'token' => bin2hex(random_bytes(16)),
            'now' => date('Y-m-d H:i:s'),
        ]);
        return true;
    }
}
