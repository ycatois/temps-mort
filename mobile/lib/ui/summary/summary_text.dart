import '../../domain/domain.dart';

/// Textes du résumé (E10), communs à l'écran, à l'image et au PDF.

String percent(double? v) => v == null ? '—' : '${(v * 100).round()} %';

/// « 2,1 » : note de réception avec une décimale, virgule française.
String grade(double? v) => v == null ? '—' : v.toStringAsFixed(1).replaceAll('.', ',');

String plural(int n, String word, [String? many]) => '$n ${n > 1 ? (many ?? '${word}s') : word}';

String resultLabel(MatchSummary s) => switch (s.winner) {
      Side.us => 'Victoire',
      Side.them => 'Défaite',
      null => 'Match en cours',
    };

/// « Meilleure marqueuse » pour une équipe féminine ; formulation neutre sinon (« Plus de points »).
String bestCategoryLabel(BestCategory c, Team team) {
  final feminine = team.gender == TeamGender.feminine;
  return switch (c) {
    BestCategory.scorer => feminine ? 'Meilleure marqueuse' : 'Plus de points',
    BestCategory.block => feminine ? 'Meilleure au contre' : 'Plus de contres',
    BestCategory.serve => feminine ? 'Meilleure au service' : 'Plus d\'aces',
    BestCategory.reception => 'Meilleure réception',
  };
}

String playerLabel(Team team, String id) {
  final p = team.player(id);
  return p == null ? '?' : '#${p.number} ${p.firstName}';
}

/// « 21 points · 38 % en attaque », « 5 contres gagnants », « 4 aces », « 2,6 de moyenne sur 31 ».
String bestDetail(BestPlayer b, {required bool fullInput}) {
  final s = b.stats;
  return switch (b.category) {
    BestCategory.scorer => fullInput && s.attackAttempts > 0
        ? '${plural(s.points, 'point')} · ${percent(s.attackEfficiency)} en attaque'
        : plural(s.points, 'point'),
    BestCategory.block => plural(s.blocks, 'contre gagnant', 'contres gagnants'),
    BestCategory.serve => plural(s.aces, 'ace'),
    BestCategory.reception => '${grade(s.receptionAverage)} de moyenne sur ${s.receptions}',
  };
}

/// Phrase « à retenir » : la partie en gras, puis la suite.
({String bold, String rest, bool positive}) takeawayText(Takeaway t) => switch (t) {
      RotationTakeaway(:final rotation, :final score, :final strongest, :final receptionAverage) => (
          bold: 'Rotation $rotation',
          rest: '${strongest ? ' la plus forte' : ' la plus faible'} : '
              '${plural(score.us, 'point gagné', 'points gagnés')} pour ${score.them} perdu${score.them > 1 ? 's' : ''}'
              '${receptionAverage == null ? '' : ', réception à ${grade(receptionAverage)}'}.',
          positive: strongest,
        ),
      ServiceErrorsTakeaway(:final total, :final worstSet, :final inWorstSet, :final worstSetLost) => (
          bold: plural(total, 'faute de service', 'fautes de service'),
          rest: worstSet == null ? '.' : ', dont $inWorstSet dans le set ${worstSet + 1}${worstSetLost ? ' perdu' : ''}.',
          positive: false,
        ),
    };

/// Les chiffres clés du bas de la carte.
List<(String, String)> keyFigures(MatchSummary s) => [
      ('Side-out', percent(s.stats.sideOutRate)),
      ('Break', percent(s.stats.breakRate)),
      if (s.stats.fullInput) ('Réception', '${grade(s.stats.team.receptionAverage)} / 3'),
      ('Fautes directes', '${s.stats.teamErrors}'),
    ];

/// Nom de fichier sans accent ni espace : « resume-2026-11-15-as-rennes ».
String exportFileName(DateTime? date, String? opponent) {
  final parts = ['resume'];
  if (date != null) {
    parts.add('${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}');
  }
  if (opponent != null && opponent.trim().isNotEmpty) parts.add(_slug(opponent));
  return parts.join('-');
}

String _slug(String s) {
  const from = 'àâäáãçéèêëíìîïñóòôöõúùûüýÿœæ';
  const to = 'aaaaaceeeeiiiinooooouuuuyyoa';
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final i = from.indexOf(ch);
    final c = i >= 0 ? to[i] : ch;
    b.write(RegExp('[a-z0-9]').hasMatch(c) ? c : '-');
  }
  return b.toString().replaceAll(RegExp('-+'), '-').replaceAll(RegExp(r'^-|-$'), '');
}
