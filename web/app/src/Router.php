<?php
declare(strict_types=1);

namespace TempsMort;

final class Router
{
    /** @var array<string,array<string,callable>> */
    private array $routes = ['GET' => [], 'POST' => []];
    /** @var callable|null */
    private $notFound = null;

    public function __construct(private readonly string $basePath = '') {}

    public function get(string $path, callable $handler): void  { $this->routes['GET'][$path] = $handler; }
    public function post(string $path, callable $handler): void { $this->routes['POST'][$path] = $handler; }
    public function notFound(callable $handler): void { $this->notFound = $handler; }

    /** @param array<string,mixed> $post */
    public function dispatch(string $method, string $uri, array $post = [], array $server = []): Response
    {
        $path = parse_url($uri, PHP_URL_PATH) ?: '/';
        if ($this->basePath !== '' && str_starts_with($path, $this->basePath)) {
            $path = substr($path, strlen($this->basePath)) ?: '/';
        }
        $path = $path === '/' ? '/' : rtrim($path, '/');
        $method = $method === 'HEAD' ? 'GET' : $method;

        $handler = $this->routes[$method][$path] ?? null;
        if ($handler !== null) {
            return $handler($post, $server);
        }
        $allowed = array_keys(array_filter($this->routes, static fn (array $r) => isset($r[$path])));
        if ($allowed !== []) {
            return new Response('Méthode non autorisée', 405, ['Allow' => implode(', ', $allowed), 'Content-Type' => 'text/plain; charset=utf-8']);
        }
        return $this->notFound ? ($this->notFound)() : new Response('Page introuvable', 404);
    }
}
