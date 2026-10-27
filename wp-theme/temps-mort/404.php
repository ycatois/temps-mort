<?php
if (!defined('ABSPATH')) { exit; }
get_header(); ?>
<section class="prose container container--narrow">
  <span class="eyebrow">Erreur 404</span>
  <h1 class="display display--l">Hors du terrain.</h1>
  <p>Cet article n'existe pas ou a changé d'adresse.</p>
  <?php get_search_form(); ?>
  <p><a class="btn btn--navy" href="<?php echo esc_url(home_url('/')); ?>">Tous les articles</a></p>
</section>
<?php get_footer();
