<?php
declare(strict_types=1);

namespace TempsMort\Controller;

use TempsMort\Api\Accounts;
use TempsMort\Api\ApiError;
use TempsMort\Api\Documents;
use TempsMort\Response;

/**
 * API de l'app mobile, /api/v1 (docs/compte-et-synchro.md). JSON en entrée et en sortie ;
 * l'appareil s'identifie par « Authorization: Bearer <jeton> ». Pas de cookie, donc pas de CSRF.
 */
final class ApiController
{
    private const MAX_BODY = 8_000_000;

    public function __construct(private readonly Accounts $accounts, private readonly Documents $documents) {}

    /** @param array<string,mixed> $post @param array<string,mixed> $server */
    public function register(array $post, array $server): Response
    {
        return $this->handle($server, function (array $in) use ($server) {
            $token = $this->accounts->register($this->str($in, 'email'), $this->str($in, 'password'), $this->str($in, 'deviceName'), $this->ip($server));
            return [201, ['token' => $token]];
        });
    }

    /** @param array<string,mixed> $post @param array<string,mixed> $server */
    public function login(array $post, array $server): Response
    {
        return $this->handle($server, fn (array $in) => [200, ['token' => $this->accounts->login(
            $this->str($in, 'email'), $this->str($in, 'password'), $this->str($in, 'deviceName'), $this->ip($server),
        )]]);
    }

    /** @param array<string,mixed> $post @param array<string,mixed> $server */
    public function resetCode(array $post, array $server): Response
    {
        return $this->handle($server, function (array $in) use ($server) {
            $this->accounts->sendResetCode($this->str($in, 'email'), $this->ip($server));
            // Même réponse que l'adresse ait un compte ou non.
            return [200, ['sent' => true]];
        });
    }

    /** @param array<string,mixed> $post @param array<string,mixed> $server */
    public function reset(array $post, array $server): Response
    {
        return $this->handle($server, fn (array $in) => [200, ['token' => $this->accounts->resetPassword(
            $this->str($in, 'email'), $this->str($in, 'code'), $this->str($in, 'newPassword'), $this->str($in, 'deviceName'),
        )]]);
    }

    /** @param array<string,mixed> $post @param array<string,mixed> $server */
    public function logout(array $post, array $server): Response
    {
        return $this->handle($server, function () use ($server) {
            $this->accounts->logout($this->auth($server)['device_id']);
            return [200, ['loggedOut' => true]];
        }, body: false);
    }

    /** @param array<string,mixed> $post @param array<string,mixed> $server */
    public function sync(array $post, array $server): Response
    {
        return $this->handle($server, function (array $in) use ($server) {
            $who = $this->auth($server);
            $lastRev = $in['lastRev'] ?? 0;
            $changes = $in['changes'] ?? [];
            if (!is_int($lastRev) || $lastRev < 0 || !is_array($changes) || !array_is_list($changes)) {
                throw new ApiError(400, 'bad_request', 'Requête de synchronisation invalide.');
            }
            $result = $this->documents->sync($who['coach_id'], $lastRev, $changes);
            // Objet JSON même vide (« {} »), pas une liste.
            $result['pushed'] = (object) $result['pushed'];
            return [200, $result];
        });
    }

    /** @param array<string,mixed> $post @param array<string,mixed> $server */
    public function deleteAccount(array $post, array $server): Response
    {
        return $this->handle($server, function (array $in) use ($server) {
            $this->accounts->deleteAccount($this->auth($server)['coach_id'], $this->str($in, 'password'));
            return [200, ['deleted' => true]];
        });
    }

    /**
     * @param array<string,mixed> $server
     * @param callable(array<string,mixed>):array{0:int,1:array<string,mixed>} $action
     */
    private function handle(array $server, callable $action, bool $body = true): Response
    {
        try {
            [$status, $payload] = $action($body ? $this->body($server) : []);
            return $this->json($status, $payload);
        } catch (ApiError $e) {
            return $this->json($e->status, ['error' => ['code' => $e->errorCode, 'message' => $e->getMessage()]]);
        } catch (\Throwable $e) {
            error_log('api: ' . $e);
            return $this->json(500, ['error' => ['code' => 'server_error', 'message' => 'Erreur du serveur. Réessayez plus tard.']]);
        }
    }

    /** @param array<string,mixed> $server @return array<string,mixed> */
    private function body(array $server): array
    {
        // Les tests passent le corps dans TM_RAW_BODY ; en vrai, il vient de php://input.
        $raw = $server['TM_RAW_BODY'] ?? file_get_contents('php://input', length: self::MAX_BODY + 1);
        if (!is_string($raw) || strlen($raw) > self::MAX_BODY) {
            throw new ApiError(413, 'too_large', 'Envoi trop volumineux.');
        }
        try {
            $data = json_decode($raw === '' ? '{}' : $raw, true, 512, JSON_THROW_ON_ERROR);
        } catch (\JsonException) {
            throw new ApiError(400, 'bad_json', 'Requête illisible.');
        }
        if (!is_array($data) || array_is_list($data) && $data !== []) {
            throw new ApiError(400, 'bad_json', 'Requête illisible.');
        }
        return $data;
    }

    /** @param array<string,mixed> $server @return array{coach_id:int,device_id:int,email:string} */
    private function auth(array $server): array
    {
        // Selon la configuration d'Apache (o2switch), l'en-tête arrive sous l'un ou l'autre nom.
        $header = (string) ($server['HTTP_AUTHORIZATION'] ?? $server['REDIRECT_HTTP_AUTHORIZATION'] ?? '');
        $token = preg_match('/^Bearer\s+(\S+)$/', $header, $m) ? $m[1] : '';
        return $this->accounts->authenticate($token);
    }

    /** @param array<string,mixed> $in */
    private function str(array $in, string $key): string
    {
        $v = $in[$key] ?? '';
        return is_string($v) ? $v : '';
    }

    /** @param array<string,mixed> $server */
    private function ip(array $server): string
    {
        return (string) ($server['REMOTE_ADDR'] ?? '');
    }

    /** @param array<string,mixed> $payload */
    private function json(int $status, array $payload): Response
    {
        return new Response(
            json_encode($payload, JSON_THROW_ON_ERROR | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
            $status,
            ['Content-Type' => 'application/json; charset=utf-8', 'Cache-Control' => 'no-store'],
        );
    }
}
