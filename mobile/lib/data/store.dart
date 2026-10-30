import 'dart:math';

import '../domain/domain.dart';
import 'match_record.dart';
import 'tactic_play.dart';

/// Stockage local, sur l'appareil (hors ligne d'abord). Implémentations : [SqliteStore] dans l'app,
/// [MemoryStore] dans les tests.
abstract interface class AppStore {
  Future<List<Team>> teams();
  Future<void> saveTeam(Team team);

  /// Matchs de l'équipe, du plus récent au plus ancien.
  Future<List<MatchRecord>> matches(String teamId);
  Future<void> saveMatch(MatchRecord match);

  /// Supprime le match et tous ses événements (E11).
  Future<void> deleteMatch(String id);

  Future<List<MatchEvent>> events(String matchId);

  /// Remplace la liste d'événements du match : appelé après chaque saisie et chaque annulation (V1-TEC-02).
  Future<void> saveEvents(String matchId, List<MatchEvent> events);

  /// Composition type de l'équipe dans ce format, ou null.
  Future<LineupTemplate?> lineupTemplate(String teamId, GameFormat format);
  Future<void> saveLineupTemplate(LineupTemplate template);

  /// Schémas tactiques de l'équipe (V1-TAC-07), du plus récent au plus ancien.
  Future<List<TacticPlay>> plays(String teamId);
  Future<void> savePlay(TacticPlay play);
  Future<void> deletePlay(String id);

  /// Efface les matchs (et leurs événements), compositions types et schémas de l'équipe ;
  /// l'équipe et son effectif restent. Sert à remettre l'équipe de démonstration à zéro.
  Future<void> clearTeamData(String teamId);
}

class MemoryStore implements AppStore {
  final _teams = <String, Team>{};
  final _matches = <String, MatchRecord>{};
  final _events = <String, List<MatchEvent>>{};
  final _templates = <String, LineupTemplate>{};
  final _plays = <String, TacticPlay>{};

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
  Future<void> deleteMatch(String id) async {
    _matches.remove(id);
    _events.remove(id);
  }

  @override
  Future<List<MatchEvent>> events(String matchId) async => [...?_events[matchId]];

  @override
  Future<void> saveEvents(String matchId, List<MatchEvent> events) async => _events[matchId] = [...events];

  @override
  Future<LineupTemplate?> lineupTemplate(String teamId, GameFormat format) async => _templates['$teamId/${format.name}'];

  @override
  Future<void> saveLineupTemplate(LineupTemplate template) async =>
      _templates['${template.teamId}/${template.format.name}'] = template;

  @override
  Future<List<TacticPlay>> plays(String teamId) async =>
      _plays.values.where((p) => p.teamId == teamId).toList()..sort((a, b) => b.savedAt.compareTo(a.savedAt));

  @override
  Future<void> savePlay(TacticPlay play) async => _plays[play.id] = play;

  @override
  Future<void> deletePlay(String id) async => _plays.remove(id);

  @override
  Future<void> clearTeamData(String teamId) async {
    final matchIds = [for (final m in _matches.values) if (m.teamId == teamId) m.id];
    for (final id in matchIds) {
      _matches.remove(id);
      _events.remove(id);
    }
    _templates.removeWhere((_, t) => t.teamId == teamId);
    _plays.removeWhere((_, p) => p.teamId == teamId);
  }
}

final _random = Random.secure();

/// Identifiant unique créé sur l'appareil, sans réseau.
String newId() {
  final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final noise = List.generate(8, (_) => _random.nextInt(36).toRadixString(36)).join();
  return '$time$noise';
}
