<?php /** Page tarifs — maquette design/maquettes/Site-Tarifs.dc.html. @var array $config */
$p = $config['pricing'];
$proMonth = $p['coach_pro_month'];
$proSeasonMonthly = $proMonth === null ? null : round($proMonth * (1 - $p['season_discount']), 2);
$rows = [
    ['Équipes', '1', 'Jusqu’à 3', 'Illimité'],
    ['Formats 6x6, 4x4, 2x2 et mixte', 'Oui', 'Oui', 'Oui'],
    ['Match en direct hors ligne', 'Oui', 'Oui', 'Oui'],
    ['Stats', 'Mode simple', 'Complètes', 'Complètes'],
    ['Historique des matchs', 'Dernier match', 'Saison entière', 'Toutes les saisons'],
    ['Tableau tactique', 'Oui', 'Schémas illimités', 'Bibliothèque du club'],
    ['Exports PDF et CSV', '—', 'Oui', 'Oui'],
    ['Coach adjoint, saisie par un parent', '—', 'Oui', 'Oui'],
];
?>
<section class="pricing-hero on-navy">
  <div class="pricing-hero__inner container">
    <h1 class="display pricing-hero__title">Un tarif par coach, ou un pour tout le club.</h1>
    <p class="pricing-hero__lead">Le match en direct reste gratuit pour une équipe. Payez seulement pour l'historique, les stats complètes et plusieurs équipes.</p>
    <div class="billing-toggle" role="group" aria-label="Période de facturation" data-billing-toggle>
      <button type="button" class="billing-toggle__btn" data-billing="month" aria-pressed="false">Mensuel</button>
      <button type="button" class="billing-toggle__btn" data-billing="season" aria-pressed="true">À la saison · −<?= e((string) round($p['season_discount'] * 100)) ?> %</button>
    </div>
  </div>
</section>

<section class="offers container" aria-label="Offres">
  <article class="offer">
    <div class="offer__head"><h2 class="offer__name">Coach</h2><span class="offer__for">Pour découvrir avec une équipe</span></div>
    <span class="offer__price">0 €</span>
    <ul class="offer__list">
      <li>Une équipe, tous formats</li><li>Match en direct et rotation automatique</li><li>Stats en mode simple</li><li>Tableau tactique</li><li>Résumé partageable du dernier match</li>
    </ul>
    <a class="btn btn--outline offer__cta" href="<?= e(url($config, '/')) ?>#beta">Commencer gratuitement</a>
  </article>

  <article class="offer offer--featured">
    <div class="offer__head offer__head--row">
      <div><h2 class="offer__name">Coach Pro</h2><span class="offer__for">Pour suivre une saison entière</span></div>
      <span class="offer__badge">Le plus choisi</span>
    </div>
    <span class="offer__price offer__price--yellow">
      <span data-price-month hidden><?= e(price($proMonth)) ?></span><span data-price-season><?= e(price($proSeasonMonthly)) ?></span> €<span class="offer__per"> / mois</span>
    </span>
    <ul class="offer__list">
      <li>Jusqu'à 3 équipes</li><li>Stats complètes et par rotation</li><li>Historique et progression de chaque joueuse</li><li>Exports PDF et CSV</li><li>Coach adjoint et saisie par un parent</li>
    </ul>
    <a class="btn btn--yellow offer__cta" href="<?= e(url($config, '/')) ?>#beta">Essayer 30 jours</a>
  </article>

  <article class="offer">
    <div class="offer__head"><h2 class="offer__name">Club</h2><span class="offer__for">Pour toutes les équipes du club</span></div>
    <span class="offer__price"><?= e(price($p['club_season'])) ?> €<span class="offer__per"> / saison</span></span>
    <ul class="offer__list">
      <li>Équipes et coachs illimités</li><li>Tout Coach Pro pour chaque coach</li><li>Tableau de bord du responsable technique</li><li>Bibliothèque de schémas partagée</li><li>Facture au nom de l'association</li>
    </ul>
    <a class="btn btn--outline offer__cta" href="mailto:<?= e($config['contact_email']) ?>">Parler à un humain</a>
  </article>
</section>

<section class="section container" aria-label="Comparatif détaillé">
  <h2 class="display display--m">Comparatif détaillé</h2>
  <div class="table-wrap">
    <table class="compare">
      <thead><tr><th scope="col">Fonctionnalité</th><th scope="col">Coach</th><th scope="col">Coach Pro</th><th scope="col">Club</th></tr></thead>
      <tbody>
        <?php foreach ($rows as [$f, $a, $b, $c]): ?>
          <tr><th scope="row"><?= e($f) ?></th><td><?= e($a) ?></td><td><?= e($b) ?></td><td><?= e($c) ?></td></tr>
        <?php endforeach; ?>
      </tbody>
    </table>
  </div>
  <p class="fineprint">Prix TTC. Sans engagement en mensuel. Les associations non assujetties à la TVA paient le prix affiché.</p>
</section>
