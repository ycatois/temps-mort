<?php /** @var array $config @var string $title @var string $description @var string $content @var string $current */ ?>
<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title><?= e($title) ?></title>
<?php if ($description !== ''): ?><meta name="description" content="<?= e($description) ?>"><?php endif; ?>
<link rel="icon" href="<?= e(url($config, '/assets/img/favicon.svg')) ?>" type="image/svg+xml">
<link rel="preload" href="<?= e(url($config, '/assets/fonts/barlow-condensed-latin-700-normal.woff2')) ?>" as="font" type="font/woff2" crossorigin>
<link rel="preload" href="<?= e(url($config, '/assets/fonts/barlow-latin-400-normal.woff2')) ?>" as="font" type="font/woff2" crossorigin>
<link rel="stylesheet" href="<?= e(asset($config, 'assets/css/tokens.css')) ?>">
<link rel="stylesheet" href="<?= e(asset($config, 'assets/css/base.css')) ?>">
<link rel="stylesheet" href="<?= e(asset($config, 'assets/css/site.css')) ?>">
<meta property="og:title" content="<?= e($title) ?>">
<meta property="og:site_name" content="<?= e($config['brand']) ?>">
<meta property="og:locale" content="fr_FR">
</head>
<body>
<a class="skip-link" href="#contenu">Aller au contenu</a>
<?php require __DIR__ . '/partials/header.php'; ?>
<main id="contenu">
<?= $content ?>
</main>
<?php require __DIR__ . '/partials/footer.php'; ?>
<script src="<?= e(asset($config, 'assets/js/site.js')) ?>" defer></script>
</body>
</html>
