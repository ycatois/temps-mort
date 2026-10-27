<?php
declare(strict_types=1);

namespace TempsMort;

final class Kernel
{
    public function __construct(private readonly Router $router) {}

    public function run(): void
    {
        try {
            $response = $this->router->dispatch($_SERVER['REQUEST_METHOD'] ?? 'GET', $_SERVER['REQUEST_URI'] ?? '/', $_POST, $_SERVER);
        } catch (\Throwable $e) {
            error_log((string) $e);
            $response = new Response('<!doctype html><meta charset="utf-8"><title>Erreur</title><p>Une erreur est survenue. Réessayez dans un instant.</p>', 500);
        }
        $response->send();
    }
}
