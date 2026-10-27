<?php /** @var array $config */ ?>
<article class="prose container container--narrow">
  <h1 class="display display--l">Mentions légales</h1>
  <p class="fineprint">À compléter et faire relire avant la mise en ligne. Les éléments entre crochets sont à renseigner.</p>

  <h2>Éditeur</h2>
  <p><?= e($config['publisher']) ?>, société par actions simplifiée unipersonnelle au capital de [montant] €, immatriculée au RCS de [ville] sous le numéro [SIREN], dont le siège est situé [adresse]. TVA intracommunautaire : [numéro].<br>
  Directeur de la publication : [Prénom Nom].<br>
  Contact : <a href="mailto:<?= e($config['contact_email']) ?>"><?= e($config['contact_email']) ?></a></p>

  <h2>Hébergement</h2>
  <p>o2switch, [adresse du siège à vérifier sur o2switch.fr], France.</p>

  <h2>Propriété intellectuelle</h2>
  <p>La marque <?= e($config['brand']) ?>, les textes, visuels et logiciels présentés sur ce site sont la propriété de <?= e($config['publisher']) ?>. Toute reproduction sans autorisation est interdite.</p>
</article>
