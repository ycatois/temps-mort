<?php
/** Liste des articles : accueil du blog, archives, recherche (WordPress retombe sur ce gabarit). */
if (!defined('ABSPATH')) { exit; }
get_header();

if (is_search()) {
    $eyebrow = 'Recherche';
    $title = sprintf('Résultats pour « %s »', get_search_query());
    $lead = '';
} elseif (is_archive()) {
    $eyebrow = is_category() ? 'Catégorie' : (is_tag() ? 'Mot-clé' : 'Archives');
    $title = single_term_title('', false) ?: wp_strip_all_tags(get_the_archive_title());
    $lead = wp_strip_all_tags(get_the_archive_description());
} else {
    $eyebrow = 'Le blog';
    $title = 'Conseils de banc, pour les coachs amateurs.';
    $lead = 'Rotations, stats utiles, gestion d\'équipe jeune ou mixte, 4x4 et 2x2 : ce qu\'on apprend le samedi au gymnase.';
}
$categories = get_categories(['hide_empty' => true, 'number' => 8]);
?>
<section class="blog-hero on-navy">
  <div class="blog-hero__inner container">
    <span class="eyebrow"><?php echo esc_html($eyebrow); ?></span>
    <h1 class="display display--l"><?php echo esc_html($title); ?></h1>
    <?php if ($lead !== ''): ?><p class="blog-hero__lead"><?php echo esc_html($lead); ?></p><?php endif; ?>
    <?php if ($categories): ?>
      <nav class="chips" aria-label="Catégories">
        <a class="chip<?php echo is_home() ? ' chip--active' : ''; ?>" href="<?php echo esc_url(home_url('/')); ?>">Tout</a>
        <?php foreach ($categories as $cat): ?>
          <a class="chip<?php echo is_category($cat->term_id) ? ' chip--active' : ''; ?>" href="<?php echo esc_url(get_category_link($cat)); ?>"><?php echo esc_html($cat->name); ?></a>
        <?php endforeach; ?>
      </nav>
    <?php endif; ?>
  </div>
</section>

<section class="container post-list-wrap">
  <?php if (have_posts()): ?>
    <div class="post-list">
      <?php while (have_posts()): the_post(); get_template_part('template-parts/card'); endwhile; ?>
    </div>
    <?php the_posts_pagination(['mid_size' => 1, 'prev_text' => '← Plus récents', 'next_text' => 'Plus anciens →']); ?>
  <?php else: ?>
    <div class="empty">
      <p>Aucun article ici pour l'instant.</p>
      <?php get_search_form(); ?>
    </div>
  <?php endif; ?>
</section>

<?php
get_template_part('template-parts/beta');
get_footer();
