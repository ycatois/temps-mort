import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../common/widgets.dart';
import '../match/match_controller.dart';
import '../theme/tokens.dart';

/// E07 — Statistiques en direct (V1-LIV-01, 04 à 07). Maquettes : design/maquettes/Tablette-Stats.dc.html
/// et Mobile-Stats.dc.html. Se met à jour pendant le match ; tous les calculs viennent de `computeStats`.
///
/// La qualité de réception (0 à 3) et l'efficacité en attaque (V1-LIV-02, 03) ne s'affichent que si la
/// période contient de la saisie complète : en saisie simple, les attaques restées en jeu manquent.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key, required this.c});

  final MatchController c;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  /// Set affiché (0 = premier set), ou null pour tout le match.
  late int? _set = widget.c.state.phase == Phase.inPlay ? widget.c.state.setIndex : null;

  MatchController get c => widget.c;

  /// Sets joués ou en cours, pour le choix de la période.
  int get _setCount => c.state.setsDone.length + (c.state.phase == Phase.inPlay ? 1 : 0);

  String get _scores => [
        for (final s in c.state.setsDone) '$s',
        if (c.state.phase == Phase.inPlay) '${c.state.score}',
      ].join(' · ');

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final stats = computeStats(c.state.history, touches: c.state.touches, setIndex: _set);
        final scores = _scores;
        return LayoutBuilder(builder: (context, box) {
          final tablet = box.maxWidth >= tabletWidth;
          final title = Text(
            scores.isEmpty ? 'Statistiques' : '${tablet ? 'Statistiques' : 'Stats'} · $scores',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: TmFont.display, fontWeight: FontWeight.w700, fontSize: 28),
          );
          if (tablet) {
            return Scaffold(
              appBar: AppBar(toolbarHeight: 72, title: title),
              body: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _periodPicker(),
                  const SizedBox(height: 16),
                  Row(children: [
                    for (final (i, t) in _tiles(stats, phone: false).indexed) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(child: t),
                    ],
                  ]),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: TmCard(title: 'Par joueuse', child: _playerTable(stats))),
                      const SizedBox(width: 16),
                      SizedBox(width: 380, child: TmCard(title: 'Par rotation', child: _rotations(stats))),
                    ],
                  ),
                ],
              ),
            );
          }
          return DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                toolbarHeight: 64,
                title: title,
                bottom: const TabBar(
                  labelColor: Colors.white,
                  unselectedLabelColor: TmColor.onNavyMuted,
                  indicatorColor: TmColor.yellow,
                  labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  tabs: [Tab(text: 'Joueuses'), Tab(text: 'Rotations'), Tab(text: 'Équipe')],
                ),
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(children: [
                      for (final (i, t) in _tiles(stats, phone: true).indexed) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(child: t),
                      ],
                    ]),
                  ),
                  Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 0), child: _periodPicker()),
                  Expanded(
                    child: TabBarView(children: [
                      ListView(padding: const EdgeInsets.all(16), children: [_playerList(stats)]),
                      ListView(padding: const EdgeInsets.all(16), children: [TmCard(child: _rotations(stats))]),
                      ListView(padding: const EdgeInsets.all(16), children: [_teamDetails(stats)]),
                    ]),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _periodPicker() {
    final n = _setCount;
    if (n == 0) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SegmentedButton<int>(
          showSelectedIcon: false,
          segments: [
            for (var i = 0; i < n; i++) ButtonSegment(value: i, label: Text('Set ${i + 1}')),
            const ButtonSegment(value: -1, label: Text('Match')),
          ],
          selected: {_set ?? -1},
          onSelectionChanged: (s) => setState(() => _set = s.single < 0 ? null : s.single),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Chiffres clés
  // ---------------------------------------------------------------------------

  List<Widget> _tiles(MatchStats st, {required bool phone}) {
    final o = st.origin;
    return [
      _Tile(label: 'Side-out', value: _percent(st.sideOutRate), caption: phone ? null : 'points gagnés en réception'),
      _Tile(label: 'Break', value: _percent(st.breakRate), caption: phone ? null : 'points gagnés au service'),
      _Tile(
        label: phone ? 'Réception' : 'Réception moyenne',
        value: st.fullInput ? _grade(st.team.receptionAverage) : '—',
        extra: phone || !st.fullInput || st.team.receptionAverage == null ? null : ' / 3',
        caption: phone
            ? null
            : st.fullInput
                ? '${st.team.receptions} réception${st.team.receptions > 1 ? 's' : ''}'
                : 'en saisie complète',
      ),
      if (!phone) ...[
        _Tile(
          label: 'Origine des points',
          value: '${o.scored}',
          extra: ' + ${o.opponentErrors}',
          caption: 'marqués + fautes adverses${o.unspecified > 0 ? ' (+ ${o.unspecified} sans détail)' : ''}',
        ),
        _Tile(label: 'Fautes directes', value: '${st.teamErrors}', caption: 'sur ${st.pointsLost} points perdus'),
      ],
    ];
  }

  // ---------------------------------------------------------------------------
  // Par joueuse
  // ---------------------------------------------------------------------------

  /// Joueuses de l'effectif et toute joueuse créditée, des plus décisives aux autres.
  List<Player> _players(MatchStats st) {
    final team = c.team;
    final list = [
      ...team.activePlayers,
      for (final id in st.byPlayer.keys)
        if (team.player(id)?.archived ?? false) team.player(id)!,
    ];
    int pts(Player p) => st.byPlayer[p.id]?.points ?? 0;
    return list..sort((a, b) => pts(b) != pts(a) ? pts(b).compareTo(pts(a)) : a.number.compareTo(b.number));
  }

  Widget _playerTable(MatchStats st) {
    const head = TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: TmColor.muted, letterSpacing: .5);
    const cell = TextStyle(fontSize: 17, fontWeight: FontWeight.w600);
    Widget num(int v, {bool strong = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text('$v', textAlign: TextAlign.center, style: strong ? cell.copyWith(fontWeight: FontWeight.w800) : cell),
        );
    Widget text(String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(v, textAlign: TextAlign.center, style: cell),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Table(
          columnWidths: const {0: FlexColumnWidth(2.4)},
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: const TableBorder(horizontalInside: BorderSide(color: TmColor.lineSoft)),
          children: [
            TableRow(children: [
              for (final h in ['JOUEUSE', 'POINTS', 'ATTAQUES', 'EFFICACITÉ', 'ACES', 'CONTRES', 'RÉCEPTION', 'FAUTES'])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(h, textAlign: h == 'JOUEUSE' ? TextAlign.start : TextAlign.center, style: head),
                ),
            ]),
            for (final p in _players(st))
              () {
                final s = st.byPlayer[p.id] ?? const PlayerStats();
                return TableRow(children: [
                  Row(children: [
                    NumberBadge(p.number, muted: p.archived),
                    const SizedBox(width: 10),
                    Flexible(child: Text(p.firstName, overflow: TextOverflow.ellipsis, style: cell)),
                  ]),
                  num(s.points, strong: true),
                  text(st.fullInput ? '${s.attackPoints}/${s.attackAttempts}' : '${s.attackPoints}'),
                  text(st.fullInput ? _signedPercent(s.attackEfficiency) : '—'),
                  num(s.aces),
                  num(s.blocks),
                  text(st.fullInput ? _grade(s.receptionAverage) : '—'),
                  num(s.errors),
                ]);
              }(),
          ],
        ),
        const SizedBox(height: 12),
        _Note(st.fullInput
            ? 'Attaques : points / tentatives. Efficacité = (points − fautes et contrées) / tentatives. '
                'Réception notée de 0 à 3.'
            : 'Attaques gagnantes. Efficacité et réception (0 à 3) : passez en saisie complète pendant le match.'),
      ],
    );
  }

  Widget _playerList(MatchStats st) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final p in _players(st)) ...[
          () {
            final s = st.byPlayer[p.id] ?? const PlayerStats();
            final line = [
              if (s.attackPoints > 0) '${s.attackPoints} attaque${s.attackPoints > 1 ? 's' : ''}',
              if (s.aces > 0) '${s.aces} ace${s.aces > 1 ? 's' : ''}',
              if (s.blocks > 0) '${s.blocks} contre${s.blocks > 1 ? 's' : ''}',
              if (s.errors > 0) '${s.errors} faute${s.errors > 1 ? 's' : ''}',
              if (st.fullInput && s.attackAttempts > 0) 'attaque ${_signedPercent(s.attackEfficiency)}',
              if (st.fullInput && s.receptions > 0) 'réception ${_grade(s.receptionAverage)}',
            ];
            return TmCard(
              child: Row(children: [
                NumberBadge(p.number, muted: p.archived),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.firstName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    Text(line.isEmpty ? '—' : line.join(' · '), style: const TextStyle(fontSize: 14, color: TmColor.muted)),
                  ]),
                ),
                Column(children: [
                  Text('${s.points}',
                      style: const TextStyle(fontFamily: TmFont.display, fontWeight: FontWeight.w700, fontSize: 28, height: 1)),
                  const Text('pts', style: TextStyle(fontSize: 12, color: TmColor.muted)),
                ]),
              ]),
            );
          }(),
          const SizedBox(height: 8),
        ],
        if (!st.fullInput) const _Note('Efficacité et réception (0 à 3) : passez en saisie complète pendant le match.'),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Par rotation
  // ---------------------------------------------------------------------------

  Widget _rotations(MatchStats st) {
    final n = c.team.format.playersOnCourt;
    final rows = [for (var r = 1; r <= n; r++) (rotation: r, score: st.byRotation[r] ?? const Score())];
    final max = rows.fold(1, (m, e) => e.score.us + e.score.them > m ? e.score.us + e.score.them : m);
    final weakest = st.weakestRotation;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Points gagnés et perdus dans chaque rotation', style: TextStyle(fontSize: 14, color: TmColor.muted)),
        const SizedBox(height: 12),
        for (final e in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Semantics(
              label: 'Rotation ${e.rotation} : ${e.score.us} gagnés, ${e.score.them} perdus'
                  '${e.rotation == weakest ? ', la plus faible' : ''}',
              excludeSemantics: true,
              child: Row(children: [
                SizedBox(
                  width: 34,
                  child: Text('R${e.rotation}',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: e.rotation == weakest ? TmColor.error : TmColor.text)),
                ),
                Expanded(child: _RotationBar(won: e.score.us, lost: e.score.them, max: max)),
                SizedBox(
                  width: 56,
                  child: Text('${e.score.us}–${e.score.them}',
                      textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ]),
            ),
          ),
        const SizedBox(height: 4),
        if (weakest != null)
          _Callout(
            strong: 'Rotation $weakest',
            text: ' : ${st.byRotation[weakest]!.us} points gagnés pour ${st.byRotation[weakest]!.them} perdus.',
          )
        else if (st.byRotation.isNotEmpty)
          const _Callout(strong: 'Aucune rotation déficitaire', text: ' pour l\'instant.'),
        const SizedBox(height: 10),
        Row(children: [
          const _Legend(color: TmColor.accent, label: 'Gagnés'),
          const SizedBox(width: 16),
          _Legend(color: _lostColor, label: 'Perdus', hatched: true),
        ]),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Équipe (smartphone)
  // ---------------------------------------------------------------------------

  Widget _teamDetails(MatchStats st) {
    final o = st.origin;
    final t = st.team;
    final errors = <String, int>{
      'Service': t.serviceErrors,
      'Attaque (dehors ou contrée)': t.attackErrors,
      'Réception': t.receptionErrors,
      'Contre': t.blockErrors,
      'Défense': t.digErrors,
      'Passe': t.setErrors,
      'Autre': t.otherErrors,
    };
    final unassigned = st.teamErrors - errors.values.fold<int>(0, (a, b) => a + b);
    Widget line(String label, int v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
            Text('$v', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ]),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TmCard(
          title: 'Origine des points · ${st.pointsWon}',
          child: Column(children: [
            line('Marqués (ace, attaque, contre)', o.scored),
            line('Fautes adverses', o.opponentErrors),
            if (o.unspecified > 0) line('Sans détail', o.unspecified),
          ]),
        ),
        const SizedBox(height: 12),
        TmCard(
          title: 'Fautes directes · ${st.teamErrors}',
          child: Column(children: [
            for (final e in errors.entries) line(e.key, e.value),
            if (unassigned > 0) line('Sans joueuse désignée', unassigned),
          ]),
        ),
      ],
    );
  }

  /// « +33 % », « −50 % » : l'efficacité peut être négative.
  static String _signedPercent(double? v) {
    if (v == null) return '—';
    final n = (v * 100).round();
    return '${n > 0 ? '+' : n < 0 ? '−' : ''}${n.abs()} %';
  }

  /// Moyenne de réception à la française : « 2,0 ».
  static String _grade(double? v) => v == null ? '—' : v.toStringAsFixed(1).replaceAll('.', ',');

  static String _percent(double? v) => v == null ? '—' : '${(v * 100).round()} %';
}

// -----------------------------------------------------------------------------

/// Teinte des points perdus, dérivée du token « faute » (orange brûlé).
final Color _lostColor = TmColor.error.withValues(alpha: .55);

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value, this.extra, this.caption});

  final String label;
  final String value;
  final String? extra;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return TmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: .8, color: TmColor.muted)),
          Text.rich(
            TextSpan(children: [
              TextSpan(text: value),
              if (extra != null) TextSpan(text: extra, style: const TextStyle(fontSize: 22, color: TmColor.muted)),
            ]),
            style: const TextStyle(fontFamily: TmFont.display, fontWeight: FontWeight.w700, fontSize: 36, height: 1.1),
          ),
          if (caption != null) Text(caption!, style: const TextStyle(fontSize: 13, color: TmColor.muted)),
        ],
      ),
    );
  }
}

class _RotationBar extends StatelessWidget {
  const _RotationBar({required this.won, required this.lost, required this.max});

  final int won;
  final int lost;
  final int max;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final unit = box.maxWidth / max;
      return Container(
        height: 18,
        decoration: BoxDecoration(color: TmColor.groundApp, borderRadius: BorderRadius.circular(4)),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.centerLeft,
        child: Row(children: [
          Container(width: unit * won, color: TmColor.accent),
          // Les points perdus sont hachurés : la différence ne repose pas sur la couleur seule.
          SizedBox(width: unit * lost, child: CustomPaint(painter: _Hatch(_lostColor), child: const SizedBox.expand())),
        ]),
      );
    });
  }
}

class _Hatch extends CustomPainter {
  const _Hatch(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = color);
    final line = Paint()
      ..color = Colors.white.withValues(alpha: .6)
      ..strokeWidth = 2;
    for (var x = -size.height; x < size.width; x += 7) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), line);
    }
  }

  @override
  bool shouldRepaint(_Hatch old) => old.color != color;
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, this.hatched = false});
  final Color color;
  final String label;
  final bool hatched;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: 18,
          height: 12,
          child: hatched ? CustomPaint(painter: _Hatch(color)) : ColoredBox(color: color),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 14, color: TmColor.muted)),
      ]);
}

class _Callout extends StatelessWidget {
  const _Callout({required this.strong, required this.text});
  final String strong;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TmColor.yellow.withValues(alpha: .22),
          border: Border.all(color: TmColor.yellow),
          borderRadius: BorderRadius.circular(TmRadius.md),
        ),
        child: Text.rich(
          TextSpan(children: [
            TextSpan(text: strong, style: const TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(text: text),
          ]),
          style: const TextStyle(fontSize: 15, color: TmColor.text),
        ),
      );
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 13, color: TmColor.muted));
}
