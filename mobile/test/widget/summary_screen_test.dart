import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temps_mort/data/csv_export.dart';
import 'package:temps_mort/demo/demo_team.dart';
import 'package:temps_mort/domain/domain.dart';
import 'package:temps_mort/ui/match/match_screen.dart';
import 'package:temps_mort/ui/summary/summary_screen.dart';
import 'package:temps_mort/ui/summary/summary_text.dart';
import 'package:temps_mort/ui/theme/theme.dart';

final rules = MatchRules.defaultFor(GameFormat.six).copyWith(setsToWin: 2, pointsPerSet: 3, pointsDecidingSet: 3);

/// Match terminé 2–0 : Lucie marque, Emma contre, Manon fait une faute de service puis un ace,
/// avec un remplacement et un temps mort pour le journal CSV.
List<MatchEvent> finishedMatch() {
  final s = MatchSession(demoTeam, rules: rules, events: [demoStartSet]);
  for (final e in const [
    Rally(Side.us, playerId: 'lucie', action: RallyAction.attaque),
    TimeoutTaken(Side.us),
    Rally(Side.them, playerId: 'manon', action: RallyAction.serviceFaute),
    Touch('chloe', TouchKind.reception3),
    Rally(Side.us, playerId: 'emma', action: RallyAction.contre),
    Substitution('ines', 'zoe'),
    Rally(Side.us, playerId: 'lucie', action: RallyAction.attaque),
  ]) {
    expect(s.record(e), isNull, reason: '$e');
  }
  s.record(s.nextSetStart()!);
  for (var i = 0; i < 3; i++) {
    s.record(const Rally(Side.us, playerId: 'lucie', action: RallyAction.attaque));
  }
  expect(s.state.phase, Phase.finished);
  return s.events;
}

typedef Shared = ({Uint8List bytes, String name, String mime});

Future<List<Shared>> pumpSummary(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final shared = <Shared>[];
  await tester.pumpWidget(MaterialApp(
    theme: buildTheme(),
    home: SummaryScreen(
      team: demoTeam,
      rules: rules,
      events: finishedMatch(),
      opponent: 'AS Rennes',
      date: DateTime(2026, 11, 15, 15),
      share: (bytes, name, mime, {origin}) async => shared.add((bytes: bytes, name: name, mime: mime)),
    ),
  ));
  await tester.pumpAndSettle();
  return shared;
}

Future<void> tapAndWait(WidgetTester tester, Finder button) async {
  await tester.ensureVisible(button);
  await tester.runAsync(() async {
    await tester.tap(button);
    // Capture d'image et PDF : du vrai travail asynchrone, hors de l'horloge simulée du test.
    for (var i = 0; i < 50; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await tester.pump();
    }
  });
  await tester.pumpAndSettle();
}

void main() {
  test('CSV : une ligne par événement, score et rotation au moment de l\'échange', () {
    final csv = matchCsv(demoTeam, rules, finishedMatch());
    expect(csv.startsWith('﻿Set;Échange;Score'), isTrue);
    final lines = csv.trim().split('\r\n');
    expect(lines[1], '1;;0–0;nous;1;;;;Début du set');
    expect(lines[2], '1;1;1–0;nous;1;nous;7;Lucie;Attaque');
    expect(lines[3], '1;;1–0;;;;;;Temps mort');
    expect(lines[4], '1;2;1–1;nous;1;adversaire;5;Manon;Faute de service');
    expect(lines[5], '1;3;1–1;adversaire;1;;9;Chloé;Réception notée 3');
    expect(lines.where((l) => l.contains('Remplacement : sort pour 10 Zoé')), hasLength(1));
    expect(lines.where((l) => l.startsWith('1;') && l.contains(';3–1;')), isNotEmpty, reason: 'score final du set 1');
    expect(lines.last, '2;3;3–0;nous;2;nous;7;Lucie;Attaque');
  });

  test('nom de fichier sans accent ni espace', () {
    expect(exportFileName(DateTime(2026, 11, 5), 'Élan Sportif d\'Orléans'), 'resume-2026-11-05-elan-sportif-d-orleans');
    expect(exportFileName(null, null), 'resume');
  });

  testWidgets('tablette : carte de résumé, à retenir, partage image, PDF et CSV', (tester) async {
    final shared = await pumpSummary(tester, const Size(1194, 834));
    expect(find.text('Victoire'), findsOneWidget);
    expect(find.text('2 – 0'), findsOneWidget);
    expect(find.text('AS Rennes'), findsOneWidget);
    expect(find.text('3–1'), findsOneWidget);
    expect(find.text('MEILLEURE MARQUEUSE'), findsOneWidget);
    expect(find.text('#7 Lucie'), findsOneWidget);
    // Le match contient un geste en jeu (saisie complète) : l'efficacité en attaque est donnée.
    expect(find.text('5 points · 100 % en attaque'), findsOneWidget);
    expect(find.text('MEILLEURE AU CONTRE'), findsOneWidget);
    expect(find.textContaining('1 faute de service', findRichText: true), findsOneWidget);
    expect(find.text('À retenir pour l\'entraînement'), findsOneWidget);

    await tapAndWait(tester, find.text('Données CSV'));
    expect(shared.single.name, 'donnees-2026-11-15-as-rennes.csv');
    expect(utf8.decode(shared.single.bytes), contains('Lucie;Attaque'));

    await tapAndWait(tester, find.text('PDF détaillé'));
    expect(shared.last.name, 'resume-2026-11-15-as-rennes.pdf');
    expect(String.fromCharCodes(shared.last.bytes.take(5)), '%PDF-');

    await tapAndWait(tester, find.textContaining('Partager l\'image'));
    expect(shared.last.mime, 'image/png');
    expect(shared.last.bytes.sublist(1, 4), utf8.encode('PNG'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('smartphone : carte compacte et boutons en bas, sans débordement', (tester) async {
    await pumpSummary(tester, const Size(390, 844));
    expect(find.text('2 – 0'), findsOneWidget);
    // Liste construite au fil du défilement : on descend jusqu'aux boutons.
    await tester.scrollUntilVisible(find.text('CSV'), 300);
    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('CSV'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fin de match : le bouton du résumé est mis en avant', (tester) async {
    tester.view.physicalSize = const Size(1194, 834);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: MatchScreen(team: demoTeam, rules: rules, events: finishedMatch(), opponent: 'AS Rennes'),
    ));
    await tester.tap(find.text('Voir le résumé et le partager'));
    await tester.pumpAndSettle();
    expect(find.text('Résumé du match'), findsOneWidget);
    expect(find.text('AS Rennes'), findsOneWidget);
  });
}
