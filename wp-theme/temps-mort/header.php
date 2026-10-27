<?php
/**
 * En-tête : balisage IDENTIQUE à web/app/templates/partials/header.php (seuls les liens changent de base).
 */
if (!defined('ABSPATH')) { exit; }
$home = tm_site_url();
?>
<!doctype html>
<html <?php language_attributes(); ?>>
<head>
<meta charset="<?php bloginfo('charset'); ?>">
<meta name="viewport" content="width=device-width, initial-scale=1">
<?php wp_head(); ?>
</head>
<body <?php body_class(); ?>>
<?php wp_body_open(); ?>
<a class="skip-link" href="#contenu">Aller au contenu</a>
<header class="site-header">
  <nav class="site-nav container" aria-label="Navigation principale">
    <a class="site-logo" href="<?php echo esc_url($home); ?>">
      <svg width="34" height="34" viewBox="0 0 34 34" aria-hidden="true"><circle cx="17" cy="19" r="13" fill="none" stroke="#FFD23F" stroke-width="3"/><path d="M17 19V11" stroke="#FFD23F" stroke-width="3" stroke-linecap="round"/><path d="M13 3h8" stroke="#FFD23F" stroke-width="3" stroke-linecap="round"/></svg>
      <span class="site-logo__name"><?php echo esc_html(tm_brand()); ?></span>
    </a>
    <div class="site-nav__links">
      <a class="site-nav__link" href="<?php echo esc_url($home); ?>#fonctions">Fonctionnalités</a>
      <a class="site-nav__link" href="<?php echo esc_url($home); ?>#formats">Formats</a>
      <a class="site-nav__link" href="<?php echo esc_url(tm_site_url('tarifs')); ?>">Tarifs</a>
      <a class="site-nav__link" href="<?php echo esc_url(home_url('/')); ?>" aria-current="page">Blog</a>
      <a class="site-nav__link" href="<?php echo esc_url($home); ?>#faq">Questions</a>
    </div>
    <a class="btn btn--yellow btn--sm" href="<?php echo esc_url($home); ?>#beta">Rejoindre la bêta</a>
  </nav>
</header>
<main id="contenu">
