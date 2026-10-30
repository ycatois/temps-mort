import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temps_mort/data/store.dart';
import 'package:temps_mort/domain/domain.dart';

import 'history_test.dart' show filledStore, match, pumpApp;

const tablet = Size(1194, 834);

Future<void> openTeam(WidgetTester tester) async {
  await tester.tap(find.text('M18 F').first);
  await tester.pumpAndSettle();
}

Future<void> confirm(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(TextButton, label).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('nouvelle équipe : saison en cours par défaut et couleur du maillot', (tester) async {
    final store = MemoryStore();
    await pumpApp(tester, tablet, store);
    await tester.tap(find.text('Créer une équipe'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Nom de l\'équipe'), 'M13 garçons');
    expect(find.text(seasonOf(DateTime.now())), findsOneWidget);
    await tester.ensureVisible(find.text('Rouge'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rouge'));
    await tester.pump();
    await tester.ensureVisible(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    final team = (await store.teams()).single;
    expect(team.color, TeamColor.red);
    expect(team.season, seasonOf(DateTime.now()));
    // L'en-tête de la fiche d'équipe fusionne sa sémantique : le libellé du maillot en fait partie.
    expect(find.bySemanticsLabel(RegExp('Maillot rouge')), findsOneWidget);
    expect(find.textContaining(team.season), findsOneWidget);
  });

  testWidgets('supprimer les données d\'une joueuse qui a joué : trace anonyme, matchs intacts', (tester) async {
    final store = await filledStore();
    await pumpApp(tester, tablet, store);
    await openTeam(tester);
    await tester.tap(find.text('Lucie'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Supprimer ses données'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer ses données'));
    await tester.pumpAndSettle();
    expect(find.textContaining('« Anonyme »'), findsOneWidget);
    await confirm(tester, 'Supprimer');

    final lucie = (await store.teams()).firstWhere((t) => t.id == 'demo').player('lucie')!;
    expect(lucie.firstName, 'Anonyme');
    expect(find.text('Lucie'), findsNothing);
    expect(find.text('Effectif (7)'), findsOneWidget);

    // Le match gagné se rejoue toujours : son résumé s'ouvre
    await tester.tap(find.text('Matchs (4)'));
    await tester.pumpAndSettle();
    expect(find.text('Gagné 1–0 · 2–0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('supprimer une joueuse qui n\'a jamais joué : plus aucune trace', (tester) async {
    final store = await filledStore();
    await pumpApp(tester, tablet, store);
    await openTeam(tester);
    await tester.tap(find.text('Zoé'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Supprimer ses données'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer ses données'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Anonyme'), findsNothing);
    await confirm(tester, 'Supprimer');
    expect((await store.teams()).firstWhere((t) => t.id == 'demo').player('zoe'), isNull);
  });

  testWidgets('historique par saison, quand il y en a plusieurs', (tester) async {
    final store = await filledStore();
    await store.saveMatch(match('lorient-2025', 'Lorient', DateTime(2026, 3, 7, 15)));
    await pumpApp(tester, tablet, store);
    await openTeam(tester);
    await tester.tap(find.text('Matchs (5)'));
    await tester.pumpAndSettle();
    final current = seasonOf(DateTime.now());
    expect(find.text('Saison $current'), findsOneWidget);
    expect(find.text('Lorient'), findsNothing);
    await tester.tap(find.text('Saison 2025-2026'));
    await tester.pumpAndSettle();
    expect(find.text('Lorient'), findsOneWidget);
    expect(find.text('Rennes'), findsNothing);
  });

  testWidgets('supprimer l\'équipe et toutes ses données', (tester) async {
    final store = await filledStore();
    await pumpApp(tester, tablet, store);
    await openTeam(tester);
    await tester.tap(find.byTooltip('Modifier l\'équipe'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Supprimer l\'équipe et toutes ses données'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer l\'équipe et toutes ses données'));
    await tester.pumpAndSettle();
    await confirm(tester, 'Supprimer définitivement');
    expect((await store.teams()).map((t) => t.id), ['seniors']);
    expect(await store.matches('demo'), isEmpty);
    expect(find.text('M18 F'), findsNothing, reason: 'retour à l\'accueil, équipe disparue');
    expect(find.text('Seniors F'), findsOneWidget);
  });
}
