<?php /** Page d'accueil — maquette design/maquettes/Site-Accueil.dc.html. @var array $config @var ?string $betaStatus */
$p = $config['pricing'];
$features = [
    ['R3', 'Feuille de match vivante', 'Score, service et rotation suivis seuls. Remplacements et libero contrôlés selon les règles.'],
    ['2 tapes', 'Stats sans quitter le jeu des yeux', 'La joueuse, puis l\'action. Mode simple pour un coach seul, mode complet si un parent tient la tablette.'],
    ['30 s', 'Tableau tactique au doigt', 'Au temps mort, la rotation du match est déjà placée. Déplacez, dessinez, montrez la tablette.'],
    ['1 message', 'Résumé prêt à partager', 'Score par set, meilleures joueuses, rotation à travailler. Envoyé à l\'équipe dès le coup de sifflet final.'],
];
$gym = [
    ['Hors ligne', 'Aucune saisie perdue'],
    ['Tablette et smartphone', 'Même compte, mêmes données'],
    ['Données en France', 'Minimum de données sur les mineures'],
    ['Annuler sans limite', 'Une erreur ne casse pas le match'],
];
$faq = [
    ['Faut-il du réseau dans le gymnase ?', 'Non. Tout le match se joue hors ligne ; les données se synchronisent dès que le réseau revient.'],
    ['Ça marche pour le 4x4, le 2x2 et les équipes mixtes ?', 'Oui. Le format et la mixité se règlent par équipe, et peuvent changer pour un tournoi.'],
    ['Je coache seul : est-ce que j\'aurai le temps de saisir ?', 'Le mode simple se limite au point gagné ou perdu et à la joueuse concernée : deux touches par échange.'],
    ['Que devient la donnée de mes joueuses mineures ?', 'Elle est hébergée en France, limitée au nécessaire et supprimée sur simple demande.'],
];
?>
<section class="hero on-navy">
  <div class="hero__inner container">
    <div class="hero__text">
      <span class="eyebrow">Application de coaching volley</span>
      <h1 class="display display--xl">Le banc de touche tient dans votre tablette.</h1>
      <p class="hero__lead">Stats en direct, rotation automatique et tableau tactique au doigt. Pensé par un coach pour les coachs amateurs, et utilisable sans réseau dans le gymnase.</p>
      <div class="hero__actions">
        <a class="btn btn--yellow" href="#beta">Essayer gratuitement</a>
        <a class="btn btn--ghost-light" href="#fonctions">Voir comment ça marche</a>
      </div>
      <span class="hero__note">Gratuit pour une équipe · tablette et smartphone · données hébergées en France</span>
    </div>

    <div class="hero__visual" role="img" aria-label="Aperçu de l'application sur tablette">
      <div class="device">
        <div class="device__screen">
          <div class="device__bar">
            <span class="device__set">SET 2</span>
            <span class="device__score">18 <span class="device__muted device__dash">–</span> <span class="device__muted">15</span></span>
            <span class="device__tm">Temps mort</span>
          </div>
          <div class="device__body">
            <div class="court">
              <div class="court__floor"></div>
              <div class="court__line"></div>
              <span class="court__p court__p--z4 court__p--server"></span>
              <span class="court__p court__p--z3"></span>
              <span class="court__p court__p--z2"></span>
              <span class="court__p court__p--z5"></span>
              <span class="court__p court__p--z6 court__p--libero"></span>
              <span class="court__p court__p--z1"></span>
            </div>
            <div class="device__pad">
              <span class="k k--blue"></span><span class="k"></span><span class="k k--err"></span><span class="k k--err"></span>
              <span class="k k--blue"></span><span class="k"></span><span class="k"></span><span class="k k--err"></span>
              <span class="k k--wide"></span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</section>

<section id="formats" class="formats" aria-label="Formats couverts">
  <div class="formats__inner container">
    <span>6x6</span><span>4x4</span><span>2x2</span><span>Féminin</span><span>Masculin</span><span>Mixte</span><span>Toutes catégories, des plus jeunes aux vétérans</span>
  </div>
</section>

<section id="fonctions" class="section container">
  <div class="section__head">
    <span class="eyebrow">Pendant le match</span>
    <h2 class="display display--l">Tout ce que vous notiez sur un carnet, en deux touches.</h2>
  </div>
  <div class="grid-cards">
    <?php foreach ($features as [$big, $h, $txt]): ?>
      <article class="card feature">
        <span class="feature__big"><?= e($big) ?></span>
        <h3 class="feature__title"><?= e($h) ?></h3>
        <p class="card__text"><?= e($txt) ?></p>
      </article>
    <?php endforeach; ?>
  </div>
</section>

<section class="gym container">
  <div class="gym__text">
    <span class="eyebrow">Pensé pour le gymnase</span>
    <h2 class="display display--l">Pas de réseau, une main libre, des boutons qui se voient de loin.</h2>
    <p class="gym__lead">L'application fonctionne entièrement hors ligne et synchronise à la sortie du gymnase. L'écran reste allumé, chaque saisie se corrige d'un geste.</p>
  </div>
  <ul class="gym__list">
    <?php foreach ($gym as [$t, $s]): ?>
      <li class="gym__item"><strong><?= e($t) ?></strong><span><?= e($s) ?></span></li>
    <?php endforeach; ?>
  </ul>
</section>

<section class="founder">
  <div class="founder__inner container">
    <div class="founder__photo">[Photo du coach sur le banc]</div>
    <div class="founder__text">
      <span class="eyebrow">Né sur un banc de touche</span>
      <p class="founder__quote">« [Votre histoire : pourquoi vous, coach d'une équipe féminine, avez construit l'outil qui vous manquait le samedi.] »</p>
      <span class="founder__sig">[Prénom], coach de volley et fondateur</span>
    </div>
  </div>
</section>

<section class="section container">
  <div class="section__row">
    <h2 class="display display--l">Gratuit pour commencer.</h2>
    <a class="section__link" href="<?= e(url($config, '/tarifs')) ?>">Comparer les offres</a>
  </div>
  <div class="grid-cards grid-cards--3">
    <div class="card offer-mini">
      <span class="offer-mini__name">Coach</span>
      <span class="offer-mini__price">0 €</span>
      <span class="offer-mini__desc">Une équipe, match en direct, stats simples, tableau tactique</span>
    </div>
    <div class="card card--navy offer-mini">
      <span class="offer-mini__name">Coach Pro</span>
      <span class="offer-mini__price offer-mini__price--yellow"><?= e(price($p['coach_pro_month'])) ?> €<span class="offer-mini__per"> / mois</span></span>
      <span class="offer-mini__desc">Stats complètes, historique de saison, plusieurs équipes, exports</span>
    </div>
    <div class="card offer-mini">
      <span class="offer-mini__name">Club</span>
      <span class="offer-mini__price"><?= e(price($p['club_season'])) ?> €<span class="offer-mini__per"> / an</span></span>
      <span class="offer-mini__desc">Toutes les équipes et tous les coachs du club</span>
    </div>
  </div>
</section>

<section id="faq" class="faq">
  <div class="faq__inner container container--narrow">
    <h2 class="display display--m faq__title">Questions fréquentes</h2>
    <?php foreach ($faq as $i => [$q, $a]): ?>
      <details class="faq__item"<?= $i === 0 ? ' open' : '' ?>>
        <summary><?= e($q) ?></summary>
        <p><?= e($a) ?></p>
      </details>
    <?php endforeach; ?>
  </div>
</section>

<?php require dirname(__DIR__) . '/partials/beta.php'; ?>
