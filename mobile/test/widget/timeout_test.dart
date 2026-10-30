import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temps_mort/data/match_record.dart';
import 'package:temps_mort/data/store.dart';
import 'package:temps_mort/demo/demo_team.dart';
import 'package:temps_mort/domain/domain.dart';
import 'package:temps_mort/main.dart';
import 'package:temps_mort/ui/match/match_screen.dart';
import 'package:temps_mort/ui/theme/theme.dart';

/// Deux échanges sur notre service : un gagné, un perdu sur une faute de service de Manon.
final events = <MatchEvent>[
  demoStartSet,
  const Rally(Side.us, playerId: 'lucie', action: RallyAction.attaque),
  const Rally(Side.them, playerId: 'manon', action: RallyAction.serviceFaute),
];

Future<void> pumpMatch(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: buildTheme(), home: MatchScreen(team: demoTeam, events: events)));
}

void main() {
  testWidgets('tablette : le temps mort ouvre le tableau avec le chrono et les chiffres du set', (tester) async {
    await pumpMatch(tester, const Size(1194, 834));
    await tester.tap(find.text('Temps mort 0/2'));
    await tester.pumpAndSettle();

    expect(find.text('Temps mort · 0:30'), findsOneWidget);
    expect(find.text('1 – 1'), findsOneWidget);
    expect(find.text('Ce set'), findsOneWidget);
    expect(find.text('50 %'), findsOneWidget, reason: 'break : 1 échange gagné sur 2 au service');
    expect(find.text('—'), findsOneWidget, reason: 'aucune réception : pas de side-out inventé');
    expect(find.bySemanticsLabel('Fautes : 1 directes'), findsOneWidget);
    expect(find.text('Manon'), findsOneWidget, reason: 'le tableau tactique est là, sur la rotation');

    await tester.pump(const Duration(seconds: 6));
    expect(find.text('Temps mort · 0:24'), findsOneWidget);
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('Temps mort · reprise'), findsOneWidget);

    // Retour au match : le temps mort est compté
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Temps mort 1/2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('smartphone : chrono compact et chiffres sur une ligne', (tester) async {
    await pumpMatch(tester, const Size(390, 844));
    await tester.tap(find.text('Temps mort 0/2'));
    await tester.pumpAndSettle();
    expect(find.text('TM 0:30'), findsOneWidget);
    expect(find.text('SIDE-OUT'), findsOneWidget);
    await tester.pump(const Duration(seconds: 31));
    expect(find.text('Reprise'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('accueil : réinitialiser la démonstration efface ses matchs, pas les autres équipes', (tester) async {
    tester.view.physicalSize = const Size(1194, 834);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = MemoryStore();
    final other = Team(
        id: 'autre', name: 'Seniors', format: GameFormat.six, gender: TeamGender.feminine, category: AgeCategory.seniors, players: const []);
    MatchRecord match(String id, String teamId) => MatchRecord(
        id: id, teamId: teamId, opponent: 'Brest', date: DateTime(2026, 10, 30), format: GameFormat.six, rules: MatchRules.defaultFor(GameFormat.six));
    await store.saveTeam(demoTeam.copyWith(name: 'Démo renommée'));
    await store.saveTeam(other);
    await store.saveMatch(match('m1', 'demo'));
    await store.saveEvents('m1', [demoStartSet, const TimeoutTaken(Side.us), const TimeoutTaken(Side.us)]);
    await store.saveMatch(match('m2', 'autre'));
    await store.saveLineupTemplate(LineupTemplate(teamId: 'demo', format: GameFormat.six, lineup: demoStartSet.lineup));

    await tester.pumpWidget(TempsMortApp(store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Réinitialiser la démonstration'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Réinitialiser'));
    await tester.pumpAndSettle();

    expect(await store.matches('demo'), isEmpty);
    expect(await store.events('m1'), isEmpty);
    expect(await store.lineupTemplate('demo', GameFormat.six), isNull);
    expect((await store.matches('autre')).single.id, 'm2');
    expect(find.text('M18 F'), findsOneWidget, reason: 'effectif et nom d\'origine');
    expect(find.text('Seniors'), findsOneWidget);
  });
}
