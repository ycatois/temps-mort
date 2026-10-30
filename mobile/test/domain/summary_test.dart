import 'package:flutter_test/flutter_test.dart';
import 'package:temps_mort/demo/demo_team.dart';
import 'package:temps_mort/domain/domain.dart';

/// Sets courts (3 points) pour écrire des matchs complets en quelques lignes.
final rules = MatchRules.defaultFor(GameFormat.six).copyWith(setsToWin: 2, pointsPerSet: 3, pointsDecidingSet: 3);

MatchSession play(List<MatchEvent> events) {
  final session = MatchSession(demoTeam, rules: rules, events: [demoStartSet]);
  for (final e in events) {
    final rejection = session.record(e);
    expect(rejection, isNull, reason: '$e refusé : $rejection');
  }
  return session;
}

void nextSet(MatchSession s, {Side? firstServer}) => s.record(s.nextSetStart(firstServer: firstServer)!);

const attack = RallyAction.attaque;
const serveFault = RallyAction.serviceFaute;

void main() {
  test('match gagné 2–1 : scores par set, meilleures joueuses, fautes de service du set perdu', () {
    final s = play(const [
      Rally(Side.us, playerId: 'lucie', action: attack),
      Rally(Side.us, playerId: 'lucie', action: attack),
      Rally(Side.them, playerId: 'chloe', action: serveFault),
      Rally(Side.us, playerId: 'emma', action: RallyAction.contre),
    ]);
    nextSet(s);
    for (final e in const [
      Rally(Side.them, playerId: 'manon', action: serveFault),
      Rally(Side.them),
      Rally(Side.them, playerId: 'ines', action: serveFault),
    ]) {
      s.record(e);
    }
    nextSet(s, firstServer: Side.us);
    for (var i = 0; i < 3; i++) {
      s.record(const Rally(Side.us, playerId: 'lucie', action: attack));
    }

    final summary = summarize(demoTeam, s.state);
    expect(summary.finished, isTrue);
    expect(summary.winner, Side.us);
    expect(summary.setsWon, const Score(2, 1));
    expect(summary.sets, const [Score(3, 1), Score(0, 3), Score(3, 0)]);

    final scorer = summary.bestOf(BestCategory.scorer)!;
    expect(scorer.playerId, 'lucie');
    expect(scorer.value, 5);
    expect(summary.bestOf(BestCategory.block)!.playerId, 'emma');
    expect(summary.bestOf(BestCategory.serve), isNull, reason: 'aucun ace : pas de « meilleure au service »');
    expect(summary.bestOf(BestCategory.reception), isNull, reason: 'saisie simple : réception inconnue');

    final service = summary.takeaways.whereType<ServiceErrorsTakeaway>().single;
    expect(service.total, 3);
    expect(service.worstSet, 1);
    expect(service.inWorstSet, 2);
    expect(service.worstSetLost, isTrue);
    expect(summary.takeaways.whereType<RotationTakeaway>().where((t) => t.strongest), hasLength(1));
  });

  test('match en cours : le set entamé compte, pas de vainqueur', () {
    final s = play(const [Rally(Side.us, playerId: 'lucie', action: attack)]);
    final summary = summarize(demoTeam, s.state);
    expect(summary.finished, isFalse);
    expect(summary.winner, isNull);
    expect(summary.sets, const [Score(1, 0)]);
  });

  test('à égalité de points, la joueuse avec le moins de fautes passe devant', () {
    final s = play(const [
      Rally(Side.us, playerId: 'manon', action: attack),
      Rally(Side.them, playerId: 'manon', action: RallyAction.attaqueFaute),
      Rally(Side.us, playerId: 'lucie', action: attack),
    ]);
    expect(summarize(demoTeam, s.state).bestOf(BestCategory.scorer)!.playerId, 'lucie');
  });

  test('saisie complète : meilleure en réception avec au moins 3 réceptions, réception par rotation', () {
    final s = play(const [
      Rally(Side.them),
      Touch('chloe', TouchKind.reception3),
      Touch('chloe', TouchKind.reception3),
      Touch('lucie', TouchKind.reception2),
      Touch('lucie', TouchKind.reception3),
      Touch('lucie', TouchKind.reception2),
      Rally(Side.them, playerId: 'lucie', action: RallyAction.receptionFaute),
    ]);
    final summary = summarize(demoTeam, s.state);
    final best = summary.bestOf(BestCategory.reception)!;
    expect(best.playerId, 'lucie', reason: 'Chloé n\'a que 2 réceptions');
    expect(best.value, closeTo(7 / 4, 1e-9));

    final weak = summary.takeaways.whereType<RotationTakeaway>().singleWhere((t) => !t.strongest);
    expect(weak.score, const Score(0, 2));
    // 3 + 3 + 2 + 3 + 2 + 0 sur 6 réceptions
    expect(weak.receptionAverage, closeTo(13 / 6, 1e-9));
  });
}
