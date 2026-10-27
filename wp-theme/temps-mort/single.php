<?php
/** Article. */
if (!defined('ABSPATH')) { exit; }
get_header();
while (have_posts()): the_post();
    $cats = get_the_category();
    ?>
    <article id="post-<?php the_ID(); ?>" <?php post_class('entry'); ?>>
      <header class="entry-hero on-navy">
        <div class="entry-hero__inner container container--narrow">
          <?php if ($cats): ?><a class="eyebrow entry-hero__cat" href="<?php echo esc_url(get_category_link($cats[0])); ?>"><?php echo esc_html($cats[0]->name); ?></a><?php endif; ?>
          <h1 class="display display--l"><?php the_title(); ?></h1>
          <span class="entry-hero__meta"><?php echo esc_html(get_the_date()); ?> · <?php echo esc_html(tm_reading_time()); ?> · <?php the_author(); ?></span>
        </div>
      </header>
      <?php if (has_post_thumbnail()): ?>
        <figure class="entry-cover container container--narrow"><?php the_post_thumbnail('large'); ?></figure>
      <?php endif; ?>
      <div class="prose entry-content container container--narrow">
        <?php the_content(); ?>
        <?php wp_link_pages(['before' => '<nav class="page-links">Pages : ', 'after' => '</nav>']); ?>
      </div>
      <footer class="entry-footer container container--narrow">
        <?php the_tags('<div class="chips chips--light">', '', '</div>'); ?>
        <nav class="entry-nav" aria-label="Articles voisins">
          <?php previous_post_link('<span class="entry-nav__prev">%link</span>', '← %title'); ?>
          <?php next_post_link('<span class="entry-nav__next">%link</span>', '%title →'); ?>
        </nav>
      </footer>
      <?php if (comments_open() || get_comments_number()) { comments_template(); } ?>
    </article>
    <?php
endwhile;
get_template_part('template-parts/beta');
get_footer();
