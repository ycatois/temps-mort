<?php
/** Page statique du blog (ex. « À propos »). */
if (!defined('ABSPATH')) { exit; }
get_header();
while (have_posts()): the_post(); ?>
  <article id="post-<?php the_ID(); ?>" <?php post_class(); ?>>
    <div class="prose container container--narrow">
      <h1 class="display display--l"><?php the_title(); ?></h1>
      <?php the_content(); ?>
    </div>
  </article>
<?php endwhile;
get_footer();
