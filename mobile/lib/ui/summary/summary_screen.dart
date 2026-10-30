import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/csv_export.dart';
import '../../domain/domain.dart';
import '../common/labels.dart';
import '../common/widgets.dart';
import '../theme/tokens.dart';
import 'summary_pdf.dart';
import 'summary_text.dart';

/// Envoie un fichier par la feuille de partage du téléphone (V1-FIN-03). Remplacée dans les tests.
typedef ShareFile = Future<void> Function(Uint8List bytes, String fileName, String mimeType, {Rect? origin});

Future<void> shareWithSystem(Uint8List bytes, String fileName, String mimeType, {Rect? origin}) =>
    SharePlus.instance.share(ShareParams(
      files: [XFile.fromData(bytes, mimeType: mimeType, name: fileName)],
      fileNameOverrides: [fileName],
      sharePositionOrigin: origin,
    ));

/// E10 — Résumé du match (V1-FIN-01 à 04). Tablette : carte de résumé à gauche, partage et « à retenir »
/// à droite ; smartphone : carte, à retenir, puis boutons. Maquettes : design/maquettes/Tablette-Resume.dc.html
/// et Mobile-Resume.dc.html. La carte est exactement l'image envoyée.
class SummaryScreen extends StatefulWidget {
  const SummaryScreen({
    super.key,
    required this.team,
    this.rules,
    required this.events,
    this.opponent,
    this.date,
    this.share = shareWithSystem,
  });

  /// L'équipe dans le format du match.
  final Team team;
  final MatchRules? rules;
  final List<MatchEvent> events;
  final String? opponent;
  final DateTime? date;
  final ShareFile share;

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final _cardKey = GlobalKey();
  late final MatchState _state = MatchSession(widget.team, rules: widget.rules, events: widget.events).state;
  late final MatchSummary _summary = summarize(widget.team, _state);
  bool _busy = false;

  String get _fileName => exportFileName(widget.date, widget.opponent);

  Rect? _origin(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _export(BuildContext buttonContext, Future<(Uint8List, String, String)> Function() build) async {
    final origin = _origin(buttonContext);
    setState(() => _busy = true);
    try {
      final (bytes, name, mime) = await build();
      await widget.share(bytes, name, mime, origin: origin);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Partage impossible : $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<(Uint8List, String, String)> _image() async {
    final boundary = _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return (data!.buffer.asUint8List(), '$_fileName.png', 'image/png');
  }

  Future<(Uint8List, String, String)> _pdf() async => (
        await summaryPdf(team: widget.team, summary: _summary, opponent: widget.opponent, date: widget.date),
        '$_fileName.pdf',
        'application/pdf',
      );

  Future<(Uint8List, String, String)> _csv() async => (
        Uint8List.fromList(utf8.encode(matchCsv(widget.team, _state.rules, widget.events))),
        '${_fileName.replaceFirst('resume', 'donnees')}.csv',
        'text/csv',
      );

  void _home() => Navigator.of(context).popUntil((r) => r.isFirst);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final tablet = box.maxWidth >= tabletWidth;
      final card = RepaintBoundary(
        key: _cardKey,
        child: _SummaryCard(
          team: widget.team,
          summary: _summary,
          opponent: widget.opponent,
          date: widget.date,
          compact: !tablet,
        ),
      );
      final shareButton = Builder(
        builder: (b) => FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 60), textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          onPressed: _busy ? null : () => _export(b, _image),
          icon: const Icon(Icons.ios_share),
          label: Text(tablet ? 'Partager l\'image (WhatsApp, e-mail…)' : 'Envoyer l\'image'),
        ),
      );
      final files = Row(children: [
        Expanded(
          child: Builder(
            builder: (b) => OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, TmTouch.primaryTarget)),
              onPressed: _busy ? null : () => _export(b, _pdf),
              child: Text(tablet ? 'PDF détaillé' : 'PDF'),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Builder(
            builder: (b) => OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, TmTouch.primaryTarget)),
              onPressed: _busy ? null : () => _export(b, _csv),
              child: Text(tablet ? 'Données CSV' : 'CSV'),
            ),
          ),
        ),
      ]);
      final takeaways = _Takeaways(summary: _summary);
      final home = TextButton(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, TmTouch.primaryTarget),
          backgroundColor: TmColor.surfaceAlt,
          foregroundColor: TmColor.navy,
        ),
        onPressed: _home,
        child: const Text('Revenir à l\'accueil'),
      );

      return Scaffold(
        backgroundColor: TmColor.groundApp,
        appBar: AppBar(
          title: const Text('Résumé du match', style: TextStyle(fontFamily: TmFont.display, fontWeight: FontWeight.w700, fontSize: 26)),
          bottom: _busy ? const PreferredSize(preferredSize: Size.fromHeight(4), child: LinearProgressIndicator()) : null,
        ),
        body: SafeArea(
          top: false,
          child: tablet
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 640, child: SingleChildScrollView(child: card)),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TmCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text('Partager le résumé', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 12),
                                  shareButton,
                                  const SizedBox(height: 10),
                                  files,
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: TmCard(
                                child: Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(child: SingleChildScrollView(child: takeaways)),
                                      const SizedBox(height: 12),
                                      home,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    card,
                    const SizedBox(height: 14),
                    TmCard(child: takeaways),
                    const SizedBox(height: 14),
                    shareButton,
                    const SizedBox(height: 10),
                    files,
                    const SizedBox(height: 10),
                    home,
                  ],
                ),
        ),
      );
    });
  }
}

/// La carte partageable : score, sets, meilleures joueuses, chiffres clés.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.team, required this.summary, required this.opponent, required this.date, required this.compact});

  final Team team;
  final MatchSummary summary;
  final String? opponent;
  final DateTime? date;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final head = [
      if (date != null) compact ? formatDate(date!).replaceFirst(RegExp(r' \d{4}$'), '') : formatLongDate(date!),
      team.name,
    ].join(' · ');
    final won = s.winner == Side.us;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 18 : 30, vertical: compact ? 18 : 28),
      decoration: BoxDecoration(color: TmColor.navy, borderRadius: BorderRadius.circular(TmRadius.xl)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(head.toUpperCase(),
                    style: const TextStyle(color: TmColor.onNavyMuted, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: won ? TmColor.yellow : TmColor.navySoft,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(resultLabel(s),
                    style: TextStyle(color: won ? TmColor.navy : Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(team.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                    if (opponent != null)
                      Text(opponent!, style: const TextStyle(color: TmColor.onNavyMuted, fontSize: 16)),
                  ],
                ),
              ),
              Semantics(
                label: 'Sets ${s.setsWon.us} à ${s.setsWon.them}',
                excludeSemantics: true,
                child: Text('${s.setsWon.us} – ${s.setsWon.them}',
                    style: TextStyle(
                        fontFamily: TmFont.display, fontWeight: FontWeight.w700, fontSize: compact ? 64 : 92, height: 1, color: Colors.white)),
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 18),
          Row(
            children: [
              for (var i = 0; i < s.sets.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _SetTile(index: i, score: s.sets[i], compact: compact)),
              ],
            ],
          ),
          if (s.best.isNotEmpty) ...[
            SizedBox(height: compact ? 12 : 18),
            LayoutBuilder(builder: (context, box) {
              final w = (box.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final b in s.best)
                    SizedBox(
                      width: w,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(TmRadius.md)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(bestCategoryLabel(b.category, team).toUpperCase(),
                                style: const TextStyle(color: TmColor.muted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
                            Text(playerLabel(team, b.playerId),
                                style: TextStyle(color: TmColor.text, fontSize: compact ? 16 : 18, fontWeight: FontWeight.w700)),
                            Text(bestDetail(b, fullInput: s.stats.fullInput),
                                style: const TextStyle(color: TmColor.muted, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            }),
          ],
          SizedBox(height: compact ? 12 : 20),
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF33456E)))),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 16,
              runSpacing: 6,
              children: [
                for (final (label, value) in keyFigures(s))
                  Text.rich(TextSpan(
                    style: const TextStyle(color: TmColor.onNavy, fontSize: 15),
                    children: [
                      TextSpan(text: '$label '),
                      TextSpan(text: value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ],
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SetTile extends StatelessWidget {
  const _SetTile({required this.index, required this.score, required this.compact});
  final int index;
  final Score score;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final lost = score.them > score.us;
    return Semantics(
      label: 'Set ${index + 1} ${lost ? 'perdu' : 'gagné'} ${score.us} à ${score.them}',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: compact ? 6 : 10),
        decoration: BoxDecoration(color: TmColor.navySoft, borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            if (!compact) Text('Set ${index + 1}', style: const TextStyle(color: TmColor.onNavyMuted, fontSize: 12)),
            Text('$score',
                style: TextStyle(
                    fontFamily: TmFont.display,
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 20 : 26,
                    color: lost ? TmColor.onNavyMuted : Colors.white)),
          ],
        ),
      ),
    );
  }
}

/// « À retenir pour l'entraînement » : une icône de tendance en plus de la couleur.
class _Takeaways extends StatelessWidget {
  const _Takeaways({required this.summary});
  final MatchSummary summary;

  @override
  Widget build(BuildContext context) {
    final items = summary.takeaways.map(takeawayText).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('À retenir pour l\'entraînement', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const Text('Pas encore assez d\'échanges pour en tirer des enseignements.',
              style: TextStyle(color: TmColor.muted, fontSize: 16)),
        for (final t in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(t.positive ? Icons.trending_up : Icons.trending_down,
                    size: 20, color: t.positive ? TmColor.accent : TmColor.error),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(TextSpan(
                    style: const TextStyle(fontSize: 16, color: TmColor.text),
                    children: [
                      TextSpan(text: t.bold, style: const TextStyle(fontWeight: FontWeight.w700)),
                      TextSpan(text: t.rest),
                    ],
                  )),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
