import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:temps_mort/data/codec.dart';
import 'package:temps_mort/data/match_record.dart';
import 'package:temps_mort/data/sqlite_store.dart';
import 'package:temps_mort/demo/demo_team.dart';
import 'package:temps_mort/domain/domain.dart';

final team = Team(
  id: 't1',
  name: 'Loisir mixte',
  format: GameFormat.four,
  gender: TeamGender.mixte,
  category: AgeCategory.loisir,
  minWomenOnCourt: 1,
  players: const [
    Player(id: 'a', firstName: 'Anna', number: 4, gender: PlayerGender.f, role: Role.passeur),
    Player(id: 'b', firstName: 'Basile', number: 8, gender: PlayerGender.m, archived: true),
  ],
);

final match = MatchRecord(
  id: 'm1',
  teamId: 't1',
  opponent: 'Rennes',
  date: DateTime(2026, 11, 14, 15),
  venue: 'Gymnase Colette',
  home: false,
  competition: 'Coupe loisir',
  format: GameFormat.four,
  rules: MatchRules.defaultFor(GameFormat.four).copyWith(pointsPerSet: 21),
);

final events = <MatchEvent>[
  StartSet(Side.them, const ['manon', 'chloe', 'emma', 'ines', 'lucie', 'lea'],
      liberoId: 'jade', captainId: 'emma', system: GameSystem.s51),
  const Rally(Side.us, playerId: 'lucie', action: RallyAction.attaque),
  const Rally(Side.them),
  const TimeoutTaken(Side.us),
  const Substitution('emma', 'zoe'),
  const LiberoIn('manon'),
  const LiberoOut(),
  const Touch('lucie', TouchKind.reception2),
  const Rally(Side.them, playerId: 'lea', action: RallyAction.passeFaute),
];

void expectSameTeam(Team actual, Team expected) {
  expect(teamToJson(actual), teamToJson(expected));
}

void main() {
  test('équipe, match et événements survivent à un aller-retour JSON', () {
    expectSameTeam(teamFromJson(teamToJson(team)), team);
    expect(teamFromJson(teamToJson(team)).player('b')!.archived, isTrue);
    expect(matchToJson(matchFromJson(matchToJson(match))), matchToJson(match));
    final back = [for (final e in events) eventFromJson(eventToJson(e))];
    expect([for (final e in back) eventToJson(e)], [for (final e in events) eventToJson(e)]);
  });

  test('un match rechargé depuis SQLite reprend exactement là où il était', () async {
    sqfliteFfiInit();
    final store = await SqliteStore.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
    addTearDown(store.close);

    await store.saveTeam(demoTeam);
    await store.saveTeam(team);
    expect((await store.teams()).map((t) => t.id), ['demo', 't1']);

    await store.saveMatch(match);
    await store.saveMatch(MatchRecord(
      id: 'm0',
      teamId: 't1',
      opponent: 'Brest',
      date: DateTime(2026, 10, 1),
      format: GameFormat.four,
      rules: MatchRules.defaultFor(GameFormat.four),
    ));
    expect((await store.matches('t1')).map((m) => m.id), ['m1', 'm0']);

    final session = MatchSession(demoTeam, events: [demoStartSet]);
    session.record(const Rally(Side.us, playerId: 'lucie', action: RallyAction.attaque));
    session.record(const Rally(Side.them));
    await store.saveEvents('m1', session.events);
    session.undo();
    await store.saveEvents('m1', session.events);

    final reloaded = MatchSession(demoTeam, events: await store.events('m1'));
    expect(reloaded.state.score, const Score(1, 0));
    expect(reloaded.events.length, 2);
    expect((reloaded.events.first as StartSet).liberoId, 'jade');

    // Composition type : une par équipe et par format
    expect(await store.lineupTemplate('demo', GameFormat.six), isNull);
    await store.saveLineupTemplate(LineupTemplate(
        teamId: 'demo', format: GameFormat.six, lineup: demoStartSet.lineup, liberoId: 'jade', captainId: 'emma', system: GameSystem.s51));
    final template = await store.lineupTemplate('demo', GameFormat.six);
    expect(template!.lineup, demoStartSet.lineup);
    expect(template.captainId, 'emma');
    expect(template.system, GameSystem.s51);
    expect(await store.lineupTemplate('demo', GameFormat.four), isNull);
  });
}
