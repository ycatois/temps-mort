<?php
declare(strict_types=1);

namespace TempsMort\Api;

use PDO;
use TempsMort\Mail\Mailer;

/**
 * Comptes coach (V1-EQU-01) : e-mail et mot de passe, un jeton par appareil, mot de passe oublié
 * par code à 6 chiffres. Voir docs/compte-et-synchro.md.
 */
final class Accounts
{
    public const MIN_PASSWORD = 12;
    private const CODE_TTL = 600;          // 10 minutes
    private const CODE_ATTEMPTS = 5;

    /** Empreinte factice, calculée une fois : vérifiée pour une adresse inconnue, à la même vitesse. */
    private static ?string $dummyHash = null;

    /** @param \Closure():int $clock */
    public function __construct(
        private readonly PDO $pdo,
        private readonly Mailer $mailer,
        private readonly RateLimiter $limits,
        private readonly string $secret,
        private readonly \Closure $clock,
    ) {}

    /** Crée le compte et connecte l'appareil. Renvoie le jeton d'appareil. */
    public function register(string $email, string $password, string $deviceName, string $ip): string
    {
        $email = $this->email($email);
        $this->checkPassword($password);
        // Pas de création de comptes en série : elle remplirait la base du serveur mutualisé.
        if (!$this->limits->hit('register-ip:' . $ip, 5, 3600)) {
            throw new ApiError(429, 'too_many_attempts', 'Trop de comptes créés depuis ce réseau. Réessayez dans une heure.');
        }
        $taken = new ApiError(409, 'email_taken', 'Un compte existe déjà avec cette adresse. Connectez-vous, ou utilisez « Mot de passe oublié ».');
        $exists = $this->pdo->prepare('SELECT 1 FROM coaches WHERE email = :e');
        $exists->execute(['e' => $email]);
        if ($exists->fetchColumn()) { throw $taken; }

        $this->pdo->beginTransaction();
        try {
            $this->pdo->prepare('INSERT INTO coaches (email, password_hash, rev, created_at) VALUES (:e, :h, 0, :now)')
                ->execute(['e' => $email, 'h' => $this->hash($password), 'now' => $this->now()]);
            $token = $this->newDevice((int) $this->pdo->lastInsertId(), $deviceName);
            $this->pdo->commit();
            return $token;
        } catch (\PDOException $e) {
            $this->pdo->rollBack();
            // Deux inscriptions simultanées avec la même adresse : la seconde bute sur la clé unique.
            if ($e->getCode() === '23000' || str_starts_with((string) $e->getCode(), '23')) { throw $taken; }
            throw $e;
        }
    }

    /** Connexion d'un appareil. Même réponse que l'adresse soit inconnue ou le mot de passe faux. */
    public function login(string $email, string $password, string $deviceName, string $ip): string
    {
        $email = $this->email($email);
        // Par adresse et réseau (10), par réseau (30), et un plafond plus haut par adresse (50) : un tiers
        // ne bloque pas un coach en essayant son adresse depuis un seul endroit.
        if (!$this->limits->hit('login:' . $email . '|' . $ip, 10, 900)
            || !$this->limits->hit('login-ip:' . $ip, 30, 900)
            || !$this->limits->hit('login:' . $email, 50, 900)) {
            throw new ApiError(429, 'too_many_attempts', 'Trop de tentatives. Réessayez dans un quart d\'heure.');
        }
        $stmt = $this->pdo->prepare('SELECT id, password_hash FROM coaches WHERE email = :e');
        $stmt->execute(['e' => $email]);
        $coach = $stmt->fetch(PDO::FETCH_ASSOC);
        // Sans compte, on vérifie quand même un mot de passe contre une vraie empreinte : même durée de
        // réponse, on ne devine pas quelles adresses ont un compte.
        $hash = $coach === false ? (self::$dummyHash ??= $this->hash(bin2hex(random_bytes(16)))) : (string) $coach['password_hash'];
        if (!password_verify($password, $hash) || $coach === false) {
            throw new ApiError(401, 'bad_credentials', 'Adresse ou mot de passe incorrect.');
        }
        if (password_needs_rehash($hash, $this->algorithm())) {
            $this->pdo->prepare('UPDATE coaches SET password_hash = :h WHERE id = :id')
                ->execute(['h' => $this->hash($password), 'id' => $coach['id']]);
        }
        $this->limits->clear('login:' . $email . '|' . $ip);
        return $this->newDevice((int) $coach['id'], $deviceName);
    }

    /** Coach et appareil du jeton, ou erreur 401. Met à jour la dernière activité de l'appareil. */
    public function authenticate(string $token): array
    {
        if ($token === '') { throw new ApiError(401, 'unauthenticated', 'Connectez-vous pour synchroniser.'); }
        $stmt = $this->pdo->prepare('SELECT d.id AS device_id, d.coach_id, c.email FROM devices d JOIN coaches c ON c.id = d.coach_id WHERE d.token_hash = :t');
        $stmt->execute(['t' => hash('sha256', $token)]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if ($row === false) { throw new ApiError(401, 'unauthenticated', 'Cet appareil a été déconnecté. Reconnectez-vous.'); }
        $this->pdo->prepare('UPDATE devices SET last_seen_at = :now WHERE id = :id')->execute(['now' => $this->now(), 'id' => $row['device_id']]);
        return ['coach_id' => (int) $row['coach_id'], 'device_id' => (int) $row['device_id'], 'email' => (string) $row['email']];
    }

    public function logout(int $deviceId): void
    {
        $this->pdo->prepare('DELETE FROM devices WHERE id = :id')->execute(['id' => $deviceId]);
    }

    /** Envoie un code si l'adresse a un compte ; ne dit jamais si elle en a un. */
    public function sendResetCode(string $email, string $ip): void
    {
        $email = $this->email($email);
        if (!$this->limits->hit('reset:' . $email . '|' . $ip, 3, 3600)
            || !$this->limits->hit('reset-ip:' . $ip, 10, 3600)
            || !$this->limits->hit('reset:' . $email, 10, 3600)) {
            throw new ApiError(429, 'too_many_attempts', 'Trop de demandes. Réessayez dans une heure.');
        }
        // Codes expirés : rien à garder (adresse comprise).
        $this->pdo->prepare('DELETE FROM reset_codes WHERE expires_at < :now')->execute(['now' => $this->now()]);
        $exists = $this->pdo->prepare('SELECT 1 FROM coaches WHERE email = :e');
        $exists->execute(['e' => $email]);
        if (!$exists->fetchColumn()) { return; }

        $code = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        $this->pdo->prepare('DELETE FROM reset_codes WHERE email = :e')->execute(['e' => $email]);
        $this->pdo->prepare('INSERT INTO reset_codes (email, code_hash, expires_at, attempts) VALUES (:e, :h, :x, 0)')
            ->execute(['e' => $email, 'h' => $this->codeHash($email, $code), 'x' => date('Y-m-d H:i:s', ($this->clock)() + self::CODE_TTL)]);
        $this->mailer->send($email, 'Temps Mort : votre code', implode("\n", [
            'Bonjour,',
            '',
            "Votre code pour choisir un nouveau mot de passe : $code",
            'Il est valable 10 minutes.',
            '',
            'Si vous n\'avez rien demandé, ignorez ce message : votre mot de passe ne change pas.',
            '',
            'Temps Mort',
        ]));
    }

    /** Nouveau mot de passe avec le code reçu : les autres appareils sont déconnectés. Renvoie un jeton. */
    public function resetPassword(string $email, string $code, string $password, string $deviceName): string
    {
        $email = $this->email($email);
        $this->checkPassword($password);
        $invalid = new ApiError(400, 'bad_code', 'Code incorrect ou expiré. Demandez-en un nouveau.');
        // Chaque essai consomme une tentative AVANT la comparaison, en une seule requête : des essais
        // envoyés en parallèle ne dépassent pas les 5 autorisés.
        $use = $this->pdo->prepare('UPDATE reset_codes SET attempts = attempts + 1 WHERE email = :e AND attempts < :max AND expires_at >= :now');
        $use->execute(['e' => $email, 'max' => self::CODE_ATTEMPTS, 'now' => $this->now()]);
        if ($use->rowCount() !== 1) { throw $invalid; }
        $stmt = $this->pdo->prepare('SELECT code_hash FROM reset_codes WHERE email = :e');
        $stmt->execute(['e' => $email]);
        if (!hash_equals((string) $stmt->fetchColumn(), $this->codeHash($email, trim($code)))) { throw $invalid; }
        $this->pdo->prepare('DELETE FROM reset_codes WHERE email = :e')->execute(['e' => $email]);
        $coach = $this->pdo->prepare('SELECT id FROM coaches WHERE email = :e');
        $coach->execute(['e' => $email]);
        $id = (int) $coach->fetchColumn();
        $this->pdo->prepare('UPDATE coaches SET password_hash = :h WHERE id = :id')->execute(['h' => $this->hash($password), 'id' => $id]);
        $this->pdo->prepare('DELETE FROM devices WHERE coach_id = :id')->execute(['id' => $id]);
        return $this->newDevice($id, $deviceName);
    }

    /** Suppression du compte (RGPD) : appareils et documents partent avec lui (clés étrangères). */
    public function deleteAccount(int $coachId, string $password): void
    {
        $stmt = $this->pdo->prepare('SELECT email, password_hash FROM coaches WHERE id = :id');
        $stmt->execute(['id' => $coachId]);
        $coach = $stmt->fetch(PDO::FETCH_ASSOC);
        if ($coach === false || !password_verify($password, (string) $coach['password_hash'])) {
            throw new ApiError(401, 'bad_credentials', 'Mot de passe incorrect.');
        }
        $this->pdo->beginTransaction();
        try {
            // Explicite plutôt que de compter sur les clés étrangères (SQLite des tests ne les active pas).
            foreach (['documents', 'devices'] as $table) {
                $this->pdo->prepare("DELETE FROM $table WHERE coach_id = :id")->execute(['id' => $coachId]);
            }
            $this->pdo->prepare('DELETE FROM reset_codes WHERE email = :e')->execute(['e' => $coach['email']]);
            $this->pdo->prepare('DELETE FROM coaches WHERE id = :id')->execute(['id' => $coachId]);
            $this->pdo->commit();
        } catch (\Throwable $e) {
            $this->pdo->rollBack();
            throw $e;
        }
    }

    private function newDevice(int $coachId, string $name): string
    {
        $token = rtrim(strtr(base64_encode(random_bytes(32)), '+/', '-_'), '=');
        $name = mb_substr(trim($name) !== '' ? trim($name) : 'Appareil', 0, 100);
        // Un paramètre nommé ne peut servir qu'une fois avec les vraies requêtes préparées de MariaDB.
        $this->pdo->prepare('INSERT INTO devices (coach_id, token_hash, name, created_at, last_seen_at) VALUES (:c, :t, :n, :created, :seen)')
            ->execute(['c' => $coachId, 't' => hash('sha256', $token), 'n' => $name, 'created' => $this->now(), 'seen' => $this->now()]);
        return $token;
    }

    private function email(string $email): string
    {
        $email = strtolower(trim($email));
        if ($email === '' || strlen($email) > 190 || filter_var($email, FILTER_VALIDATE_EMAIL) === false) {
            throw new ApiError(400, 'bad_email', 'Adresse e-mail invalide.');
        }
        return $email;
    }

    private function checkPassword(string $password): void
    {
        if (mb_strlen($password) < self::MIN_PASSWORD) {
            throw new ApiError(400, 'weak_password', 'Le mot de passe doit faire au moins ' . self::MIN_PASSWORD . ' caractères.');
        }
        if (strlen($password) > 1024) {
            throw new ApiError(400, 'weak_password', 'Mot de passe trop long.');
        }
    }

    private function algorithm(): string|int
    {
        return defined('PASSWORD_ARGON2ID') ? PASSWORD_ARGON2ID : PASSWORD_DEFAULT;
    }

    private function hash(string $password): string
    {
        return password_hash($password, $this->algorithm());
    }

    private function codeHash(string $email, string $code): string
    {
        return hash_hmac('sha256', $email . '|' . $code, $this->secret);
    }

    private function now(): string
    {
        return date('Y-m-d H:i:s', ($this->clock)());
    }
}
