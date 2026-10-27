import 'match.dart';

class MatchStats {
  const MatchStats({
    required this.sideOutRate,
    required this.breakRate,
    required this.pointsByPlayer,
    required this.errorsByPlayer,
    required this.byRotation,
  });

  /// Part (0 à 1) des échanges gagnés quand l'adversaire sert (null si aucun).
  final double? sideOutRate;

  /// Part (0 à 1) des échanges gagnés sur notre service (null si aucun).
  final double? breakRate;

  /// Points marqués par joueuse (ace, attaque, contre).
  final Map<String, int> pointsByPlayer;

  /// Fautes directes par joueuse.
  final Map<String, int> errorsByPlayer;

  /// Échanges gagnés / perdus par rotation (R1..Rn), dans l'ordre des rotations.
  final Map<int, Score> byRotation;

  /// Rotation au plus mauvais solde, pour le bloc « À retenir » du résumé ; null si aucune n'est déficitaire.
  int? get weakestRotation {
    int? worst;
    var worstBalance = 0;
    byRotation.forEach((rotation, s) {
      final balance = s.us - s.them;
      if (balance < worstBalance) {
        worst = rotation;
        worstBalance = balance;
      }
    });
    return worst;
  }
}

MatchStats computeStats(List<RallyRecord> history, {int? setIndex}) {
  final rallies = setIndex == null ? history : history.where((r) => r.setIndex == setIndex).toList();

  double? rate(Iterable<RallyRecord> list) {
    final all = list.toList();
    if (all.isEmpty) return null;
    return all.where((r) => r.winner == Side.us).length / all.length;
  }

  final points = <String, int>{};
  final errors = <String, int>{};
  final rotations = <int, Score>{};
  for (final r in rallies) {
    final pid = r.playerId;
    final action = r.action;
    if (pid != null && action != null) {
      if (r.winner == Side.us && action.scoring && action != RallyAction.fauteAdverse) {
        points[pid] = (points[pid] ?? 0) + 1;
      }
      if (r.winner == Side.them && !action.scoring) {
        errors[pid] = (errors[pid] ?? 0) + 1;
      }
    }
    rotations[r.rotation] = (rotations[r.rotation] ?? const Score()).plus(r.winner);
  }

  final sortedKeys = rotations.keys.toList()..sort();
  return MatchStats(
    sideOutRate: rate(rallies.where((r) => r.server == Side.them)),
    breakRate: rate(rallies.where((r) => r.server == Side.us)),
    pointsByPlayer: Map.unmodifiable(points),
    errorsByPlayer: Map.unmodifiable(errors),
    byRotation: Map.unmodifiable({for (final k in sortedKeys) k: rotations[k]!}),
  );
}
