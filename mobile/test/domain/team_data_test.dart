import 'package:flutter_test/flutter_test.dart';
import 'package:temps_mort/data/codec.dart';
import 'package:temps_mort/data/match_record.dart';
import 'package:temps_mort/data/store.dart';
import 'package:temps_mort/demo/demo_team.dart';
import 'package:temps_mort/domain/domain.dart';

void main() {
  test('la saison commence le 1er juillet', () {
    expect(seasonOf(DateTime(2026, 6, 30)), '2025-2026');
    expect(seasonOf(DateTime(2026, 7, 1)), '2026-2027');
    expect(seasonOf(DateTime(2027, 1, 15)), '2026-2027');
  });

  group('suppression des données d\'une joueuse (RGPD)', () {
    test('jamais jouée : elle disparaît complètement', () {
      final team = demoTeam.deletePlayer('zoe', keepTrace: false);
      expect(team.player('zoe'), isNull);
      expect(team.players, hasLength(demoTeam.players.length - 1));
    });

    test('déjà jouée : trace anonyme, ni prénom ni numéro, hors de l\'effectif', () {
      final team = demoTeam.deletePlayer('lucie', keepTrace: true);
      final trace = team.player('lucie')!;
      expect(trace.firstName, 'Anonyme');
      expect(trace.number, 0);
      expect(trace.deleted, isTrue);
      expect(trace.gender, PlayerGender.f, reason: 'nécessaire à la mixité des matchs rejoués');
      expect(team.activePlayers.map((p) => p.id), isNot(contains('lucie')));
      expect(team.archivedPlayers.map((p) => p.id), isNot(contains('lucie')));
    });

    test('ses matchs se rejouent à l\'identique, ses statistiques restent sans nom', () {
      final events = [demoStartSet, const Rally(Side.us, playerId: 'lucie', action: RallyAction.attaque)];
      final team = demoTeam.deletePlayer('lucie', keepTrace: true);
      final s = MatchSession(team, events: events);
      expect(s.state.score, const Score(1, 0));
      expect(s.stats().byPlayer['lucie']!.attackPoints, 1);
    });
  });

  test('saison, couleur et suppression survivent au JSON et au changement de format', () {
    final team = demoTeam
        .copyWith(season: '2025-2026', color: TeamColor.red)
        .deletePlayer('lucie', keepTrace: true);
    final back = teamFromJson(teamToJson(team));
    expect(back.season, '2025-2026');
    expect(back.color, TeamColor.red);
    expect(back.player('lucie')!.deleted, isTrue);
    expect(teamToJson(back), teamToJson(team));
    final four = team.withFormat(GameFormat.four);
    expect(four.season, '2025-2026');
    expect(four.color, TeamColor.red);
    expect(team.copyWith(color: null).color, isNull, reason: 'retirer la couleur');
  });

  test('supprimer une équipe efface tout ce qui la concerne, pas les autres', () async {
    final store = MemoryStore();
    final other = demoTeam.copyWith(name: 'Autre');
    await store.saveTeam(demoTeam);
    MatchRecord match(String id, String teamId) => MatchRecord(
        id: id, teamId: teamId, opponent: 'X', date: DateTime(2026, 10, 1), format: GameFormat.six, rules: MatchRules.defaultFor(GameFormat.six));
    await store.saveTeam(Team(
      id: 'autre',
      name: other.name,
      format: GameFormat.six,
      gender: TeamGender.feminine,
      category: AgeCategory.seniors,
      players: const [],
    ));
    await store.saveMatch(match('a', 'demo'));
    await store.saveEvents('a', [demoStartSet]);
    await store.saveMatch(match('b', 'autre'));
    await store.deleteTeam('demo');
    expect((await store.teams()).map((t) => t.id), ['autre']);
    expect(await store.matches('demo'), isEmpty);
    expect(await store.events('a'), isEmpty);
    expect(await store.matches('autre'), hasLength(1));
  });
}
