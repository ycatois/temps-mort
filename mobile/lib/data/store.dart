import 'dart:math';

import '../domain/domain.dart';
import 'match_record.dart';

/// Stockage local, sur l'appareil (hors ligne d'abord). Implémentations : [SqliteStore] dans l'app,
/// [MemoryStore] dans les tests.
abstract interface class AppStore {
  Future<List<Team>> teams();
  Future<void> saveTeam(Team team);

  /// Matchs de l'équipe, du plus récent au plus ancien.
  Future<List<MatchRecord>> matches(String teamId);
  Future<void> saveMatch(MatchRecord match);

  Future<List<MatchEvent>> events(String matchId);

  /// Remplace la liste d'événements du match : appelé après chaque saisie et chaque annulation (V1-TEC-02).
  Future<void> saveEvents(String matchId, List<MatchEvent> events);

  /// Composition type de l'équipe dans ce format, ou null.
  Future<LineupTemplate?> lineupTemplate(String teamId, GameFormat format);
  Future<void> saveLineupTemplate(LineupTemplate template);
}

class MemoryStore implements AppStore {
  final _teams = <String, Team>{};
  final _matches = <String, MatchRecord>{};
  final _events = <String, List<MatchEvent>>{};
  final _templates = <String, LineupTemplate>{};

  @override
  Future<List<Team>> teams() async => _teams.values.toList();

  @override
  Future<void> saveTeam(Team team) async => _teams[team.id] = team;

  @override
  Future<List<MatchRecord>> matches(String teamId) async =>
      _matches.values.where((m) => m.teamId == teamId).toList()..sort((a, b) => b.date.compareTo(a.date));

  @override
  Future<void> saveMatch(MatchRecord match) async => _matches[match.id] = match;

  @override
  Future<List<MatchEvent>> events(String matchId) async => [...?_events[matchId]];

  @override
  Future<void> saveEvents(String matchId, List<MatchEvent> events) async => _events[matchId] = [...events];

  @override
  Future<LineupTemplate?> lineupTemplate(String teamId, GameFormat format) async => _templates['$teamId/${format.name}'];

  @override
  Future<void> saveLineupTemplate(LineupTemplate template) async =>
      _templates['${template.teamId}/${template.format.name}'] = template;
}

final _random = Random.secure();

/// Identifiant unique créé sur l'appareil, sans réseau.
String newId() {
  final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final noise = List.generate(8, (_) => _random.nextInt(36).toRadixString(36)).join();
  return '$time$noise';
}
