<?php
/**
 * En-tête commun. Le thème WordPress (wp-theme/temps-mort/header.php) reproduit EXACTEMENT ce balisage :
 * toute modification ici doit y être reportée (cf. agent design-guardian).
 * @var array $config @var string $current
 */
$home = url($config, '/');
?>
<header class="site-header">
  <nav class="site-nav container" aria-label="Navigation principale">
    <a class="site-logo" href="<?= e($home) ?>">
      <svg width="34" height="34" viewBox="0 0 34 34" aria-hidden="true"><circle cx="17" cy="19" r="13" fill="none" stroke="#FFD23F" stroke-width="3"/><path d="M17 19V11" stroke="#FFD23F" stroke-width="3" stroke-linecap="round"/><path d="M13 3h8" stroke="#FFD23F" stroke-width="3" stroke-linecap="round"/></svg>
      <span class="site-logo__name"><?= e($config['brand']) ?></span>
    </a>
    <div class="site-nav__links">
      <a class="site-nav__link" href="<?= e($home) ?>#fonctions">Fonctionnalités</a>
      <a class="site-nav__link" href="<?= e($home) ?>#formats">Formats</a>
      <a class="site-nav__link" href="<?= e(url($config, '/tarifs')) ?>"<?= $current === 'tarifs' ? ' aria-current="page"' : '' ?>>Tarifs</a>
      <a class="site-nav__link" href="<?= e($config['blog_url']) ?>">Blog</a>
      <a class="site-nav__link" href="<?= e($home) ?>#faq">Questions</a>
    </div>
    <a class="btn btn--yellow btn--sm" href="<?= e($home) ?>#beta">Rejoindre la bêta</a>
  </nav>
</header>
