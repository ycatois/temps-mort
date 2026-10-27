<?php
/**
 * Thème Temps Mort — blog WordPress installé dans /blog, à côté du site PHP.
 */
declare(strict_types=1);

if (!defined('ABSPATH')) { exit; }

const TM_THEME_VERSION = '0.1.0';

add_action('after_setup_theme', static function (): void {
    add_theme_support('title-tag');
    add_theme_support('post-thumbnails');
    add_theme_support('responsive-embeds');
    add_theme_support('html5', ['search-form', 'comment-form', 'comment-list', 'gallery', 'caption', 'style', 'script']);
    add_theme_support('editor-styles');
    add_editor_style(['assets/css/tokens.css', 'assets/css/base.css', 'assets/css/editor.css']);
    remove_theme_support('core-block-patterns');
    add_image_size('tm-card', 720, 405, true);
});

/** Feuilles de style : tokens + socle communs au site, puis styles propres au blog. */
add_action('wp_enqueue_scripts', static function (): void {
    $uri = get_template_directory_uri() . '/assets/css/';
    $dir = get_template_directory() . '/assets/css/';
    $ver = static fn (string $f) => TM_THEME_VERSION . '.' . (string) @filemtime($dir . $f);
    wp_enqueue_style('tm-tokens', $uri . 'tokens.css', [], $ver('tokens.css'));
    wp_enqueue_style('tm-base', $uri . 'base.css', ['tm-tokens'], $ver('base.css'));
    wp_enqueue_style('tm-blog', $uri . 'blog.css', ['tm-base'], $ver('blog.css'));
    // Pas d'emoji ni de styles globaux inutiles : le design vient de nos feuilles.
    wp_dequeue_style('classic-theme-styles');
});
remove_action('wp_head', 'print_emoji_detection_script', 7);
remove_action('wp_print_styles', 'print_emoji_styles');

add_action('wp_head', static function (): void {
    $fonts = get_template_directory_uri() . '/assets/fonts/';
    echo '<link rel="preload" href="' . esc_url($fonts . 'barlow-condensed-latin-700-normal.woff2') . '" as="font" type="font/woff2" crossorigin>' . "\n";
    echo '<link rel="preload" href="' . esc_url($fonts . 'barlow-latin-400-normal.woff2') . '" as="font" type="font/woff2" crossorigin>' . "\n";
    echo '<link rel="icon" href="' . esc_url(tm_site_url('assets/img/favicon.svg')) . '" type="image/svg+xml">' . "\n";
}, 1);

/** Réglages dans Apparence > Personnaliser > Site vitrine. */
add_action('customize_register', static function (WP_Customize_Manager $c): void {
    $c->add_section('tm_site', ['title' => 'Site vitrine', 'priority' => 30]);
    $fields = [
        'tm_brand'         => ['Nom de la marque', 'Temps Mort', 'sanitize_text_field'],
        'tm_site_url'      => ['Adresse du site vitrine (vide = parent du blog)', '', 'esc_url_raw'],
        'tm_contact_email' => ['Email de contact', 'contact@exemple.fr', 'sanitize_email'],
        'tm_publisher'     => ['Éditeur', 'Hasteria SASU', 'sanitize_text_field'],
    ];
    foreach ($fields as $id => [$label, $default, $sanitize]) {
        $c->add_setting($id, ['default' => $default, 'sanitize_callback' => $sanitize]);
        $c->add_control($id, ['label' => $label, 'section' => 'tm_site', 'type' => 'text']);
    }
});

function tm_brand(): string
{
    return (string) get_theme_mod('tm_brand', 'Temps Mort');
}

/** URL du site vitrine. Par défaut : le dossier parent du blog (https://exemple.fr/blog → https://exemple.fr/). */
function tm_site_url(string $path = ''): string
{
    $base = (string) get_theme_mod('tm_site_url', '');
    if ($base === '') {
        $home = untrailingslashit(home_url());
        $base = preg_replace('#/[^/]+$#', '', $home) ?: $home;
        if (!preg_match('#^https?://[^/]+#', $base)) { $base = $home; }
    }
    return trailingslashit($base) . ltrim($path, '/');
}

/** Chemin relatif (même domaine) du site vitrine, pour le formulaire bêta. */
function tm_site_path(string $path = ''): string
{
    $p = (string) wp_parse_url(tm_site_url($path), PHP_URL_PATH);
    return $p === '' ? '/' : $p;
}

/** Temps de lecture estimé (230 mots/min). */
function tm_reading_time(?int $post_id = null): string
{
    $words = str_word_count(wp_strip_all_tags((string) get_post_field('post_content', $post_id ?? get_the_ID())));
    return max(1, (int) round($words / 230)) . ' min de lecture';
}

/** Extrait court sans « [...] ». */
add_filter('excerpt_length', static fn () => 28);
add_filter('excerpt_more', static fn () => '…');
