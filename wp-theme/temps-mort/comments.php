<?php
/** Commentaires (désactivables dans Réglages > Discussion). */
if (!defined('ABSPATH') || post_password_required()) { return; }
?>
<section id="commentaires" class="comments container container--narrow">
  <?php if (have_comments()): ?>
    <h2 class="display comments__title"><?php echo esc_html(sprintf(_n('%d commentaire', '%d commentaires', get_comments_number(), 'temps-mort'), get_comments_number())); ?></h2>
    <ol class="comments__list"><?php wp_list_comments(['style' => 'ol', 'avatar_size' => 40, 'short_ping' => true]); ?></ol>
    <?php the_comments_pagination(); ?>
  <?php endif; ?>
  <?php comment_form(['class_submit' => 'btn btn--navy btn--sm', 'title_reply' => 'Laisser un commentaire']); ?>
</section>
