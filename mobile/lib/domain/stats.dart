import 'match.dart';

/// Ce qu'une joueuse a apporté. Mode simple : l'action qui conclut l'échange. Mode complet : aussi les
/// gestes en jeu ([TouchKind]), qui permettent la réception moyenne et l'efficacité en attaque.
class PlayerStats {
  const PlayerStats({
    this.aces = 0,
    this.attackPoints = 0,
    this.blocks = 0,
    this.serviceErrors = 0,
    this.attackErrors = 0,
    this.receptionErrors = 0,
    this.blockErrors = 0,
    this.digErrors = 0,
    this.setErrors = 0,
    this.otherErrors = 0,
    this.servesInPlay = 0,
    this.attacksInPlay = 0,
    this.blockTouches = 0,
    this.digs = 0,
    this.receptions = 0,
    this.receptionTotal = 0,
  });

  final int aces;
  final int attackPoints;
  final int blocks;
  final int serviceErrors;

  /// Attaque dehors ou contrée.
  final int attackErrors;

  /// Réception ratée (notée 0).
  final int receptionErrors;
  final int blockErrors;
  final int digErrors;
  final int setErrors;
  final int otherErrors;

  final int servesInPlay;
  final int attacksInPlay;
  final int blockTouches;
  final int digs;

  /// Réceptions notées (0 à 3) et somme des notes.
  final int receptions;
  final int receptionTotal;

  int get points => aces + attackPoints + blocks;
  int get errors => serviceErrors + attackErrors + receptionErrors + blockErrors + digErrors + setErrors + otherErrors;

  int get attackAttempts => attackPoints + attackErrors + attacksInPlay;

  /// (points − fautes et contrées) / tentatives (V1-LIV-02) ; null sans tentative.
  double? get attackEfficiency => attackAttempts == 0 ? null : (attackPoints - attackErrors) / attackAttempts;

  /// Moyenne des réceptions notées de 0 à 3 (V1-LIV-03) ; null sans réception.
  double? get receptionAverage => receptions == 0 ? null : receptionTotal / receptions;

  PlayerStats operator +(PlayerStats o) => PlayerStats(
        aces: aces + o.aces,
        attackPoints: attackPoints + o.attackPoints,
        blocks: blocks + o.blocks,
        serviceErrors: serviceErrors + o.serviceErrors,
        attackErrors: attackErrors + o.attackErrors,
        receptionErrors: receptionErrors + o.receptionErrors,
        blockErrors: blockErrors + o.blockErrors,
        digErrors: digErrors + o.digErrors,
        setErrors: setErrors + o.setErrors,
        otherErrors: otherErrors + o.otherErrors,
        servesInPlay: servesInPlay + o.servesInPlay,
        attacksInPlay: attacksInPlay + o.attacksInPlay,
        blockTouches: blockTouches + o.blockTouches,
        digs: digs + o.digs,
        receptions: receptions + o.receptions,
        receptionTotal: receptionTotal + o.receptionTotal,
      );

  static PlayerStats ofRally(RallyAction action) => switch (action) {
        RallyAction.ace => const PlayerStats(aces: 1),
        RallyAction.attaque => const PlayerStats(attackPoints: 1),
        RallyAction.contre => const PlayerStats(blocks: 1),
        RallyAction.serviceFaute => const PlayerStats(serviceErrors: 1),
        RallyAction.attaqueFaute => const PlayerStats(attackErrors: 1),
        RallyAction.receptionFaute => const PlayerStats(receptionErrors: 1, receptions: 1),
        RallyAction.contreFaute => const PlayerStats(blockErrors: 1),
        RallyAction.defenseFaute => const PlayerStats(digErrors: 1),
        RallyAction.passeFaute => const PlayerStats(setErrors: 1),
        RallyAction.autreFaute => const PlayerStats(otherErrors: 1),
        RallyAction.fauteAdverse => const PlayerStats(),
      };

  static PlayerStats ofTouch(TouchKind kind) => switch (kind) {
        TouchKind.serveInPlay => const PlayerStats(servesInPlay: 1),
        TouchKind.attackInPlay => const PlayerStats(attacksInPlay: 1),
        TouchKind.blockTouch => const PlayerStats(blockTouches: 1),
        TouchKind.digOk => const PlayerStats(digs: 1),
        TouchKind.reception3 || TouchKind.reception2 || TouchKind.reception1 =>
          PlayerStats(receptions: 1, receptionTotal: kind.receptionGrade!),
      };
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
    required this.fullInput,
  });

  /// Part (0 à 1) des échanges gagnés quand l'adversaire sert (null si aucun).
  final double? sideOutRate;

  /// Part (0 à 1) des échanges gagnés sur notre service (null si aucun).
  final double? breakRate;

  /// Détail par joueuse, pour celles qui ont au moins une action saisie.
  final Map<String, PlayerStats> byPlayer;

  /// Échanges gagnés / perdus par rotation (R1..Rn), dans l'ordre des rotations.
  final Map<int, Score> byRotation;

  final PointOrigin origin;
  final int pointsLost;

  /// Fautes directes de l'équipe (échanges perdus sur une faute saisie, joueuse désignée ou non).
  final int teamErrors;

  /// La période contient des gestes en jeu (saisie complète) : réception et efficacité ont un sens.
  /// En saisie simple, les attaques restées en jeu manquent et l'efficacité serait faussée.
  final bool fullInput;

  int get pointsWon => origin.total;

  /// Toute l'équipe, joueuse par joueuse additionnées.
  PlayerStats get team => byPlayer.values.fold(const PlayerStats(), (a, b) => a + b);

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
/// [touches] : gestes en jeu de la saisie complète.
MatchStats computeStats(List<RallyRecord> history, {List<TouchRecord> touches = const [], int? setIndex}) {
  final rallies = setIndex == null ? history : history.where((r) => r.setIndex == setIndex).toList();
  final gestures = setIndex == null ? touches : touches.where((t) => t.setIndex == setIndex).toList();

  double? rate(Iterable<RallyRecord> list) {
    final all = list.toList();
    if (all.isEmpty) return null;
    return all.where((r) => r.winner == Side.us).length / all.length;
  }

  final players = <String, PlayerStats>{};
  void credit(String id, PlayerStats s) => players[id] = (players[id] ?? const PlayerStats()) + s;

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
    if (pid != null && credited) credit(pid, PlayerStats.ofRally(action));
    rotations[r.rotation] = (rotations[r.rotation] ?? const Score()).plus(r.winner);
  }
  for (final t in gestures) {
    credit(t.playerId, PlayerStats.ofTouch(t.kind));
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
    fullInput: gestures.isNotEmpty,
  );
}
