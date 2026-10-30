<?php
declare(strict_types=1);

namespace TempsMort\Api;

use PDO;

/**
 * Synchronisation (V1-TEC-03) : l'app pousse ses documents modifiés et tire ceux modifiés ailleurs,
 * en un seul appel. Chaque écriture reçoit une révision du coach (compteur croissant). Le serveur ne
 * lit pas le contenu : il garde le JSON de l'app tel quel. Voir docs/compte-et-synchro.md.
 */
final class Documents
{
    public const KINDS = ['team', 'match', 'events', 'template', 'play'];
    public const MAX_CHANGES = 500;
    public const MAX_DOCUMENT_BYTES = 1_000_000;

    /** Plafonds par coach : de quoi tenir des années de matchs, sans laisser saturer le serveur mutualisé. */
    public const MAX_COACH_DOCUMENTS = 20_000;
    public const MAX_COACH_BYTES = 50_000_000;

    /** @param \Closure():int $clock */
    public function __construct(
        private readonly PDO $pdo,
        private readonly \Closure $clock,
        private readonly int $maxDocuments = self::MAX_COACH_DOCUMENTS,
        private readonly int $maxBytes = self::MAX_COACH_BYTES,
    ) {}

    /**
     * @param list<mixed> $changes [{id, kind, baseRev, deleted?, data?}] ; baseRev = révision connue de l'app (0 si nouveau)
     * @return array{rev:int, changes:list<array<string,mixed>>, conflicts:list<string>, pushed:array<string,int>}
     *   pushed : révision attribuée à chaque document reçu, que l'app garde comme baseRev.
     */
    public function sync(int $coachId, int $lastRev, array $changes): array
    {
        if (count($changes) > self::MAX_CHANGES) {
            throw new ApiError(413, 'too_many_changes', 'Trop de modifications en une fois : réessayez, l\'app enverra la suite.');
        }
        $incoming = array_map($this->validate(...), $changes);

        $mysql = $this->pdo->getAttribute(PDO::ATTR_DRIVER_NAME) === 'mysql';
        // MariaDB : en REPEATABLE READ, la première lecture fige la vue de la transaction ; une synchro
        // concurrente validée entre-temps resterait invisible (documents jamais renvoyés, conflits ratés).
        // READ COMMITTED + verrou sur la ligne du coach : ses synchros passent l'une après l'autre et
        // chacune voit tout ce que les précédentes ont écrit. (SQLite, des tests, sérialise déjà tout.)
        if ($mysql) { $this->pdo->exec('SET TRANSACTION ISOLATION LEVEL READ COMMITTED'); }
        $this->pdo->beginTransaction();
        try {
            $this->pdo->prepare('SELECT rev FROM coaches WHERE id = :c' . ($mysql ? ' FOR UPDATE' : ''))->execute(['c' => $coachId]);
            $pushed = [];
            $conflicts = [];
            $kept = [];
            foreach ($incoming as $c) {
                $current = $this->find($coachId, $c['id']);
                if ($current !== null && $current['kind'] !== $c['kind']) {
                    throw new ApiError(400, 'bad_change', "Le document {$c['id']} change de nature.");
                }
                $conflict = $current !== null && (int) $current['rev'] > $c['baseRev'];
                if ($conflict) {
                    $conflicts[] = $c['id'];
                    if (!$this->incomingWins($c, $current)) {
                        // Version de l'appareil refusée : on lui renverra celle du serveur.
                        $kept[$c['id']] = true;
                        continue;
                    }
                }
                $rev = $this->nextRev($coachId);
                $this->write($coachId, $c, $rev, $current !== null);
                $pushed[$c['id']] = $rev;
            }
            $this->checkQuota($coachId);

            // Ce qui a changé depuis la dernière synchro de l'appareil, sauf ce qu'il vient d'envoyer ;
            // plus la version du serveur de tout document en conflit qu'il n'a pas pu écrire.
            $stmt = $this->pdo->prepare('SELECT id, kind, rev, deleted, data FROM documents WHERE coach_id = :c AND rev > :r ORDER BY rev');
            $stmt->execute(['c' => $coachId, 'r' => $lastRev]);
            $out = [];
            foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
                if (($pushed[$row['id']] ?? null) === (int) $row['rev']) { continue; }
                unset($kept[$row['id']]);
                $out[] = $this->row($row);
            }
            foreach (array_keys($kept) as $id) {
                $row = $this->find($coachId, (string) $id);
                $out[] = $this->row(['id' => $id] + $row);
            }
            $rev = $this->currentRev($coachId);
            $this->pdo->commit();
        } catch (\Throwable $e) {
            $this->pdo->rollBack();
            throw $e;
        }
        return ['rev' => $rev, 'changes' => $out, 'conflicts' => $conflicts, 'pushed' => $pushed];
    }

    /**
     * Conflit (le document a changé ailleurs depuis que l'app l'a reçu). Une suppression gagne toujours,
     * dans les deux sens : une modification restée hors ligne ne ressuscite pas des données supprimées
     * à la demande d'une famille (RGPD). Sinon la dernière modification gagne, sauf pour les événements
     * d'un match, où l'on garde le journal le plus long (il contient l'autre en général : saisie poursuivie
     * sur un appareil, simple reprise sur l'autre).
     *
     * @param array<string,mixed> $c @param array<string,mixed> $current
     */
    private function incomingWins(array $c, array $current): bool
    {
        if ($c['deleted']) { return true; }
        if ($current['deleted']) { return false; }
        if ($c['kind'] !== 'events') { return true; }
        $existing = json_decode((string) $current['data'], true);
        return count($c['data']) >= (is_array($existing) ? count($existing) : 0);
    }

    /** @return array{id:string,kind:string,baseRev:int,deleted:bool,data:mixed} */
    private function validate(mixed $c): array
    {
        $bad = static fn (string $why) => new ApiError(400, 'bad_change', "Modification refusée : $why.");
        if (!is_array($c)) { throw $bad('format'); }
        $id = $c['id'] ?? null;
        if (!is_string($id) || !preg_match('/^[A-Za-z0-9_:-][A-Za-z0-9._:-]{0,99}$/', $id)) { throw $bad('identifiant'); }
        $kind = $c['kind'] ?? null;
        if (!in_array($kind, self::KINDS, true)) { throw $bad("nature inconnue pour $id"); }
        $base = $c['baseRev'] ?? 0;
        if (!is_int($base) || $base < 0) { throw $bad("révision de $id"); }
        $deleted = ($c['deleted'] ?? false) === true;
        $data = $c['data'] ?? null;
        if (!$deleted) {
            if (!is_array($data)) { throw $bad("contenu de $id"); }
            if (strlen(json_encode($data, JSON_THROW_ON_ERROR)) > self::MAX_DOCUMENT_BYTES) { throw $bad("$id trop volumineux"); }
        }
        return ['id' => $id, 'kind' => $kind, 'baseRev' => $base, 'deleted' => $deleted, 'data' => $deleted ? null : $data];
    }

    /** @param array<string,mixed> $row @return array<string,mixed> */
    private function row(array $row): array
    {
        return [
            'id' => (string) $row['id'],
            'kind' => (string) $row['kind'],
            'rev' => (int) $row['rev'],
            'deleted' => (bool) $row['deleted'],
            'data' => $row['deleted'] ? null : json_decode((string) $row['data'], true, 512, JSON_THROW_ON_ERROR),
        ];
    }

    private function checkQuota(int $coachId): void
    {
        $stmt = $this->pdo->prepare('SELECT COUNT(*) AS n, COALESCE(SUM(LENGTH(data)), 0) AS bytes FROM documents WHERE coach_id = :c');
        $stmt->execute(['c' => $coachId]);
        $use = $stmt->fetch(PDO::FETCH_ASSOC);
        if ((int) $use['n'] > $this->maxDocuments || (int) $use['bytes'] > $this->maxBytes) {
            throw new ApiError(507, 'quota_exceeded', 'Espace de sauvegarde plein. Supprimez d\'anciens matchs ou écrivez-nous.');
        }
    }

    /** @return array<string,mixed>|null */
    private function find(int $coachId, string $id): ?array
    {
        $stmt = $this->pdo->prepare('SELECT kind, rev, deleted, data FROM documents WHERE coach_id = :c AND id = :id');
        $stmt->execute(['c' => $coachId, 'id' => $id]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        return $row === false ? null : $row;
    }

    /** @param array<string,mixed> $c */
    private function write(int $coachId, array $c, int $rev, bool $exists): void
    {
        // Pierre tombale : le contenu est effacé pour de bon (RGPD), seule la marque reste.
        $params = [
            'c' => $coachId,
            'id' => $c['id'],
            'kind' => $c['kind'],
            'rev' => $rev,
            'deleted' => $c['deleted'] ? 1 : 0,
            'data' => $c['deleted'] ? null : json_encode($c['data'], JSON_THROW_ON_ERROR | JSON_UNESCAPED_UNICODE),
            'now' => date('Y-m-d H:i:s', ($this->clock)()),
        ];
        $sql = $exists
            ? 'UPDATE documents SET kind = :kind, rev = :rev, deleted = :deleted, data = :data, updated_at = :now WHERE coach_id = :c AND id = :id'
            : 'INSERT INTO documents (coach_id, id, kind, rev, deleted, data, updated_at) VALUES (:c, :id, :kind, :rev, :deleted, :data, :now)';
        $this->pdo->prepare($sql)->execute($params);
    }

    private function nextRev(int $coachId): int
    {
        $this->pdo->prepare('UPDATE coaches SET rev = rev + 1 WHERE id = :c')->execute(['c' => $coachId]);
        return $this->currentRev($coachId);
    }

    private function currentRev(int $coachId): int
    {
        $stmt = $this->pdo->prepare('SELECT rev FROM coaches WHERE id = :c');
        $stmt->execute(['c' => $coachId]);
        return (int) $stmt->fetchColumn();
    }
}
