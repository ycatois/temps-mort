import 'match.dart';
import 'stats.dart';
import 'team.dart';

/// Catégories de « meilleure joueuse » du résumé (V1-FIN-01).
enum BestCategory { scorer, block, serve, reception }

/// Meilleure joueuse d'une catégorie. [value] : points, contres ou aces ; moyenne de réception
/// pour [BestCategory.reception].
class BestPlayer {
  const BestPlayer({required this.category, required this.playerId, required this.value, required this.stats});

  final BestCategory category;
  final String playerId;
  final num value;

  /// Toute la ligne de la joueuse, pour le détail (efficacité, nombre de réceptions).
  final PlayerStats stats;
}

/// Point « à retenir pour l'entraînement » (maquette Tablette-Resume). Le texte est écrit par l'écran.
sealed class Takeaway {
  const Takeaway();
}

/// Rotation la plus forte (meilleur solde positif) ou la plus faible (pire solde négatif).
/// [receptionAverage] : réception moyenne dans cette rotation, en saisie complète seulement.
final class RotationTakeaway extends Takeaway {
  const RotationTakeaway({required this.rotation, required this.score, required this.strongest, this.receptionAverage});

  final int rotation;
  final Score score;
  final bool strongest;
  final double? receptionAverage;
}

/// Fautes de service du match, et le set qui en compte le plus (null si aucun ne se détache).
final class ServiceErrorsTakeaway extends Takeaway {
  const ServiceErrorsTakeaway({required this.total, this.worstSet, this.inWorstSet = 0, this.worstSetLost = false});

  final int total;

  /// Index du set (0 = premier set).
  final int? worstSet;
  final int inWorstSet;
  final bool worstSetLost;
}

/// Résumé automatique du match (E10, V1-FIN-01), calculé depuis l'état rejoué : rien n'est saisi en plus.
class MatchSummary {
  const MatchSummary({
    required this.sets,
    required this.setsWon,
    required this.finished,
    required this.stats,
    required this.best,
    required this.takeaways,
  });

  /// Score de chaque set joué, y compris le set en cours s'il a commencé.
  final List<Score> sets;
  final Score setsWon;
  final bool finished;
  final MatchStats stats;
  final List<BestPlayer> best;
  final List<Takeaway> takeaways;

  /// Vainqueur, ou null tant que le match n'est pas terminé.
  Side? get winner => !finished ? null : (setsWon.us > setsWon.them ? Side.us : Side.them);

  BestPlayer? bestOf(BestCategory category) {
    for (final b in best) {
      if (b.category == category) return b;
    }
    return null;
  }
}

/// Réceptions minimum pour être « meilleure en réception » : une seule réception parfaite ne suffit pas.
const int minReceptionsForBest = 3;

MatchSummary summarize(Team team, MatchState state) {
  final current = state.phase == Phase.inPlay && (state.score.us > 0 || state.score.them > 0);
  final sets = [...state.setsDone, if (current) state.score];
  final stats = computeStats(state.history, touches: state.touches);

  // À égalité : moins de fautes, puis le plus petit numéro (résultat stable d'un affichage à l'autre).
  int number(String id) => team.player(id)?.number ?? 999;
  BestPlayer? best(BestCategory category, num Function(PlayerStats) value, {bool Function(PlayerStats)? eligible}) {
    MapEntry<String, PlayerStats>? top;
    for (final e in stats.byPlayer.entries) {
      if (eligible != null && !eligible(e.value)) continue;
      final v = value(e.value);
      if (v <= 0) continue;
      if (top == null) {
        top = e;
        continue;
      }
      final t = value(top.value);
      final better = v > t ||
          (v == t &&
              (e.value.errors < top.value.errors ||
                  (e.value.errors == top.value.errors && number(e.key) < number(top.key))));
      if (better) top = e;
    }
    return top == null ? null : BestPlayer(category: category, playerId: top.key, value: value(top.value), stats: top.value);
  }

  final bests = [
    best(BestCategory.scorer, (s) => s.points),
    best(BestCategory.block, (s) => s.blocks),
    best(BestCategory.serve, (s) => s.aces),
    if (stats.fullInput)
      best(BestCategory.reception, (s) => s.receptionAverage ?? 0, eligible: (s) => s.receptions >= minReceptionsForBest),
  ];

  return MatchSummary(
    sets: sets,
    setsWon: state.setsWon,
    finished: state.phase == Phase.finished,
    stats: stats,
    best: [for (final b in bests) if (b != null) b],
    takeaways: _takeaways(state, stats),
  );
}

List<Takeaway> _takeaways(MatchState state, MatchStats stats) {
  final result = <Takeaway>[];

  double? receptionIn(int rotation) {
    if (!stats.fullInput) return null;
    var count = 0, total = 0;
    for (final t in state.touches) {
      final grade = t.kind.receptionGrade;
      if (t.rotation == rotation && grade != null) {
        count++;
        total += grade;
      }
    }
    // La réception ratée (notée 0) est un échange perdu.
    count += state.history.where((r) => r.rotation == rotation && r.action == RallyAction.receptionFaute).length;
    return count == 0 ? null : total / count;
  }

  int? strongest;
  var bestBalance = 0;
  stats.byRotation.forEach((rotation, s) {
    final balance = s.us - s.them;
    if (balance > bestBalance) {
      strongest = rotation;
      bestBalance = balance;
    }
  });
  if (strongest != null) {
    result.add(RotationTakeaway(
        rotation: strongest!, score: stats.byRotation[strongest]!, strongest: true, receptionAverage: receptionIn(strongest!)));
  }
  final weakest = stats.weakestRotation;
  if (weakest != null) {
    result.add(RotationTakeaway(
        rotation: weakest, score: stats.byRotation[weakest]!, strongest: false, receptionAverage: receptionIn(weakest)));
  }

  final serviceErrors = state.history.where((r) => r.winner == Side.them && r.action == RallyAction.serviceFaute).toList();
  if (serviceErrors.isNotEmpty) {
    final bySet = <int, int>{};
    for (final r in serviceErrors) {
      bySet[r.setIndex] = (bySet[r.setIndex] ?? 0) + 1;
    }
    int? worst;
    var worstCount = 0;
    var tie = false;
    bySet.forEach((set, n) {
      if (n > worstCount) {
        worst = set;
        worstCount = n;
        tie = false;
      } else if (n == worstCount) {
        tie = true;
      }
    });
    // On ne cite un set que s'il se détache des autres et qu'il y en a eu plusieurs.
    final cite = bySet.length > 1 && !tie;
    final lost = cite && worst! < state.setsDone.length && state.setsDone[worst!].them > state.setsDone[worst!].us;
    result.add(ServiceErrorsTakeaway(
      total: serviceErrors.length,
      worstSet: cite ? worst : null,
      inWorstSet: cite ? worstCount : 0,
      worstSetLost: lost,
    ));
  }
  return result;
}
