<?php if (!defined('ABSPATH')) { exit; } ?>
<form role="search" method="get" class="search-form" action="<?php echo esc_url(home_url('/')); ?>">
  <label for="s-<?php echo esc_attr((string) wp_rand()); ?>" class="sr-only">Rechercher un article</label>
  <input class="search-form__input" type="search" name="s" value="<?php echo esc_attr(get_search_query()); ?>" placeholder="Rotation, réception, M13…">
  <button class="btn btn--navy btn--sm" type="submit">Rechercher</button>
</form>
