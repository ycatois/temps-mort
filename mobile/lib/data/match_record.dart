import '../domain/domain.dart';

/// Fiche d'un match (écran E03 Nouveau match). Les événements du match sont stockés à part,
/// au fil de la saisie : voir [AppStore.saveEvents].
class MatchRecord {
  const MatchRecord({
    required this.id,
    required this.teamId,
    required this.opponent,
    required this.date,
    this.venue = '',
    this.home = true,
    this.competition = '',
    required this.format,
    required this.rules,
  });

  final String id;
  final String teamId;
  final String opponent;

  /// Date et heure du match (heure locale de l'appareil).
  final DateTime date;
  final String venue;
  final bool home;
  final String competition;

  /// Format joué ce jour-là : celui de l'équipe par défaut, modifiable pour ce match (V1-FOR-08).
  final GameFormat format;
  final MatchRules rules;

  /// L'équipe telle qu'elle joue ce match.
  Team teamFor(Team team) => team.withFormat(format);
}

/// Composition type d'une équipe dans un format (V1-PRE-09), rechargée au match suivant.
class LineupTemplate {
  LineupTemplate({
    required this.teamId,
    required this.format,
    required List<String> lineup,
    this.liberoId,
    this.captainId,
    this.system,
  }) : lineup = List.unmodifiable(lineup);

  final String teamId;
  final GameFormat format;

  /// Index 0 = poste 1, comme dans [StartSet].
  final List<String> lineup;
  final String? liberoId;
  final String? captainId;
  final GameSystem? system;
}
