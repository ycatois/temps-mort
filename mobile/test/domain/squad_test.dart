import 'package:flutter_test/flutter_test.dart';
import 'package:temps_mort/data/codec.dart';
import 'package:temps_mort/demo/demo_team.dart';
import 'package:temps_mort/domain/domain.dart';

/// Démo : Jade (1) libero, Zoé (10) second libero.
final start = StartSet(Side.us, demoStartSet.lineup, liberoId: 'jade', secondLiberoId: 'zoe');

MatchSession session([List<MatchEvent> more = const []]) {
  final s = MatchSession(demoTeam, events: [start]);
  for (final e in more) {
    expect(s.record(e), isNull, reason: '$e');
  }
  return s;
}

Player player(int i, {PlayerGender gender = PlayerGender.f}) =>
    Player(id: 'p$i', firstName: 'P$i', number: i, gender: gender);

void main() {
  group('joueuses présentes (V1-PRE-03)', () {
    test('6x6 : 14 au plus, libero(s) compris', () {
      final team = Team(
        id: 't',
        name: 'Seniors',
        format: GameFormat.six,
        gender: TeamGender.feminine,
        category: AgeCategory.seniors,
        players: [for (var i = 1; i <= 16; i++) player(i)],
      );
      final ids = [for (final p in team.players) p.id];
      expect(validateSquad(team, ids.take(14)), isEmpty);
      expect(validateSquad(team, ids.take(15)), [const TooManyInSquad(14, 15)]);
      expect(validateSquad(team, ids.take(5)), [const NotEnoughInSquad(6, 5)]);
    });

    test('4x4 : pas de maximum ; mixte : assez de femmes présentes', () {
      final team = Team(
        id: 't',
        name: 'Loisir',
        format: GameFormat.four,
        gender: TeamGender.mixte,
        category: AgeCategory.loisir,
        minWomenOnCourt: 2,
        players: [
          for (var i = 1; i <= 20; i++) player(i, gender: i <= 2 ? PlayerGender.f : PlayerGender.m),
        ],
      );
      expect(validateSquad(team, [for (final p in team.players) p.id]), isEmpty);
      expect(validateSquad(team, ['p1', 'p3', 'p4', 'p5']), [const NotEnoughWomenInSquad(2, 1)]);
    });

    test('l\'équipe du match ne contient que les présentes', () {
      final squad = demoTeam.withSquad(['manon', 'lucie']);
      expect(squad.players.map((p) => p.id), ['manon', 'lucie']);
      expect(demoTeam.withSquad(null), same(demoTeam));
    });

    test('les joueuses apparues dans le match ne peuvent plus être retirées', () {
      final s = MatchSession(demoTeam, events: [demoStartSet]);
      for (final e in const [
        Rally(Side.us, playerId: 'lucie', action: RallyAction.attaque),
        Substitution('emma', 'zoe'),
      ]) {
        expect(s.record(e), isNull);
      }
      expect(playersInvolved(s.events), {...demoStartSet.lineup, 'jade', 'zoe'});
    });
  });

  group('second libero (V1-PRE-05)', () {
    test('déclaré au début du set, sur le banc', () {
      final s = session();
      expect(s.state.liberoId, 'jade');
      expect(s.state.secondLiberoId, 'zoe');
    });

    test('refusé s\'il est le premier, sans premier, ou sur le terrain', () {
      final engine = MatchEngine(demoTeam);
      final state = engine.initial();
      expect(engine.check(state, StartSet(Side.us, demoStartSet.lineup, liberoId: 'jade', secondLiberoId: 'jade')),
          const SecondLiberoInvalid());
      expect(engine.check(state, StartSet(Side.us, demoStartSet.lineup, secondLiberoId: 'zoe')), const SecondLiberoInvalid());
      final inLineup = engine.check(state, StartSet(Side.us, demoStartSet.lineup, liberoId: 'jade', secondLiberoId: 'lea'));
      expect(inLineup, isA<InvalidLineup>());
      expect((inLineup! as InvalidLineup).issues, contains(isA<LiberoInLineup>()));
      final fours = MatchEngine(demoTeam.withFormat(GameFormat.four));
      expect(fours.check(fours.initial(), StartSet(Side.us, demoStartSet.lineup.take(4).toList(), liberoId: 'jade', secondLiberoId: 'zoe')),
          const LiberoNotAllowed());
    });

    test('changement de libero au banc : le second devient celui qui entre', () {
      final s = session(const [LiberoSwap()]);
      expect(s.state.liberoId, 'zoe');
      expect(s.state.secondLiberoId, 'jade');
      expect(s.record(const LiberoIn('lucie')), isNull, reason: 'Lucie est en zone 5');
      expect(s.state.lineup, contains('zoe'));
    });

    test('changement de libero sur le terrain : le second prend sa place, sans compter de remplacement', () {
      final s = session(const [LiberoIn('lucie'), LiberoSwap()]);
      expect(s.state.lineup, contains('zoe'));
      expect(s.state.lineup, isNot(contains('jade')));
      expect(s.state.liberoReplacing, 'lucie');
      expect(s.state.substitutionsUsed, 0);
      // La sortie rend sa place à Lucie
      s.record(const LiberoOut());
      expect(s.state.lineup, contains('lucie'));
      expect(s.state.lineup, isNot(contains('zoe')));
    });

    test('sans second libero, pas de changement ; un libero ne passe jamais par un remplacement', () {
      final alone = MatchSession(demoTeam, events: [demoStartSet]);
      expect(alone.check(const LiberoSwap()), const NoSecondLibero());
      expect(session().check(const Substitution('emma', 'zoe')), const LiberoCannotBeSubstituted());
    });

    test('le set suivant reprend les deux liberos', () {
      final s = session();
      for (var i = 0; i < 25; i++) {
        s.record(const Rally(Side.us));
      }
      expect(s.nextSetStart()!.secondLiberoId, 'zoe');
    });

    test('aller-retour JSON', () {
      for (final e in <MatchEvent>[start, const LiberoSwap()]) {
        expect(eventToJson(eventFromJson(eventToJson(e))), eventToJson(e));
      }
      expect((eventFromJson(eventToJson(start)) as StartSet).secondLiberoId, 'zoe');
    });
  });
}
