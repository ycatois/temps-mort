<?php
/** Pied de page : balisage identique à web/app/templates/partials/footer.php. */
if (!defined('ABSPATH')) { exit; }
$email = (string) get_theme_mod('tm_contact_email', 'contact@exemple.fr');
?>
</main>
<footer class="site-footer">
  <div class="site-footer__inner container">
    <span class="site-footer__brand"><?php echo esc_html(tm_brand()); ?></span>
    <a href="<?php echo esc_url(tm_site_url('mentions-legales')); ?>">Mentions légales</a>
    <a href="<?php echo esc_url(tm_site_url('confidentialite')); ?>">Confidentialité</a>
    <a href="mailto:<?php echo esc_attr($email); ?>">Contact</a>
    <span>Édité par <?php echo esc_html((string) get_theme_mod('tm_publisher', 'Hasteria SASU')); ?> · hébergé en France</span>
  </div>
</footer>
<?php wp_footer(); ?>
</body>
</html>
