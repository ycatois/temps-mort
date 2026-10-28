import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../domain/domain.dart';
import 'codec.dart';
import 'match_record.dart';
import 'store.dart';

/// Stockage SQLite sur l'appareil. Chaque équipe et chaque match est une ligne JSON ;
/// les événements d'un match sont une ligne par événement, dans l'ordre de saisie.
class SqliteStore implements AppStore {
  SqliteStore._(this._db);

  final Database _db;

  /// [factory] : fabrique de base, à préciser seulement dans les tests (sqflite_common_ffi).
  static Future<SqliteStore> open({String? path, DatabaseFactory? factory}) async {
    final f = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await f.getDatabasesPath(), 'temps_mort.db');
    final db = await f.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('CREATE TABLE teams (id TEXT PRIMARY KEY, data TEXT NOT NULL)');
          await db.execute(
              'CREATE TABLE matches (id TEXT PRIMARY KEY, team_id TEXT NOT NULL, date TEXT NOT NULL, data TEXT NOT NULL)');
          await db.execute('CREATE INDEX matches_team ON matches (team_id, date)');
          await db.execute('CREATE TABLE match_events (match_id TEXT NOT NULL, seq INTEGER NOT NULL, '
              'data TEXT NOT NULL, PRIMARY KEY (match_id, seq))');
        },
      ),
    );
    return SqliteStore._(db);
  }

  Future<void> close() => _db.close();

  @override
  Future<List<Team>> teams() async {
    final rows = await _db.query('teams', orderBy: 'rowid');
    return [for (final r in rows) teamFromJson(_decode(r['data']))];
  }

  @override
  Future<void> saveTeam(Team team) =>
      _db.insert('teams', {'id': team.id, 'data': jsonEncode(teamToJson(team))}, conflictAlgorithm: ConflictAlgorithm.replace);

  @override
  Future<List<MatchRecord>> matches(String teamId) async {
    final rows = await _db.query('matches', where: 'team_id = ?', whereArgs: [teamId], orderBy: 'date DESC');
    return [for (final r in rows) matchFromJson(_decode(r['data']))];
  }

  @override
  Future<void> saveMatch(MatchRecord match) => _db.insert(
        'matches',
        {'id': match.id, 'team_id': match.teamId, 'date': match.date.toIso8601String(), 'data': jsonEncode(matchToJson(match))},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  @override
  Future<List<MatchEvent>> events(String matchId) async {
    final rows = await _db.query('match_events', where: 'match_id = ?', whereArgs: [matchId], orderBy: 'seq');
    return [for (final r in rows) eventFromJson(_decode(r['data']))];
  }

  @override
  Future<void> saveEvents(String matchId, List<MatchEvent> events) => _db.transaction((txn) async {
        await txn.delete('match_events', where: 'match_id = ?', whereArgs: [matchId]);
        final batch = txn.batch();
        for (var i = 0; i < events.length; i++) {
          batch.insert('match_events', {'match_id': matchId, 'seq': i, 'data': jsonEncode(eventToJson(events[i]))});
        }
        await batch.commit(noResult: true);
      });

  static Json _decode(Object? data) => jsonDecode(data! as String) as Json;
}
