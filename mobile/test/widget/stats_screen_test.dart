import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temps_mort/demo/demo_team.dart';
import 'package:temps_mort/domain/domain.dart';
import 'package:temps_mort/ui/match/match_controller.dart';
import 'package:temps_mort/ui/match/match_screen.dart';
import 'package:temps_mort/ui/stats/stats_screen.dart';
import 'package:temps_mort/ui/theme/theme.dart';

/// Set 1 gagné 25–0 sur nos services, puis set 2 en cours : Lucie attaque, Chloé fait une faute de service.
MatchController playedMatch() {
  final c = MatchController(demoTeam, events: [demoStartSet]);
  for (var i = 0; i < 25; i++) {
    c.select('manon');
    c.action(RallyAction.ace);
  }
  c.startNextSet();
  c.opponentPoint();
  c.select('lucie');
  c.action(RallyAction.attaque);
  c.select('chloe');
  c.action(RallyAction.serviceFaute);
  c.opponentError();
  return c;
}

Future<void> pumpStats(WidgetTester tester, Size size, MatchController c) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: buildTheme(), home: StatsScreen(c: c)));
}

void main() {
  testWidgets('tablette : chiffres clés, filtre par set, rotations', (tester) async {
    final c = playedMatch();
    await pumpStats(tester, const Size(1194, 834), c);
    expect(find.text('Statistiques · 25–0 · 2–2'), findsOneWidget);

    // Set 2 affiché par défaut : 2 side-out gagnés sur 3 réceptions, 0 break sur 1 service
    expect(find.text('SIDE-OUT'), findsOneWidget);
    expect(find.text('67 %', findRichText: true), findsOneWidget);
    expect(find.text('0 %', findRichText: true), findsOneWidget);
    expect(find.textContaining('passez en saisie complète'), findsOneWidget, reason: 'pas de chiffre inventé');
    expect(find.textContaining('Aucune rotation déficitaire', findRichText: true), findsOneWidget);
    expect(find.text('1–1'), findsNWidgets(2), reason: 'R1 et R2');

    // Tout le match : 25 aces de Manon
    await tester.tap(find.text('Match'));
    await tester.pump();
    expect(find.text('25'), findsWidgets);
    expect(tester.takeException(), isNull);

    // Le tableau suit le match en direct
    await tester.tap(find.text('Set 2'));
    await tester.pump();
    c.select('emma');
    c.action(RallyAction.contre);
    await tester.pump();
    expect(find.text('Statistiques · 25–0 · 3–2'), findsOneWidget);
  });

  testWidgets('smartphone : onglets joueuses, rotations, équipe', (tester) async {
    await pumpStats(tester, const Size(390, 844), playedMatch());
    expect(tester.takeException(), isNull);
    expect(find.text('1 attaque'), findsOneWidget);
    await tester.tap(find.text('Rotations'));
    await tester.pumpAndSettle();
    expect(find.text('R1'), findsOneWidget);
    await tester.tap(find.text('Équipe'));
    await tester.pumpAndSettle();
    expect(find.text('Fautes adverses'), findsOneWidget);
    expect(find.text('Service'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('le bouton Statistiques de l\'écran de match ouvre E07', (tester) async {
    tester.view.physicalSize = const Size(1194, 834);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: buildTheme(), home: MatchScreen(team: demoTeam, events: [demoStartSet])));
    await tester.ensureVisible(find.text('Statistiques'));
    await tester.tap(find.text('Statistiques'));
    await tester.pumpAndSettle();
    expect(find.byType(StatsScreen), findsOneWidget);
  });

  testWidgets("saisie complète : du geste dans E05 à l'efficacité dans E07", (tester) async {
    tester.view.physicalSize = const Size(1194, 834);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    bool? savedMode;
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: MatchScreen(team: demoTeam, events: [demoStartSet], onFullInputChanged: (v) => savedMode = v),
    ));
    await tester.tap(find.text('Complète'));
    await tester.pump();
    expect(savedMode, isTrue);

    // [at] : rang du bouton quand le libellé existe pour plusieurs gestes (« En jeu » : service, attaque).
    Future<void> gesture(String player, String button, {int at = 0}) async {
      await tester.tap(find.text(player));
      await tester.pump();
      final target = find
          .ancestor(of: find.text(button), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton))
          .at(at);
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pump();
    }

    // Lucie réceptionne à 2, Emma attaque en jeu, Lucie marque en attaque
    await gesture('Lucie', '2');
    expect(find.text('0 – 0'), findsOneWidget, reason: 'un geste en jeu ne donne pas de point');
    await gesture('Emma', 'En jeu', at: 1);
    await gesture('Lucie', 'Point');
    expect(find.text('1 – 0'), findsOneWidget);

    await tester.ensureVisible(find.text('Statistiques'));
    await tester.tap(find.text('Statistiques'));
    await tester.pumpAndSettle();
    expect(find.text('EFFICACITÉ'), findsOneWidget);
    expect(find.text('+100 %'), findsOneWidget, reason: 'Lucie : 1 point sur 1 attaque');
    expect(find.text('0 %'), findsWidgets, reason: 'Emma : 0 point sur 1 attaque');
    expect(find.text('2,0', findRichText: true), findsWidgets, reason: "réception moyenne de Lucie et de l'équipe");
    expect(tester.takeException(), isNull);
  });
}
