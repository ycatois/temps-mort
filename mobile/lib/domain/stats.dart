import 'match.dart';

/// Ce qu'une joueuse a apporté sur les échanges qu'elle a conclus (mode de saisie actuel :
/// la joueuse puis l'action qui termine l'échange).
class PlayerStats {
  const PlayerStats({
    this.aces = 0,
    this.attackPoints = 0,
    this.blocks = 0,
    this.serviceErrors = 0,
    this.attackErrors = 0,
    this.receptionErrors = 0,
    this.otherErrors = 0,
  });

  final int aces;
  final int attackPoints;
  final int blocks;
  final int serviceErrors;

  /// Attaque dehors ou contrée.
  final int attackErrors;
  final int receptionErrors;
  final int otherErrors;

  int get points => aces + attackPoints + blocks;
  int get errors => serviceErrors + attackErrors + receptionErrors + otherErrors;

  PlayerStats _add(RallyAction action) => PlayerStats(
        aces: aces + (action == RallyAction.ace ? 1 : 0),
        attackPoints: attackPoints + (action == RallyAction.attaque ? 1 : 0),
        blocks: blocks + (action == RallyAction.contre ? 1 : 0),
        serviceErrors: serviceErrors + (action == RallyAction.serviceFaute ? 1 : 0),
        attackErrors: attackErrors + (action == RallyAction.attaqueFaute ? 1 : 0),
        receptionErrors: receptionErrors + (action == RallyAction.receptionFaute ? 1 : 0),
        otherErrors: otherErrors + (action == RallyAction.autreFaute ? 1 : 0),
      );
}

/// D'où viennent nos points (V1-LIV-07).
class PointOrigin {
  const PointOrigin({this.scored = 0, this.opponentErrors = 0, this.unspecified = 0});

  /// Ace, attaque ou contre gagnants, avec ou sans joueuse désignée.
  final int scored;

  /// « +1 faute adverse ».
  final int opponentErrors;

  /// Point gagné sans préciser l'action.
  final int unspecified;

  int get total => scored + opponentErrors + unspecified;
}

class MatchStats {
  const MatchStats({
    required this.sideOutRate,
    required this.breakRate,
    required this.byPlayer,
    required this.byRotation,
    required this.origin,
    required this.pointsLost,
    required this.teamErrors,
  });

  /// Part (0 à 1) des échanges gagnés quand l'adversaire sert (null si aucun).
  final double? sideOutRate;

  /// Part (0 à 1) des échanges gagnés sur notre service (null si aucun).
  final double? breakRate;

  /// Détail par joueuse, pour celles qui ont conclu au moins un échange.
  final Map<String, PlayerStats> byPlayer;

  /// Échanges gagnés / perdus par rotation (R1..Rn), dans l'ordre des rotations.
  final Map<int, Score> byRotation;

  final PointOrigin origin;
  final int pointsLost;

  /// Fautes directes de l'équipe (échanges perdus sur une faute saisie, joueuse désignée ou non).
  final int teamErrors;

  int get pointsWon => origin.total;

  /// Points marqués par joueuse (ace, attaque, contre).
  Map<String, int> get pointsByPlayer => {
        for (final e in byPlayer.entries)
          if (e.value.points > 0) e.key: e.value.points,
      };

  /// Fautes directes par joueuse.
  Map<String, int> get errorsByPlayer => {
        for (final e in byPlayer.entries)
          if (e.value.errors > 0) e.key: e.value.errors,
      };

  /// Rotation au plus mauvais solde, pour le bloc « À retenir » ; null si aucune n'est déficitaire.
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

/// Statistiques du match, ou du set [setIndex] (0 = premier set) si précisé (V1-LIV-06).
MatchStats computeStats(List<RallyRecord> history, {int? setIndex}) {
  final rallies = setIndex == null ? history : history.where((r) => r.setIndex == setIndex).toList();

  double? rate(Iterable<RallyRecord> list) {
    final all = list.toList();
    if (all.isEmpty) return null;
    return all.where((r) => r.winner == Side.us).length / all.length;
  }

  final players = <String, PlayerStats>{};
  final rotations = <int, Score>{};
  var scored = 0, opponentErrors = 0, unspecified = 0, lost = 0, teamErrors = 0;
  for (final r in rallies) {
    final pid = r.playerId;
    final action = r.action;
    if (r.winner == Side.us) {
      if (action == null) {
        unspecified++;
      } else if (action == RallyAction.fauteAdverse) {
        opponentErrors++;
      } else if (action.scoring) {
        scored++;
      } else {
        unspecified++;
      }
    } else {
      lost++;
      if (action != null && !action.scoring) teamErrors++;
    }
    // Une joueuse est créditée d'une action gagnante sur un point gagné, d'une faute sur un point perdu.
    final credited = action != null &&
        action != RallyAction.fauteAdverse &&
        (r.winner == Side.us ? action.scoring : !action.scoring);
    if (pid != null && credited) {
      players[pid] = (players[pid] ?? const PlayerStats())._add(action);
    }
    rotations[r.rotation] = (rotations[r.rotation] ?? const Score()).plus(r.winner);
  }

  final sortedKeys = rotations.keys.toList()..sort();
  return MatchStats(
    sideOutRate: rate(rallies.where((r) => r.server == Side.them)),
    breakRate: rate(rallies.where((r) => r.server == Side.us)),
    byPlayer: Map.unmodifiable(players),
    byRotation: Map.unmodifiable({for (final k in sortedKeys) k: rotations[k]!}),
    origin: PointOrigin(scored: scored, opponentErrors: opponentErrors, unspecified: unspecified),
    pointsLost: lost,
    teamErrors: teamErrors,
  );
}
