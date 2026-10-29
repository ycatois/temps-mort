import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temps_mort/data/match_record.dart';
import 'package:temps_mort/data/store.dart';
import 'package:temps_mort/demo/demo_team.dart';
import 'package:temps_mort/domain/domain.dart';
import 'package:temps_mort/ui/common/store_scope.dart';
import 'package:temps_mort/ui/composition/composition_draft.dart';
import 'package:temps_mort/ui/composition/composition_screen.dart';
import 'package:temps_mort/ui/theme/theme.dart';

MatchRecord matchFor(Team team) => MatchRecord(
      id: 'm',
      teamId: team.id,
      opponent: 'AS Adversaire',
      date: DateTime(2026, 11, 15, 15),
      format: team.format,
      rules: MatchRules.defaultFor(team.format),
    );

final mixed4 = Team(
  id: 'mx',
  name: 'Loisir mixte',
  format: GameFormat.four,
  gender: TeamGender.mixte,
  category: AgeCategory.loisir,
  players: const [
    Player(id: 'lucie', firstName: 'Lucie', number: 7, gender: PlayerGender.f),
    Player(id: 'hugo', firstName: 'Hugo', number: 10, gender: PlayerGender.m),
    Player(id: 'lucas', firstName: 'Lucas', number: 4, gender: PlayerGender.m),
    Player(id: 'emma', firstName: 'Emma', number: 12, gender: PlayerGender.f),
    Player(id: 'tom', firstName: 'Tom', number: 8, gender: PlayerGender.m),
  ],
);

/// Ouvre E04 au-dessus d'un écran vide et renvoie ce que l'écran rendra en se fermant.
Future<Future<StartSet?>> openComposition(WidgetTester tester, Size size, AppStore store, Widget screen) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late Future<StartSet?> result;
  await tester.pumpWidget(StoreScope(
    store: store,
    child: MaterialApp(
      theme: buildTheme(),
      home: Builder(builder: (context) {
        return Scaffold(
          body: TextButton(
            onPressed: () => result = Navigator.of(context).push<StartSet>(MaterialPageRoute(builder: (_) => screen)),
            child: const Text('ouvrir'),
          ),
        );
      }),
    ),
  ));
  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
  return result;
}

/// Touche une joueuse puis une zone, en faisant défiler l'écran si besoin (smartphone).
Future<void> tapPlace(WidgetTester tester, String player, String zone) async {
  await tapVisible(tester, player);
  await tapVisible(tester, zone);
}

Future<void> tapVisible(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pump();
}

void main() {
  group('Placement', () {
    test('venue du banc, l\'occupante retourne au banc ; venue d\'une zone, on échange', () {
      final d = CompositionDraft(3);
      d.place('a', 0);
      d.place('b', 1);
      d.place('c', 0);
      expect(d.slots, ['c', 'b', null]);
      d.place('b', 0);
      expect(d.slots, ['b', 'c', null]);
      d.remove('c');
      expect(d.emptySlots, [1, 2]);
      d.load(['x', 'b', 'y'], (id) => id != 'y');
      expect(d.slots, ['x', 'b', null]);
    });
  });

  testWidgets('tablette 6x6 : glisser, toucher, capitaine, compo type et alerte de système', (tester) async {
    final store = MemoryStore();
    final result = await openComposition(
      tester,
      const Size(1194, 834),
      store,
      CompositionScreen(team: demoTeam, rules: MatchRules.defaultFor(GameFormat.six), match: matchFor(demoTeam)),
    );
    expect(find.text('Composition du set 1 · contre AS Adversaire'), findsOneWidget);
    expect(find.text('Glissez les joueuses du banc sur les zones, ou touchez une joueuse puis une zone.'), findsOneWidget);

    // Un vrai glisser-déposer du banc vers la zone 1
    await tester.dragFrom(tester.getCenter(find.text('Manon')), tester.getCenter(find.text('Zone 1 · à placer')) - tester.getCenter(find.text('Manon')));
    await tester.pumpAndSettle();
    expect(find.text('Zone 1 · Polyvalente'), findsOneWidget);

    await tapPlace(tester, 'Chloé', 'Zone 2 · à placer');
    await tapPlace(tester, 'Emma', 'Zone 3 · à placer');
    await tapPlace(tester, 'Inès', 'Zone 4 · à placer');
    await tapPlace(tester, 'Lucie', 'Zone 5 · à placer');
    expect(find.textContaining('Zone 6 vide'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Commencer le set 1')).onPressed, isNull);
    await tapPlace(tester, 'Léa', 'Zone 6 · à placer');

    // Libero et capitaine
    await tester.tap(find.text('Aucune'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('#1 Jade').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Non désignée'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('#12 Emma').last);
    await tester.pumpAndSettle();
    expect(find.text('Emma (C)'), findsOneWidget);

    // 4-2 avec une seule passeuse : alerte, mais le set peut commencer
    await tester.tap(find.text('4-2'));
    await tester.pump();
    expect(find.textContaining('deux passeuses sont attendues'), findsOneWidget);
    await tester.tap(find.text('5-1'));
    await tester.pump();
    expect(find.textContaining('passeuse'), findsNothing);

    await tester.tap(find.text('Enregistrer comme compo type'));
    await tester.pump();
    expect((await store.lineupTemplate('demo', GameFormat.six))!.captainId, 'emma');

    await tester.tap(find.text('Nous'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Commencer le set 1'));
    await tester.pumpAndSettle();
    final start = (await result)!;
    expect(start.lineup, ['manon', 'chloe', 'emma', 'ines', 'lucie', 'lea']);
    expect(start.liberoId, 'jade');
    expect(start.captainId, 'emma');
    expect(start.system, GameSystem.s51);
    expect(start.firstServer, Side.us);
  });

  testWidgets('la compo type se recharge au match suivant', (tester) async {
    final store = MemoryStore();
    await store.saveLineupTemplate(LineupTemplate(
      teamId: 'demo',
      format: GameFormat.six,
      lineup: demoStartSet.lineup,
      liberoId: 'jade',
      captainId: 'emma',
      system: GameSystem.s51,
    ));
    await openComposition(
      tester,
      const Size(1194, 834),
      store,
      CompositionScreen(team: demoTeam, rules: MatchRules.defaultFor(GameFormat.six), match: matchFor(demoTeam)),
    );
    await tester.tap(find.text('Charger « Compo type 5-1 »'));
    await tester.pump();
    expect(find.text('Emma (C)'), findsOneWidget);
    expect(find.text('Banc · 2'), findsOneWidget);
  });

  testWidgets('set suivant : composition reprise, service en alternance non modifiable', (tester) async {
    await openComposition(
      tester,
      const Size(1194, 834),
      MemoryStore(),
      CompositionScreen(
        team: demoTeam,
        rules: MatchRules.defaultFor(GameFormat.six),
        match: matchFor(demoTeam),
        setNumber: 2,
        initial: demoStartSet,
        initialServer: Side.them,
        serverLocked: true,
      ),
    );
    expect(find.text('Adversaire (alternance)'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Commencer le set 2')).onPressed, isNotNull);
  });

  testWidgets('smartphone 4x4 mixte : mixité contrôlée, sans débordement', (tester) async {
    await openComposition(
      tester,
      const Size(390, 844),
      MemoryStore(),
      CompositionScreen(team: mixed4, rules: MatchRules.defaultFor(GameFormat.four), match: matchFor(mixed4)),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('SYSTÈME'), findsNothing);
    await tapPlace(tester, 'Hugo', 'Avant droit · à placer');
    await tapPlace(tester, 'Lucas', 'Arrière gauche · à placer');
    await tapPlace(tester, 'Tom', 'Avant gauche · à placer');
    await tapPlace(tester, 'Emma', 'Arrière droit · à placer');
    expect(find.textContaining('Il faut au moins 2 femmes'), findsOneWidget);

    // Lucie remplace Tom : la mixité est respectée
    await tapPlace(tester, 'Lucie', 'Tom');
    expect(find.textContaining('Mixité respectée'), findsOneWidget);
    expect(find.text('F · Avant gauche'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
