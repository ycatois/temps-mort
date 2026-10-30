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
    this.fullInput = false,
    this.present,
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

  /// Saisie complète (chaque geste noté) plutôt que simple (l'action qui conclut l'échange).
  /// Choisie à la création du match, modifiable pendant le match (V1-STA-11).
  final bool fullInput;

  /// Joueuses présentes ce jour-là, liberos compris (V1-PRE-03) ; null = tout l'effectif actif.
  final List<String>? present;

  MatchRecord withFullInput(bool value) => copyWith(fullInput: value);

  MatchRecord copyWith({
    String? opponent,
    DateTime? date,
    String? venue,
    bool? home,
    String? competition,
    GameFormat? format,
    MatchRules? rules,
    bool? fullInput,
    List<String>? present,
  }) =>
      MatchRecord(
        id: id,
        teamId: teamId,
        opponent: opponent ?? this.opponent,
        date: date ?? this.date,
        venue: venue ?? this.venue,
        home: home ?? this.home,
        competition: competition ?? this.competition,
        format: format ?? this.format,
        rules: rules ?? this.rules,
        fullInput: fullInput ?? this.fullInput,
        present: present ?? this.present,
      );

  /// L'équipe telle qu'elle joue ce match : son format, et seulement les présentes.
  Team teamFor(Team team) => team.withFormat(format).withSquad(present);
}

/// Composition type d'une équipe dans un format (V1-PRE-09), rechargée au match suivant.
class LineupTemplate {
  LineupTemplate({
    required this.teamId,
    required this.format,
    required List<String> lineup,
    this.liberoId,
    this.secondLiberoId,
    this.captainId,
    this.system,
  }) : lineup = List.unmodifiable(lineup);

  final String teamId;
  final GameFormat format;

  /// Index 0 = poste 1, comme dans [StartSet].
  final List<String> lineup;
  final String? liberoId;
  final String? secondLiberoId;
  final String? captainId;
  final GameSystem? system;
}
