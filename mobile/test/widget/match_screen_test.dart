import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temps_mort/ui/match/match_screen.dart';
import 'package:temps_mort/ui/theme/theme.dart';

Future<void> pumpMatch(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: buildTheme(), home: const MatchScreen()));
}

void main() {
  testWidgets('tablette : une joueuse puis une attaque donnent le point', (tester) async {
    await pumpMatch(tester, const Size(1194, 834));
    expect(find.text('0 – 0'), findsOneWidget);
    await tester.tap(find.text('Lucie'));
    await tester.pump();
    await tester.tap(find.text('Attaque'));
    await tester.pump();
    expect(find.text('1 – 0'), findsOneWidget);
    await tester.tap(find.text('Annuler la dernière saisie'));
    await tester.pump();
    expect(find.text('0 – 0'), findsOneWidget);
  });

  testWidgets('smartphone : l\'écran s\'affiche sans débordement', (tester) async {
    await pumpMatch(tester, const Size(390, 844));
    expect(tester.takeException(), isNull);
    expect(find.text('+1 adversaire'), findsOneWidget);
  });
}
