import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temps_mort/data/match_record.dart';
import 'package:temps_mort/data/store.dart';
import 'package:temps_mort/demo/demo_team.dart';
import 'package:temps_mort/domain/domain.dart';
import 'package:temps_mort/ui/common/store_scope.dart';
import 'package:temps_mort/ui/composition/composition_screen.dart';
import 'package:temps_mort/ui/home/home_screen.dart';
import 'package:temps_mort/ui/match_setup/new_match_screen.dart';
import 'package:temps_mort/ui/team/team_screen.dart';
import 'package:temps_mort/ui/theme/theme.dart';

const tablet = Size(1194, 834);
const phone = Size(390, 844);

Future<void> pumpApp(WidgetTester tester, Size size, AppStore store, Widget home) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(StoreScope(store: store, child: MaterialApp(key: UniqueKey(), theme: buildTheme(), home: home)));
  await tester.pumpAndSettle();
}

Future<void> addPlayer(WidgetTester tester, String firstName, String number) async {
  await tester.tap(find.text('Ajouter une joueuse'));
  await tester.pumpAndSettle();
  await tester.enterText(find.widgetWithText(TextFormField, 'Prénom'), firstName);
  await tester.enterText(find.widgetWithText(TextFormField, 'Numéro'), number);
  await tester.tap(find.text('Ajouter à l\'effectif'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tablette : de l\'équipe vide au premier point, et le match est enregistré', (tester) async {
    final store = MemoryStore();
    await pumpApp(tester, tablet, store, const HomeScreen());

    // Équipe 2x2
    await tester.tap(find.text('Créer une équipe'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Nom de l\'équipe'), 'M11 filles');
    await tester.tap(find.text('2x2'));
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('M11 filles'), findsOneWidget);

    // Effectif : la fiche s'ouvre à côté de la liste
    await addPlayer(tester, 'Lina', '4');
    await addPlayer(tester, 'Maya', '4');
    expect(find.text('Le numéro 4 est déjà porté par Lina'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Numéro'), '8');
    await tester.tap(find.text('Ajouter à l\'effectif'));
    await tester.pumpAndSettle();
    expect(find.text('Effectif (2)'), findsOneWidget);
    expect((await store.teams()).single.activePlayers.map((p) => p.firstName), ['Lina', 'Maya']);

    // E03 puis composition
    await tester.tap(find.text('Nouveau match'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Adversaire'), 'Brest');
    await tester.tap(find.text('Composer le six de départ'));
    await tester.pumpAndSettle();
    // Présentes : tout l'effectif est coché par défaut
    expect(find.text('2 présentes'), findsOneWidget);
    await tester.tap(find.text('Continuer vers la composition'));
    await tester.pumpAndSettle();
    expect(find.byType(CompositionScreen), findsOneWidget);
    await tester.tap(find.text('Lina'));
    await tester.pump();
    await tester.tap(find.text('Sert en premier · à placer'));
    await tester.pump();
    await tester.tap(find.text('Maya'));
    await tester.pump();
    await tester.tap(find.text('Sert en second · à placer'));
    await tester.tap(find.text('Nous'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Commencer le set 1'));
    await tester.pumpAndSettle();

    // Match en direct
    expect(find.text('0 – 0'), findsOneWidget);
    await tester.tap(find.text('+1 adversaire'));
    await tester.pump();
    expect(find.text('0 – 1'), findsOneWidget);
    final match = (await store.matches((await store.teams()).single.id)).single;
    expect(match.opponent, 'Brest');
    expect(await store.events(match.id), hasLength(2));

    // On quitte : le match apparaît en cours, et se reprend au même score
    await tester.tap(find.byTooltip('Quitter le match (il est enregistré)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Matchs (1)'));
    await tester.pumpAndSettle();
    expect(find.text('En cours · sets 0–0 · set 1 à 0–1 · toucher pour reprendre'), findsOneWidget);
    await tester.tap(find.text('Brest'));
    await tester.pumpAndSettle();
    expect(find.text('0 – 1'), findsOneWidget);
  });

  testWidgets('smartphone : effectif, nouveau match et composition sans débordement', (tester) async {
    final store = MemoryStore();
    await pumpApp(tester, phone, store, const HomeScreen());
    await tester.tap(find.text('Créer une équipe'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Mixte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mixte'));
    await tester.pumpAndSettle();
    expect(find.text('Femmes au minimum sur le terrain'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'formulaire équipe');

    await store.saveTeam(demoTeam);
    await pumpApp(tester, phone, store, TeamScreen(team: demoTeam));
    expect(tester.takeException(), isNull);

    // La fiche joueuse s'ouvre en plein écran
    await tester.tap(find.text('Lucie'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archiver (quitte l\'équipe, reste dans l\'historique)'));
    await tester.pumpAndSettle();
    expect(find.text('Effectif (7)'), findsOneWidget);
    expect(find.text('Archivées (1)'), findsOneWidget);

    await tester.tap(find.text('Nouveau match'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(NewMatchScreen), findsOneWidget);

    final match = MatchRecord(
      id: 'm',
      teamId: demoTeam.id,
      opponent: 'Rennes',
      date: DateTime(2026, 11, 14, 15),
      format: GameFormat.six,
      rules: MatchRules.defaultFor(GameFormat.six),
    );
    await pumpApp(tester, phone, store, CompositionScreen(team: demoTeam, rules: match.rules, match: match));
    expect(tester.takeException(), isNull);
    expect(find.text('Zone 1 · à placer'), findsOneWidget);
  });
}
