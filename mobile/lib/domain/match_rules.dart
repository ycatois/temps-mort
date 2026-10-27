import 'team.dart';

/// Règles d'un match. Les valeurs par défaut suivent les usages courants ; tout est modifiable
/// par le coach (championnats jeunes, tournois et loisir ont souvent leurs propres règlements).
class MatchRules {
  const MatchRules({
    required this.setsToWin,
    required this.pointsPerSet,
    required this.pointsDecidingSet,
    this.minLead = 2,
    required this.substitutionsPerSet,
    required this.timeoutsPerSet,
    required this.liberoAllowed,
  });

  factory MatchRules.defaultFor(GameFormat format) => switch (format) {
        GameFormat.six => const MatchRules(
            setsToWin: 3, pointsPerSet: 25, pointsDecidingSet: 15,
            substitutionsPerSet: 6, timeoutsPerSet: 2, liberoAllowed: true),
        GameFormat.four => const MatchRules(
            setsToWin: 2, pointsPerSet: 25, pointsDecidingSet: 15,
            substitutionsPerSet: null, timeoutsPerSet: 2, liberoAllowed: false),
        GameFormat.two => const MatchRules(
            setsToWin: 2, pointsPerSet: 21, pointsDecidingSet: 15,
            substitutionsPerSet: 0, timeoutsPerSet: 1, liberoAllowed: false),
      };

  final int setsToWin;
  final int pointsPerSet;
  final int pointsDecidingSet;
  final int minLead;

  /// null = remplacements illimités.
  final int? substitutionsPerSet;
  final int timeoutsPerSet;
  final bool liberoAllowed;

  int get maxSets => setsToWin * 2 - 1;

  int targetFor(int setIndex) => setIndex == maxSets - 1 ? pointsDecidingSet : pointsPerSet;

  static const Object _keep = Object();

  /// [substitutionsPerSet] accepte null (illimité) : ne pas le passer pour le conserver.
  MatchRules copyWith({
    int? setsToWin,
    int? pointsPerSet,
    int? pointsDecidingSet,
    int? minLead,
    Object? substitutionsPerSet = _keep,
    int? timeoutsPerSet,
    bool? liberoAllowed,
  }) =>
      MatchRules(
        setsToWin: setsToWin ?? this.setsToWin,
        pointsPerSet: pointsPerSet ?? this.pointsPerSet,
        pointsDecidingSet: pointsDecidingSet ?? this.pointsDecidingSet,
        minLead: minLead ?? this.minLead,
        substitutionsPerSet: identical(substitutionsPerSet, _keep)
            ? this.substitutionsPerSet
            : substitutionsPerSet as int?,
        timeoutsPerSet: timeoutsPerSet ?? this.timeoutsPerSet,
        liberoAllowed: liberoAllowed ?? this.liberoAllowed,
      );
}
