import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/domain.dart';
import '../common/labels.dart';
import 'summary_text.dart';

const _navy = PdfColor.fromInt(0xFF14213D);
const _muted = PdfColor.fromInt(0xFF5B6577);
const _line = PdfColor.fromInt(0xFFD3DAE3);
const _soft = PdfColor.fromInt(0xFFE6EBF2);

/// PDF détaillé du match (V1-FIN-02) : le résumé, puis le tableau par joueuse et les rotations.
/// Polices Barlow de l'app, embarquées dans le fichier (accents, aucun téléchargement).
Future<Uint8List> summaryPdf({
  required Team team,
  required MatchSummary summary,
  String? opponent,
  DateTime? date,
}) async {
  final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/barlow_regular.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/barlow_bold.ttf'));
  final display = pw.Font.ttf(await rootBundle.load('assets/fonts/barlow_condensed_bold.ttf'));
  final doc = pw.Document(
    title: 'Résumé du match ${team.name}${opponent == null ? '' : ' – $opponent'}',
    author: 'Temps Mort',
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );
  final st = summary.stats;
  final full = st.fullInput;

  pw.Widget heading(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 18, bottom: 8),
        child: pw.Text(text, style: pw.TextStyle(font: bold, fontSize: 14, color: _navy)),
      );

  final players = st.byPlayer.entries.toList()
    ..sort((a, b) {
      final byPoints = b.value.points.compareTo(a.value.points);
      return byPoints != 0 ? byPoints : (team.player(a.key)?.number ?? 0).compareTo(team.player(b.key)?.number ?? 0);
    });

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(36),
    footer: (context) => pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Temps Mort', style: const pw.TextStyle(fontSize: 9, color: _muted)),
        pw.Text('${context.pageNumber} / ${context.pagesCount}', style: const pw.TextStyle(fontSize: 9, color: _muted)),
      ],
    ),
    build: (context) => [
      pw.Text(
        [if (date != null) formatLongDate(date), team.category.label, team.format.label].join(' · ').toUpperCase(),
        style: const pw.TextStyle(fontSize: 10, color: _muted, letterSpacing: 1),
      ),
      pw.SizedBox(height: 6),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(team.name, style: pw.TextStyle(font: bold, fontSize: 20, color: _navy)),
                if (opponent != null) pw.Text('contre $opponent', style: const pw.TextStyle(fontSize: 14, color: _muted)),
                pw.Text(resultLabel(summary), style: pw.TextStyle(font: bold, fontSize: 14)),
              ],
            ),
          ),
          pw.Text('${summary.setsWon.us} – ${summary.setsWon.them}',
              style: pw.TextStyle(font: display, fontSize: 48, color: _navy)),
        ],
      ),
      pw.SizedBox(height: 10),
      pw.Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < summary.sets.length; i++)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: pw.BoxDecoration(color: _soft, borderRadius: pw.BorderRadius.circular(6)),
              child: pw.Column(children: [
                pw.Text('Set ${i + 1}${summary.sets[i].them > summary.sets[i].us ? ' · perdu' : ''}',
                    style: const pw.TextStyle(fontSize: 9, color: _muted)),
                pw.Text('${summary.sets[i]}', style: pw.TextStyle(font: display, fontSize: 18)),
              ]),
            ),
        ],
      ),
      heading('Chiffres clés'),
      pw.Row(children: [
        for (final (label, value) in keyFigures(summary))
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: _muted)),
              pw.Text(value, style: pw.TextStyle(font: display, fontSize: 22)),
            ]),
          ),
      ]),
      if (summary.best.isNotEmpty) ...[
        heading('Meilleures joueuses'),
        for (final b in summary.best)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(children: [
              pw.SizedBox(width: 150, child: pw.Text(bestCategoryLabel(b.category, team), style: const pw.TextStyle(color: _muted))),
              pw.SizedBox(width: 120, child: pw.Text(playerLabel(team, b.playerId), style: pw.TextStyle(font: bold))),
              pw.Text(bestDetail(b, fullInput: full)),
            ]),
          ),
      ],
      if (summary.takeaways.isNotEmpty) ...[
        heading('À retenir pour l\'entraînement'),
        for (final t in summary.takeaways.map(takeawayText))
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.RichText(
              text: pw.TextSpan(children: [
                pw.TextSpan(text: t.positive ? '+  ' : '–  ', style: pw.TextStyle(font: bold)),
                pw.TextSpan(text: t.bold, style: pw.TextStyle(font: bold)),
                pw.TextSpan(text: t.rest),
              ]),
            ),
          ),
      ],
      heading('Par ${playerWord(team)}'),
      pw.TableHelper.fromTextArray(
        headers: [
          'N°', 'Prénom', 'Points', 'Attaques', if (full) 'Efficacité', 'Aces', 'Contres', if (full) 'Réception', 'Fautes',
        ],
        data: [
          for (final e in players)
            [
              '${team.player(e.key)?.number ?? '?'}',
              team.player(e.key)?.firstName ?? '?',
              '${e.value.points}',
              full ? '${e.value.attackPoints}/${e.value.attackAttempts}' : '${e.value.attackPoints}',
              if (full) percent(e.value.attackEfficiency),
              '${e.value.aces}',
              '${e.value.blocks}',
              if (full) grade(e.value.receptionAverage),
              '${e.value.errors}',
            ],
        ],
        headerStyle: pw.TextStyle(font: bold, fontSize: 10, color: PdfColors.white),
        headerDecoration: const pw.BoxDecoration(color: _navy),
        cellStyle: const pw.TextStyle(fontSize: 10),
        cellAlignment: pw.Alignment.center,
        cellAlignments: {1: pw.Alignment.centerLeft},
        border: const pw.TableBorder(horizontalInside: pw.BorderSide(color: _line, width: 0.5)),
      ),
      if (!full)
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 4),
          child: pw.Text('Saisie simple : attaques gagnantes seulement, sans efficacité ni réception.',
              style: const pw.TextStyle(fontSize: 9, color: _muted)),
        ),
      heading('Par rotation'),
      pw.TableHelper.fromTextArray(
        headers: ['Rotation', 'Gagnés', 'Perdus', 'Solde'],
        data: [
          for (final e in st.byRotation.entries)
            ['R${e.key}', '${e.value.us}', '${e.value.them}', _signed(e.value.us - e.value.them)],
        ],
        headerStyle: pw.TextStyle(font: bold, fontSize: 10, color: PdfColors.white),
        headerDecoration: const pw.BoxDecoration(color: _navy),
        cellStyle: const pw.TextStyle(fontSize: 10),
        cellAlignment: pw.Alignment.center,
        border: const pw.TableBorder(horizontalInside: pw.BorderSide(color: _line, width: 0.5)),
      ),
    ],
  ));
  return doc.save();
}

String _signed(int n) => n > 0 ? '+$n' : '$n';
