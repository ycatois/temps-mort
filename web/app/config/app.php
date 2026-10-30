<?php
declare(strict_types=1);

use TempsMort\Env;

// Configuration lue depuis app/.env (voir .env.example). Les prix à null s'affichent « [PRIX] ».
return [
    'brand'     => Env::get('APP_BRAND', 'Temps Mort'),
    'publisher' => 'Hasteria SASU',
    'debug'     => Env::bool('APP_DEBUG', false),
    'url'       => rtrim(Env::get('APP_URL', 'http://localhost:8080'), '/'),
    'base_path' => rtrim(Env::get('APP_BASE_PATH', ''), '/'),
    'blog_url'  => Env::get('BLOG_URL', '/blog/'),
    'contact_email' => Env::get('CONTACT_EMAIL', 'contact@exemple.fr'),

    'db' => [
        'dsn'      => Env::get('DB_DSN', 'mysql:host=127.0.0.1;port=3306;dbname=tempsmort;charset=utf8mb4'),
        'user'     => Env::get('DB_USER', 'tempsmort'),
        'password' => Env::get('DB_PASSWORD', ''),
    ],

    // Tarifs TTC. Remplacer null par le prix retenu après l'étude Van Westendorp.
    'pricing' => [
        'coach_pro_month' => null,   // €/mois, paiement mensuel
        'club_season'     => null,   // €/saison
        'season_discount' => 0.20,   // −20 % en paiement à la saison
    ],

    // API de l'app (docs/compte-et-synchro.md). APP_SECRET : 32 caractères aléatoires au moins,
    // sert à protéger les codes de réinitialisation (HMAC). Ne jamais le changer en production
    // sans raison : les codes en cours deviendraient invalides.
    'secret' => Env::get('APP_SECRET', ''),
    'mail' => [
        'from'      => Env::get('MAIL_FROM', 'Temps Mort <ne-pas-repondre@exemple.fr>'),
        // Renseigné en local seulement (Mailpit) ; vide en production : mail() d'o2switch.
        'smtp_host' => Env::get('MAIL_SMTP_HOST', ''),
        'smtp_port' => (int) Env::get('MAIL_SMTP_PORT', '1025'),
    ],

    // Anti-abus du formulaire bêta : inscriptions max par IP et par heure.
    'beta_rate_limit' => 5,
];
