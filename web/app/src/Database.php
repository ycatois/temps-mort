<?php
declare(strict_types=1);

namespace TempsMort;

use PDO;

/** Connexion PDO paresseuse (MariaDB en production, SQLite possible pour les tests). */
final class Database
{
    private ?PDO $pdo = null;

    /** @param array{dsn:string,user:string,password:string} $config */
    public function __construct(private readonly array $config) {}

    public static function fromPdo(PDO $pdo): self
    {
        $db = new self(['dsn' => '', 'user' => '', 'password' => '']);
        $db->pdo = $pdo;
        return $db;
    }

    public function pdo(): PDO
    {
        if ($this->pdo === null) {
            $this->pdo = new PDO($this->config['dsn'], $this->config['user'], $this->config['password'], [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
            ]);
        }
        return $this->pdo;
    }
}
