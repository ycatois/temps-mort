import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temps_mort/data/store.dart';
import 'package:temps_mort/demo/demo_team.dart';
import 'package:temps_mort/domain/domain.dart';
import 'package:temps_mort/ui/common/store_scope.dart';
import 'package:temps_mort/ui/match/match_screen.dart';
import 'package:temps_mort/ui/tactics/tactics_screen.dart';
import 'package:temps_mort/ui/theme/theme.dart';

Future<MemoryStore> pumpTactics(WidgetTester tester, Size size, {List<String>? lineup}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final store = MemoryStore();
  await tester.pumpWidget(StoreScope(
    store: store,
    child: MaterialApp(
      theme: buildTheme(),
      home: TacticsScreen(
        team: demoTeam,
        lineup: lineup ?? rotate(rotate(demoStartSet.lineup)),
        liberoId: 'jade',
        rotation: 3,
        serving: false,
        score: '18 – 15',
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return store;
}

bool enabled(WidgetTester tester, String tooltip) {
  final ink = find.descendant(of: find.byTooltip(tooltip), matching: find.byType(InkWell));
  return tester.widget<InkWell>(ink).onTap != null;
}

Future<void> drawOnBoard(WidgetTester tester, Offset from) async {
  final gesture = await tester.startGesture(from);
  for (var i = 1; i <= 5; i++) {
    await gesture.moveBy(const Offset(12, -10));
    await tester.pump();
  }
  await gesture.up();
  await tester.pump();
}

void main() {
  testWidgets('tablette : pions de la rotation, déplacer, dessiner, annuler, enregistrer et rappeler', (tester) async {
    final store = await pumpTactics(tester, const Size(1194, 834));
    expect(find.text('Tableau tactique · rotation 3 en réception'), findsOneWidget);
    expect(find.text('18 – 15'), findsOneWidget);
    for (final name in ['Manon', 'Chloé', 'Emma', 'Inès', 'Lucie', 'Léa']) {
      expect(find.text(name), findsOneWidget, reason: name);
    }
    expect(find.text('Terrain entier'), findsOneWidget);

    // Déplacer un pion au doigt (outil par défaut)
    final before = tester.getCenter(find.text('Lucie'));
    await tester.dragFrom(before, const Offset(-60, -80));
    await tester.pumpAndSettle();
    final after = tester.getCenter(find.text('Lucie'));
    expect((after - before).dx, closeTo(-60, 2));
    expect((after - before).dy, closeTo(-80, 2));

    // Crayon : un trait, que l'on annule
    expect(enabled(tester, 'Annuler le dernier trait'), isFalse);
    await tester.tap(find.byTooltip('Crayon'));
    await tester.pump();
    final board = tester.getRect(find.byKey(const Key('tactics-board')));
    await drawOnBoard(tester, board.center + const Offset(0, 120));
    expect(enabled(tester, 'Annuler le dernier trait'), isTrue);
    expect(find.text('Lucie'), findsOneWidget);
    expect(tester.getCenter(find.text('Lucie')), after, reason: 'dessiner ne déplace pas les pions');
    await tester.tap(find.byTooltip('Annuler le dernier trait'));
    await tester.pump();
    expect(enabled(tester, 'Annuler le dernier trait'), isFalse);

    // Flèche rouge, ballon, adversaire, puis enregistrement
    await tester.tap(find.byTooltip('Flèche'));
    await tester.tap(find.bySemanticsLabel('Couleur rouge'));
    await tester.pump();
    await drawOnBoard(tester, board.center + const Offset(-80, 150));
    await tester.tap(find.byTooltip('Ajouter un ballon'));
    await tester.tap(find.byTooltip('Ajouter un adversaire'));
    await tester.pump();
    expect(find.text('A'), findsOneWidget);
    expect(enabled(tester, 'Ajouter un ballon'), isFalse, reason: 'un seul ballon');

    await tester.tap(find.text('Enregistrer ce schéma'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Rotation 3 en réception'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Couverture zone 4');
    await tester.tap(find.widgetWithText(FilledButton, 'Enregistrer'));
    await tester.pumpAndSettle();
    expect((await store.plays('demo')).single.board.strokes.single.color, StrokeColor.red);
    expect(find.text('Couverture zone 4'), findsOneWidget);

    // Tout effacer, puis rappeler le schéma
    await tester.tap(find.byTooltip('Tout effacer'));
    await tester.pump();
    expect(find.text('A'), findsNothing);
    expect(enabled(tester, 'Annuler le dernier trait'), isFalse);
    await tester.tap(find.text('Couverture zone 4'));
    await tester.pump();
    expect(find.text('A'), findsOneWidget);
    expect(enabled(tester, 'Annuler le dernier trait'), isTrue);

    // Replacer sur la rotation du match : Lucie revient à sa zone
    await tester.tap(find.text('Replacer sur la rotation du match'));
    await tester.pumpAndSettle();
    expect(tester.getCenter(find.text('Lucie')), before);
    expect(find.text('A'), findsOneWidget, reason: 'les adversaires restent');

    // Supprimer le schéma, après confirmation
    await tester.tap(find.byTooltip('Supprimer « Couverture zone 4 »'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Supprimer'));
    await tester.pumpAndSettle();
    expect(await store.plays('demo'), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('smartphone : demi-terrain, barre d\'outils, menu d\'ajout et bibliothèque', (tester) async {
    await pumpTactics(tester, const Size(390, 844));
    expect(find.text('Tactique · R3'), findsOneWidget);
    final half = tester.getSize(find.byKey(const Key('tactics-board')));

    for (final tip in ['Déplacer les pions', 'Crayon', 'Flèche', 'Zone', 'Annuler le dernier trait', 'Tout effacer']) {
      final size = tester.getSize(find.byTooltip(tip));
      expect(size.width, greaterThanOrEqualTo(48), reason: tip);
      expect(size.height, greaterThanOrEqualTo(48), reason: tip);
    }

    // La couleur change à chaque toucher
    await tester.tap(find.bySemanticsLabel(RegExp('^Couleur jaune')));
    await tester.pump();
    expect(find.bySemanticsLabel(RegExp('^Couleur rouge')), findsOneWidget);

    await tester.tap(find.byTooltip('Ajouter un ballon ou un adversaire'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajouter un adversaire'));
    await tester.pumpAndSettle();
    final halfRect = tester.getRect(find.byKey(const Key('tactics-board')));
    expect(halfRect.contains(tester.getCenter(find.text('A'))), isFalse,
        reason: 'en demi-terrain, le camp adverse est hors champ');

    await tester.tap(find.text('Terrain entier'));
    await tester.pumpAndSettle();
    final fullRect = tester.getRect(find.byKey(const Key('tactics-board')));
    expect(fullRect.contains(tester.getCenter(find.text('A'))), isTrue);
    expect(fullRect.size, isNot(half));

    await tester.tap(find.text('Schémas enregistrés · 0'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Aucun schéma'), findsOneWidget);
    expect(find.text('Replacer sur la rotation du match'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('le tableau s\'ouvre depuis le match, sur la rotation en cours', (tester) async {
    tester.view.physicalSize = const Size(1194, 834);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: buildTheme(), home: MatchScreen(team: demoTeam, events: [demoStartSet])));
    final button = find.text('Tableau tactique');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Tableau tactique · rotation 1 au service'), findsOneWidget);
    expect(find.text('0 – 0'), findsOneWidget);
    expect(find.text('Jade'), findsNothing, reason: 'la libero n\'est pas sur le terrain au service');
    expect(find.textContaining('Bibliothèque indisponible'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
