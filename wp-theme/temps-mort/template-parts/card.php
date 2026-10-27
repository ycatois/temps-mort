<?php
/** Carte d'article pour les listes (accueil du blog, catégories, recherche). */
if (!defined('ABSPATH')) { exit; }
$cats = get_the_category();
?>
<article id="post-<?php the_ID(); ?>" <?php post_class('card post-card'); ?>>
  <?php if (has_post_thumbnail()): ?>
    <a class="post-card__media" href="<?php the_permalink(); ?>" tabindex="-1" aria-hidden="true"><?php the_post_thumbnail('tm-card', ['loading' => 'lazy', 'alt' => '']); ?></a>
  <?php endif; ?>
  <div class="post-card__body">
    <?php if ($cats): ?><span class="eyebrow"><?php echo esc_html($cats[0]->name); ?></span><?php endif; ?>
    <h2 class="post-card__title"><a href="<?php the_permalink(); ?>"><?php the_title(); ?></a></h2>
    <p class="card__text"><?php echo esc_html(get_the_excerpt()); ?></p>
    <span class="post-meta"><?php echo esc_html(get_the_date()); ?> · <?php echo esc_html(tm_reading_time()); ?></span>
  </div>
</article>
