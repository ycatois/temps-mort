import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temps_mort/demo/demo_team.dart';
import 'package:temps_mort/domain/domain.dart';
import 'package:temps_mort/ui/match/match_screen.dart';
import 'package:temps_mort/ui/theme/theme.dart';

Future<void> pumpMatch(WidgetTester tester, Size size, {ValueChanged<List<MatchEvent>>? onEventsChanged}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: buildTheme(),
    home: MatchScreen(team: demoTeam, events: [demoStartSet], onEventsChanged: onEventsChanged),
  ));
}

void main() {
  testWidgets('tablette : une joueuse puis une attaque donnent le point', (tester) async {
    final saved = <List<MatchEvent>>[];
    await pumpMatch(tester, const Size(1194, 834), onEventsChanged: saved.add);
    expect(find.text('0 – 0'), findsOneWidget);
    await tester.tap(find.text('Lucie'));
    await tester.pump();
    await tester.tap(find.text('Attaque'));
    await tester.pump();
    expect(find.text('1 – 0'), findsOneWidget);
    expect(saved.last.length, 2, reason: 'chaque saisie est enregistrée');
    await tester.tap(find.text('Annuler la dernière saisie'));
    await tester.pump();
    expect(find.text('0 – 0'), findsOneWidget);
    expect(saved.last.length, 1, reason: "l'annulation aussi");
  });

  testWidgets('smartphone : l\'écran s\'affiche sans débordement', (tester) async {
    await pumpMatch(tester, const Size(390, 844));
    expect(tester.takeException(), isNull);
    expect(find.text('+1 adversaire'), findsOneWidget);
  });

  testWidgets('smartphone : la saisie complète tient sans débordement', (tester) async {
    await pumpMatch(tester, const Size(390, 844));
    await tester.tap(find.text('Complète'));
    await tester.pump();
    await tester.tap(find.text('Lucie'));
    await tester.pump();
    expect(find.text('0 · ratée'), findsOneWidget);
    expect(find.text('Faute (double, porté)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
