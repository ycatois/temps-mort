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

final rules = MatchRules.defaultFor(GameFormat.six).copyWith(substitutionsPerSet: 1, pointsPerSet: 3);

Finder inPanel(String text) => find.descendant(of: find.byType(SubstitutionPanel), matching: find.text(text));

void main() {
  testWidgets('blessure, quota atteint : une case à cocher, l\'app fait le remplacement exceptionnel', (tester) async {
    tester.view.physicalSize = const Size(1194, 834);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final saved = <List<MatchEvent>>[];
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: MatchScreen(
        team: demoTeam,
        rules: rules,
        events: [demoStartSet, const Substitution('emma', 'zoe')],
        onEventsChanged: saved.add,
      ),
    ));
    await tester.ensureVisible(find.byIcon(Icons.swap_horiz).first);
    await tester.tap(find.byIcon(Icons.swap_horiz).first);
    await tester.pumpAndSettle();

    await tester.tap(inPanel('Lucie').first);
    await tester.pump();
    expect(inPanel(const NoSubstitutionLeft().message), findsOneWidget, reason: 'sans blessure : refusé');

    await tester.tap(inPanel('Sortie sur blessure'));
    await tester.pump();
    expect(inPanel('Remplacement exceptionnel, hors quota'), findsOneWidget);
    await tester.tap(inPanel('Emma'));
    await tester.pump();
    final confirm = inPanel('Emma entre, Lucie sort blessée · exceptionnel');
    await tester.scrollUntilVisible(confirm, 200,
        scrollable: find.descendant(of: find.byType(SubstitutionPanel), matching: find.byType(Scrollable)).first);
    await tester.ensureVisible(confirm);
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(saved.last.last, isA<InjurySubstitution>());
    expect(find.byType(SubstitutionPanel), findsNothing);

    // Fin du set : la même composition n'est plus proposée
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('+1 faute adverse'));
      await tester.pump();
    }
    expect(find.textContaining('Lucie, sortie sur blessure, ne peut plus jouer'), findsOneWidget);
    expect(find.text('Set 2 : même composition'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('composition du set suivant : la blessée n\'est ni sur le terrain ni au banc', (tester) async {
    await openComposition(
      tester,
      const Size(1194, 834),
      MemoryStore(),
      CompositionScreen(
        team: demoTeam,
        rules: rules,
        match: matchFor(demoTeam),
        setNumber: 2,
        initial: demoStartSet,
        initialServer: Side.them,
        serverLocked: true,
        unavailable: const {'lucie'},
      ),
    );
    expect(find.text('Lucie'), findsNothing);
    expect(find.text('Zoé'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Commencer le set 2')).onPressed, isNull,
        reason: 'une zone est vide');
    expect(tester.takeException(), isNull);
  });
}
