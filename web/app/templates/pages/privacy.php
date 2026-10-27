<?php /** @var array $config */ ?>
<article class="prose container container--narrow">
  <h1 class="display display--l">Confidentialité</h1>
  <p class="fineprint">Trame à compléter et faire valider (RGPD). Elle couvre le site vitrine et le blog ; l'application aura sa propre politique.</p>

  <h2>Ce que nous collectons sur ce site</h2>
  <ul>
    <li><strong>Inscription à la bêta</strong> : votre adresse email, la date, la page d'origine et le texte d'information affiché au moment de l'inscription.</li>
    <li><strong>Protection contre les abus</strong> : une empreinte non réversible de votre adresse IP, renouvelée chaque jour.</li>
    <li>Aucun cookie publicitaire, aucun outil de mesure tiers, polices hébergées sur nos serveurs.</li>
  </ul>

  <h2>Pourquoi</h2>
  <p>Vous prévenir du lancement de la bêta puis vous envoyer au plus un email par mois. Base légale : votre consentement, donné en soumettant le formulaire.</p>

  <h2>Combien de temps</h2>
  <p>Jusqu'à votre désinscription, puis [durée] pour la preuve du consentement. Chaque email contient un lien de désinscription.</p>

  <h2>Vos droits</h2>
  <p>Accès, rectification, effacement, opposition : écrivez à <a href="mailto:<?= e($config['contact_email']) ?>"><?= e($config['contact_email']) ?></a>. Vous pouvez aussi saisir la CNIL.</p>

  <h2>Où sont les données</h2>
  <p>Chez o2switch, en France. Responsable du traitement : <?= e($config['publisher']) ?>.</p>
</article>
