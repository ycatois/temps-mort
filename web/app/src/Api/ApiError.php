<?php
declare(strict_types=1);

namespace TempsMort\Api;

/** Erreur renvoyée à l'app : code stable (pour le programme) et message en français (pour le coach). */
final class ApiError extends \RuntimeException
{
    public function __construct(public readonly int $status, public readonly string $errorCode, string $message)
    {
        parent::__construct($message);
    }
}
