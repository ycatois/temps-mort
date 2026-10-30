import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temps_mort/data/store.dart';
import 'package:temps_mort/demo/demo_team.dart';
import 'package:temps_mort/domain/domain.dart';
import 'package:temps_mort/ui/composition/composition_screen.dart';
import 'package:temps_mort/ui/match/match_screen.dart';
import 'package:temps_mort/ui/match/substitution_panel.dart';
import 'package:temps_mort/ui/theme/theme.dart';

import 'composition_screen_test.dart' show matchFor, openComposition;
import 'history_test.dart' show filledStore, pumpApp;

bool enabled(WidgetTester tester, String label) =>
    tester.widget<FilledButton>(find.ancestor(of: find.text(label), matching: find.byType(FilledButton))).onPressed != null;

void main() {
  testWidgets('présentes avant la composition : décocher les absentes, minimum pour composer', (tester) async {
    final store = await filledStore();
    await pumpApp(tester, const Size(1194, 834), store);
    await tester.tap(find.text('M18 F contre Nantes'));
    await tester.pumpAndSettle();

    expect(find.text('Présentes · Nantes'), findsOneWidget);
    expect(find.text('8 présentes sur 14 au plus'), findsOneWidget);
    await tester.tap(find.text('Zoé'));
    await tester.tap(find.text('Lucie'));
    await tester.pump();
    expect(find.text('6 présentes sur 14 au plus'), findsOneWidget);

    // Une de moins : on ne peut plus composer un six
    await tester.tap(find.text('Léa'));
    await tester.pump();
    expect(find.textContaining('Il faut au moins 6 joueuses'), findsOneWidget);
    expect(enabled(tester, 'Continuer vers la composition'), isFalse);
    await tester.tap(find.text('Léa'));
    await tester.pump();
    await tester.tap(find.text('Continuer vers la composition'));
    await tester.pumpAndSettle();

    expect(find.byType(CompositionScreen), findsOneWidget);
    expect(find.text('Banc · 6'), findsOneWidget);
    expect(find.text('Zoé'), findsNothing);
    expect(find.text('Lucie'), findsNothing);
    final saved = (await store.matches('demo')).firstWhere((m) => m.id == 'nantes');
    expect(saved.present, unorderedEquals(['jade', 'ines', 'manon', 'chloe', 'emma', 'lea']));
  });

  testWidgets('historique : les joueuses qui ont joué restent cochées', (tester) async {
    final store = await filledStore();
    await pumpApp(tester, const Size(1194, 834), store);
    await tester.tap(find.text('M18 F').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Matchs (4)'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Actions du match contre Rennes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Joueuses présentes'));
    await tester.pumpAndSettle();

    expect(find.text('A déjà joué ce match'), findsNWidgets(7), reason: 'le six de départ et la libero');
    await tester.tap(find.text('Tout décocher'));
    await tester.pump();
    expect(find.text('7 présentes sur 14 au plus'), findsOneWidget);
    await tester.tap(find.text('Enregistrer les présentes'));
    await tester.pumpAndSettle();
    expect((await store.matches('demo')).firstWhere((m) => m.id == 'rennes').present, hasLength(7));
  });

  testWidgets('composition : second libero, sur le banc, choisi après le premier', (tester) async {
    final result = await openComposition(
      tester,
      const Size(1194, 834),
      MemoryStore(),
      CompositionScreen(
        team: demoTeam,
        rules: MatchRules.defaultFor(GameFormat.six),
        match: matchFor(demoTeam),
        initial: demoStartSet,
        initialServer: Side.us,
      ),
    );
    expect(find.text('SECOND LIBERO'), findsOneWidget);
    await tester.tap(find.text('Aucune'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('#10 Zoé').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Commencer le set 1'));
    await tester.pumpAndSettle();
    final start = (await result)!;
    expect(start.liberoId, 'jade');
    expect(start.secondLiberoId, 'zoe');
  });

  testWidgets('match : changement de libero depuis le panneau de remplacement', (tester) async {
    tester.view.physicalSize = const Size(1194, 834);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final saved = <List<MatchEvent>>[];
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: MatchScreen(
        team: demoTeam,
        events: [StartSet(Side.them, demoStartSet.lineup, liberoId: 'jade', secondLiberoId: 'zoe')],
        onEventsChanged: saved.add,
      ),
    ));
    await tester.ensureVisible(find.byIcon(Icons.swap_horiz).first);
    await tester.tap(find.byIcon(Icons.swap_horiz).first);
    await tester.pumpAndSettle();
    final swap = find.descendant(
        of: find.byType(SubstitutionPanel), matching: find.text('Changer de libero : Zoé au lieu de Jade'));
    await tester.scrollUntilVisible(swap, 200,
        scrollable: find.descendant(of: find.byType(SubstitutionPanel), matching: find.byType(Scrollable)).first);
    await tester.ensureVisible(swap);
    await tester.pumpAndSettle();
    await tester.tap(swap, warnIfMissed: true);
    await tester.pumpAndSettle();
    expect(saved.last.last, isA<LiberoSwap>());
    expect(find.byType(SubstitutionPanel), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
