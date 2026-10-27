<?php /** Pied de page commun — reproduit dans wp-theme/temps-mort/footer.php. @var array $config */ ?>
<footer class="site-footer">
  <div class="site-footer__inner container">
    <span class="site-footer__brand"><?= e($config['brand']) ?></span>
    <a href="<?= e(url($config, '/mentions-legales')) ?>">Mentions légales</a>
    <a href="<?= e(url($config, '/confidentialite')) ?>">Confidentialité</a>
    <a href="mailto:<?= e($config['contact_email']) ?>">Contact</a>
    <span>Édité par <?= e($config['publisher']) ?> · hébergé en France</span>
  </div>
</footer>
