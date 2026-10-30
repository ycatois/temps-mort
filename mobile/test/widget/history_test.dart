import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:temps_mort/data/match_record.dart';
import 'package:temps_mort/data/sqlite_store.dart';
import 'package:temps_mort/data/store.dart';
import 'package:temps_mort/demo/demo_team.dart';
import 'package:temps_mort/domain/domain.dart';
import 'package:temps_mort/main.dart';

final rules = MatchRules.defaultFor(GameFormat.six).copyWith(setsToWin: 1, pointsPerSet: 2, pointsDecidingSet: 2);

MatchRecord match(String id, String opponent, DateTime date, {String teamId = 'demo'}) =>
    MatchRecord(id: id, teamId: teamId, opponent: opponent, date: date, format: GameFormat.six, rules: rules);

final other = Team(
  id: 'seniors',
  name: 'Seniors F',
  format: GameFormat.six,
  gender: TeamGender.feminine,
  category: AgeCategory.seniors,
  players: const [],
);

/// Démo : un match terminé (Brest, gagné 2–0), un en cours (Rennes, 1–0), deux à venir (Nantes puis Vannes).
/// Seniors : un match à venir (Lorient), entre les deux.
Future<MemoryStore> filledStore() async {
  final store = MemoryStore();
  await store.saveTeam(demoTeam);
  await store.saveTeam(other);
  await store.saveMatch(match('brest', 'Brest', DateTime(2026, 10, 3, 15)));
  await store.saveEvents('brest', [
    demoStartSet,
    const Rally(Side.us, playerId: 'lucie', action: RallyAction.attaque),
    const Rally(Side.us, playerId: 'lucie', action: RallyAction.attaque),
  ]);
  await store.saveMatch(match('rennes', 'Rennes', DateTime(2026, 10, 30, 15)));
  await store.saveEvents('rennes', [demoStartSet, const Rally(Side.us)]);
  await store.saveMatch(match('vannes', 'Vannes', DateTime(2026, 12, 12, 15)));
  await store.saveMatch(match('nantes', 'Nantes', DateTime(2026, 11, 14, 15)));
  await store.saveMatch(match('lorient', 'Lorient', DateTime(2026, 11, 21, 15), teamId: 'seniors'));
  return store;
}

Future<void> pumpApp(WidgetTester tester, Size size, AppStore store) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(TempsMortApp(store: store));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('accueil tablette : match en cours à reprendre et prochains matchs de toutes les équipes', (tester) async {
    final store = await filledStore();
    await pumpApp(tester, const Size(1194, 834), store);

    expect(find.text('MATCH EN COURS'), findsOneWidget);
    expect(find.text('M18 F contre Rennes'), findsOneWidget);
    expect(find.text('PROCHAINS MATCHS'), findsOneWidget);
    final nantes = tester.getTopLeft(find.text('M18 F contre Nantes')).dy;
    final lorient = tester.getTopLeft(find.text('Seniors F contre Lorient')).dy;
    final vannes = tester.getTopLeft(find.text('M18 F contre Vannes')).dy;
    expect(nantes < lorient && lorient < vannes, isTrue, reason: 'le plus proche d\'abord');
    expect(find.textContaining('Brest'), findsNothing, reason: 'les matchs terminés sont dans l\'historique');
    expect(find.textContaining('4 matchs'), findsOneWidget);

    // Reprendre le match en cours au même score
    await tester.tap(find.text('M18 F contre Rennes'));
    await tester.pumpAndSettle();
    expect(find.text('1 – 0'), findsOneWidget);
    await tester.tap(find.byTooltip('Quitter le match (il est enregistré)'));
    await tester.pumpAndSettle();
    expect(find.text('MATCH EN COURS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('historique : sections, modifier un match commencé, supprimer avec confirmation', (tester) async {
    final store = await filledStore();
    await pumpApp(tester, const Size(1194, 834), store);
    await tester.tap(find.text('M18 F').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Matchs (4)'));
    await tester.pumpAndSettle();

    expect(find.text('EN COURS (1)'), findsOneWidget);
    expect(find.text('À VENIR (2)'), findsOneWidget);
    expect(find.text('TERMINÉS (1)'), findsOneWidget);
    expect(find.text('Gagné 1–0 · 2–0'), findsOneWidget);

    // Modifier : l'adversaire change, les règles d'un match commencé sont verrouillées
    await tester.tap(find.byTooltip('Actions du match contre Rennes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modifier les informations'));
    await tester.pumpAndSettle();
    expect(find.text('Modifier le match · M18 F'), findsOneWidget);
    expect(find.text('Le match a commencé : format et règles ne se modifient plus.'), findsOneWidget);
    expect(find.text('Points par set'), findsNothing);
    await tester.enterText(find.widgetWithText(TextFormField, 'Adversaire'), 'Rennes VB');
    await tester.enterText(find.widgetWithText(TextFormField, 'Lieu (facultatif)'), 'Salle Colette');
    await tester.tap(find.text('Enregistrer les modifications'));
    await tester.pumpAndSettle();
    final edited = (await store.matches('demo')).firstWhere((m) => m.id == 'rennes');
    expect(edited.opponent, 'Rennes VB');
    expect(edited.venue, 'Salle Colette');
    expect(edited.rules.pointsPerSet, 2);
    expect(await store.events('rennes'), hasLength(2), reason: 'le match continue là où il en était');
    expect(find.text('Rennes VB'), findsOneWidget);

    // Résumé d'un match terminé, depuis le menu
    await tester.tap(find.byTooltip('Actions du match contre Brest'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voir le résumé'));
    await tester.pumpAndSettle();
    expect(find.text('Victoire'), findsOneWidget);
    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();

    // Supprimer : annuler ne change rien, confirmer efface le match et ses événements
    await tester.tap(find.byTooltip('Actions du match contre Brest'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer le match'));
    await tester.pumpAndSettle();
    expect(find.textContaining('toutes ses statistiques'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Brest'), findsOneWidget);
    await tester.tap(find.byTooltip('Actions du match contre Brest'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer le match'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Supprimer'));
    await tester.pumpAndSettle();
    expect(find.text('Brest'), findsNothing);
    expect(find.text('TERMINÉS (1)'), findsNothing);
    expect(await store.events('brest'), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('modifier un match à venir : format et règles restent modifiables', (tester) async {
    final store = await filledStore();
    await pumpApp(tester, const Size(1194, 834), store);
    await tester.tap(find.text('M18 F').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Matchs (4)'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Actions du match contre Nantes'));
    await tester.pumpAndSettle();
    expect(find.text('Voir le résumé'), findsNothing, reason: 'pas de résumé avant le premier point');
    await tester.tap(find.text('Modifier les informations'));
    await tester.pumpAndSettle();
    expect(find.text('Points par set'), findsOneWidget);
    await tester.tap(find.byTooltip('Points par set : plus'));
    await tester.tap(find.text('Enregistrer les modifications'));
    await tester.pumpAndSettle();
    expect((await store.matches('demo')).firstWhere((m) => m.id == 'nantes').rules.pointsPerSet, 3);
  });

  testWidgets('accueil smartphone : en une colonne, sans débordement', (tester) async {
    await pumpApp(tester, const Size(390, 844), await filledStore());
    expect(find.text('MATCH EN COURS'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('MES ÉQUIPES'), 300);
    expect(tester.takeException(), isNull);
  });

  test('SQLite : supprimer un match efface ses événements, pas ceux des autres', () async {
    sqfliteFfiInit();
    final store = await SqliteStore.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
    addTearDown(store.close);
    await store.saveMatch(match('a', 'Brest', DateTime(2026, 10, 3)));
    await store.saveMatch(match('b', 'Rennes', DateTime(2026, 10, 4)));
    await store.saveEvents('a', [demoStartSet]);
    await store.saveEvents('b', [demoStartSet]);
    await store.deleteMatch('a');
    expect((await store.matches('demo')).map((m) => m.id), ['b']);
    expect(await store.events('a'), isEmpty);
    expect(await store.events('b'), hasLength(1));
  });
}
