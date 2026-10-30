import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temps_mort/demo/demo_team.dart';
import 'package:temps_mort/domain/domain.dart';
import 'package:temps_mort/ui/match/match_screen.dart';
import 'package:temps_mort/ui/match/substitution_panel.dart';
import 'package:temps_mort/ui/theme/theme.dart';

Future<List<List<MatchEvent>>> pumpMatch(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final saved = <List<MatchEvent>>[];
  // Équipe des maquettes : nous servons, Manon en zone 1, Jade libero, Zoé sur le banc.
  await tester.pumpWidget(MaterialApp(
    theme: buildTheme(),
    home: MatchScreen(team: demoTeam, events: [demoStartSet], onEventsChanged: saved.add),
  ));
  return saved;
}

Finder inPanel(String text) => find.descendant(of: find.byType(SubstitutionPanel), matching: find.text(text));

Future<void> openPanel(WidgetTester tester) async {
  await tester.ensureVisible(find.byIcon(Icons.swap_horiz));
  await tester.tap(find.byIcon(Icons.swap_horiz));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tablette : remplacement, retour à la place d\'origine et libero', (tester) async {
    final saved = await pumpMatch(tester, const Size(1194, 834));
    expect(find.text('Remplacement 0/6 · libero'), findsOneWidget);

    // Emma sort, Zoé entre
    await openPanel(tester);
    expect(find.text('Remplacements : 0 / 6 dans ce set'), findsOneWidget);
    await tester.tap(inPanel('Emma'));
    await tester.pump();
    await tester.tap(inPanel('Zoé'));
    await tester.pump();
    await tester.tap(find.text('Zoé entre, Emma sort'));
    await tester.pumpAndSettle();
    expect(find.byType(SubstitutionPanel), findsNothing);
    expect(find.text('Remplacement 1/6 · libero'), findsOneWidget);
    expect(saved.last.last, isA<Substitution>());

    // Lucie ne peut pas être remplacée par Emma : Emma ne revient qu'à la place de Zoé
    await openPanel(tester);
    await tester.tap(inPanel('Lucie').first);
    await tester.pump();
    expect(inPanel("Une titulaire ne revient qu'à sa place d'origine, à la place de sa remplaçante."), findsOneWidget);
    await tester.tap(inPanel('Zoé'));
    await tester.pump();
    expect(inPanel("Revient à sa place d'origine"), findsOneWidget);
    await tester.tap(inPanel('Emma'));
    await tester.pump();
    await tester.tap(find.text('Emma entre, Zoé sort'));
    await tester.pumpAndSettle();
    expect(find.text('Remplacement 2/6 · libero'), findsOneWidget);

    // Libero : pas à la place de la serveuse, oui en zone 5
    await openPanel(tester);
    await tester.ensureVisible(inPanel('Manon').last);
    expect(inPanel('Le libero ne peut pas servir.'), findsOneWidget);
    await tester.ensureVisible(inPanel('Lucie').last);
    await tester.pumpAndSettle();
    await tester.tap(inPanel('Lucie').last);
    await tester.pumpAndSettle();
    expect(find.text('Jade · L'), findsOneWidget);
    await openPanel(tester);
    await tester.ensureVisible(find.text('Jade sort, Lucie revient'));
    await tester.tap(find.text('Jade sort, Lucie revient'));
    await tester.pumpAndSettle();
    expect(find.text('Jade · L'), findsNothing);

    // Tout s'annule pas à pas
    await tester.tap(find.text('Annuler la dernière saisie'));
    await tester.pump();
    expect(find.text('Jade · L'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('smartphone : la feuille du bas s\'ouvre sans débordement', (tester) async {
    await pumpMatch(tester, const Size(390, 844));
    await openPanel(tester);
    expect(find.byType(SubstitutionPanel), findsOneWidget);
    await tester.tap(inPanel('Emma'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Fermer'));
    await tester.pumpAndSettle();
    expect(find.byType(SubstitutionPanel), findsNothing);
  });

  testWidgets('2x2 : ni remplacement ni libero, pas de bouton', (tester) async {
    final duo = demoTeam.withFormat(GameFormat.two);
    tester.view.physicalSize = const Size(1194, 834);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: MatchScreen(team: duo, events: [StartSet(Side.us, const ['manon', 'lucie'])]),
    ));
    expect(find.byIcon(Icons.swap_horiz), findsNothing);
  });
}
