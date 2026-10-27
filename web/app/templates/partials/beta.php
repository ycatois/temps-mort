<?php
/** Formulaire bêta — même balisage dans wp-theme/temps-mort/template-parts/beta.php. @var array $config @var ?string $betaStatus */
$messages = [
    'ok' => ['ok', 'C\'est noté ! Vous recevrez un email au lancement de la bêta.'],
    'invalid' => ['error', 'Cette adresse email ne semble pas valide.'],
    'limit' => ['error', 'Trop de tentatives. Réessayez dans une heure.'],
    'error' => ['error', 'L\'inscription n\'a pas pu être enregistrée. Réessayez dans un instant.'],
];
$status = $betaStatus ?? null;
?>
<section id="beta" class="beta">
  <div class="beta__inner container container--narrow">
    <h2 class="display beta__title">Testez-le à votre prochain match.</h2>
    <p class="beta__lead">Bêta gratuite pour les coachs de volley. Vos retours décident des prochaines fonctionnalités.</p>
    <?php if ($status !== null && isset($messages[$status])): ?>
      <p class="notice notice--<?= e($messages[$status][0]) ?>" role="status"><?= e($messages[$status][1]) ?></p>
    <?php endif; ?>
    <form class="beta__form" method="post" action="<?= e(url($config, '/beta')) ?>">
      <label for="beta-email" class="sr-only">Votre email</label>
      <input id="beta-email" class="beta__input" type="email" name="email" placeholder="vous@exemple.fr" autocomplete="email" required maxlength="190">
      <span class="beta__hp" aria-hidden="true"><label for="beta-website">Ne pas remplir</label><input id="beta-website" type="text" name="website" tabindex="-1" autocomplete="off"></span>
      <input type="hidden" name="source" value="site">
      <input type="hidden" name="return" value="<?= e(url($config, '/')) ?>">
      <button class="btn btn--yellow beta__submit" type="submit">Rejoindre la bêta</button>
    </form>
    <span class="beta__note">Un email au lancement, puis un par mois au plus. Désinscription en un clic. <a href="<?= e(url($config, '/confidentialite')) ?>">Confidentialité</a></span>
  </div>
</section>
