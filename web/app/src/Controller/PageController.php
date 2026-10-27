<?php
declare(strict_types=1);

namespace TempsMort\Controller;

use TempsMort\Response;
use TempsMort\View;

final class PageController
{
    /** @param array<string,mixed> $config */
    public function __construct(private readonly View $view, private readonly array $config) {}

    public function home(): Response
    {
        $beta = $_GET['beta'] ?? null;
        return $this->view->page('home', [
            'title' => $this->config['brand'] . ' · application de coaching volley',
            'description' => 'Stats en direct, rotation automatique et tableau tactique au doigt. Pour les coachs de volley, sur tablette et smartphone, même sans réseau.',
            'betaStatus' => in_array($beta, ['ok', 'invalid', 'error', 'limit'], true) ? $beta : null,
        ]);
    }

    public function pricing(): Response
    {
        return $this->view->page('pricing', [
            'title' => 'Tarifs · ' . $this->config['brand'],
            'description' => 'Gratuit pour une équipe. Coach Pro pour suivre une saison, offre Club pour toutes les équipes.',
            'current' => 'tarifs',
        ]);
    }

    public function legal(): Response
    {
        return $this->view->page('legal', ['title' => 'Mentions légales · ' . $this->config['brand'], 'current' => 'legal']);
    }

    public function privacy(): Response
    {
        return $this->view->page('privacy', ['title' => 'Confidentialité · ' . $this->config['brand'], 'current' => 'privacy']);
    }

    public function notFound(): Response
    {
        return $this->view->page('not-found', ['title' => 'Page introuvable · ' . $this->config['brand']], 404);
    }
}
