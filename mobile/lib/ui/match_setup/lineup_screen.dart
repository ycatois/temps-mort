import 'package:flutter/material.dart';

import '../../data/match_record.dart';
import '../../domain/domain.dart';
import '../common/labels.dart';
import '../common/store_scope.dart';
import '../common/widgets.dart';
import '../theme/tokens.dart';

/// Composition de départ, version simple en attendant l'écran E04 de la maquette (glisser-déposer) :
/// on touche les joueuses dans l'ordre des postes, on choisit le libero et qui sert.
/// Enregistre le début du premier set puis renvoie true.
class LineupScreen extends StatefulWidget {
  const LineupScreen({super.key, required this.team, required this.match});

  /// L'équipe dans le format du match.
  final Team team;
  final MatchRecord match;

  @override
  State<LineupScreen> createState() => _LineupScreenState();
}

class _LineupScreenState extends State<LineupScreen> {
  late final List<String?> _slots = List.filled(widget.team.format.playersOnCourt, null);
  String? _liberoId;
  Side? _firstServer;
  bool _saving = false;

  Team get _team => widget.team;
  bool get _liberoPossible => widget.match.rules.liberoAllowed && _team.format == GameFormat.six;
  bool get _complete => !_slots.contains(null);
  List<String> get _lineup => [for (final id in _slots) id!];
  List<LineupIssue> get _issues => _complete ? validateLineup(_team, _lineup, liberoId: _liberoId) : const [];

  void _toggle(Player p) {
    setState(() {
      final at = _slots.indexOf(p.id);
      if (at >= 0) {
        _slots[at] = null;
        return;
      }
      final free = _slots.indexOf(null);
      if (free < 0) return;
      _slots[free] = p.id;
      if (_liberoId == p.id) _liberoId = null;
    });
  }

  Future<void> _start() async {
    setState(() => _saving = true);
    final first = StartSet(_firstServer!, _lineup, liberoId: _liberoId);
    await StoreScope.of(context).saveEvents(widget.match.id, [first]);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final players = _team.activePlayers..sort((a, b) => a.number.compareTo(b.number));
    final word = playerWord(_team);
    final court = _CourtSlots(team: _team, slots: _slots, onClear: (i) => setState(() => _slots[i] = null));

    final bench = TmCard(
      title: 'Effectif',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Touchez les ${word}s dans l\'ordre des postes : poste 1 (au service), puis 2, 3… '
            'Touchez à nouveau pour retirer.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          if (players.length < _slots.length)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'L\'effectif compte ${players.length} personnes disponibles : il en faut ${_slots.length} pour jouer en ${_team.format.label}.',
                style: const TextStyle(color: TmColor.error, fontWeight: FontWeight.w600),
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in players)
                _PlayerButton(
                  player: p,
                  post: _slots.contains(p.id) ? _slots.indexOf(p.id) + 1 : null,
                  isLibero: p.id == _liberoId,
                  onPressed: () => _toggle(p),
                ),
            ],
          ),
        ],
      ),
    );

    final options = TmCard(
      title: 'Avant le coup d\'envoi',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_liberoPossible) ...[
            Text('Libero (facultatif)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Pas de libero'),
                  selected: _liberoId == null,
                  onSelected: (_) => setState(() => _liberoId = null),
                ),
                for (final p in players.where((p) => !_slots.contains(p.id)))
                  ChoiceChip(
                    label: Text('#${p.number} ${p.firstName}'),
                    selected: _liberoId == p.id,
                    onSelected: (_) => setState(() => _liberoId = p.id),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Text('Premier service', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<Side>(
            emptySelectionAllowed: true,
            segments: const [
              ButtonSegment(value: Side.us, label: Text('Nous servons')),
              ButtonSegment(value: Side.them, label: Text('Ils servent')),
            ],
            selected: _firstServer == null ? const {} : {_firstServer!},
            onSelectionChanged: (s) => setState(() => _firstServer = s.isEmpty ? null : s.single),
          ),
          for (final issue in _issues)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(lineupIssueLabel(issue), style: const TextStyle(color: TmColor.error, fontWeight: FontWeight.w600)),
            ),
          const SizedBox(height: 16),
          YellowButton(
            label: 'Commencer le match',
            onPressed: _complete && _firstServer != null && _issues.isEmpty && !_saving ? _start : null,
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text('Composition · ${widget.match.opponent}')),
      body: LayoutBuilder(builder: (context, box) {
        if (box.maxWidth >= tabletWidth) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 10, child: court),
                const SizedBox(width: 16),
                Expanded(flex: 11, child: Column(children: [bench, const SizedBox(height: 16), options])),
              ],
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [court, const SizedBox(height: 16), bench, const SizedBox(height: 16), options],
        );
      }),
    );
  }
}

/// Le terrain avec les postes : avant (4 3 2) en haut, arrière (5 6 1) en bas, comme l'écran de match.
class _CourtSlots extends StatelessWidget {
  const _CourtSlots({required this.team, required this.slots, required this.onClear});

  final Team team;
  final List<String?> slots;
  final ValueChanged<int> onClear;

  @override
  Widget build(BuildContext context) {
    final rows = switch (slots.length) {
      6 => const [
          [3, 2, 1],
          [4, 5, 0],
        ],
      4 => const [
          [2, 1],
          [3, 0],
        ],
      _ => [List.generate(slots.length, (i) => i)],
    };
    return Container(
      decoration: BoxDecoration(color: TmColor.courtOut, borderRadius: BorderRadius.circular(TmRadius.lg)),
      padding: const EdgeInsets.all(14),
      child: AspectRatio(
        aspectRatio: 1.1,
        child: Container(
          decoration: BoxDecoration(color: TmColor.court, border: Border.all(color: Colors.white, width: 2)),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final row in rows)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [for (final i in row) _Slot(post: i + 1, player: slots[i] == null ? null : team.player(slots[i]!), onTap: () => onClear(i))],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.post, required this.player, required this.onTap});

  final int post;
  final Player? player;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = player;
    return Semantics(
      button: p != null,
      label: p == null ? 'Poste $post, libre' : 'Poste $post : ${p.firstName}, numéro ${p.number}. Toucher pour retirer',
      excludeSemantics: true,
      child: Material(
        color: p == null ? Colors.transparent : TmColor.navy,
        shape: CircleBorder(
          side: BorderSide(color: post == 1 && p != null ? TmColor.yellow : Colors.white, width: p == null ? 2 : 3),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: p == null ? null : onTap,
          child: SizedBox(
            width: 76,
            height: 76,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: p == null
                  ? [Text('Poste $post', style: const TextStyle(color: TmColor.navy, fontWeight: FontWeight.w700))]
                  : [
                      Text('${p.number}',
                          style: const TextStyle(fontFamily: TmFont.display, fontWeight: FontWeight.w700, fontSize: 24, color: Colors.white, height: 1)),
                      Text(p.firstName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                    ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerButton extends StatelessWidget {
  const _PlayerButton({required this.player, required this.post, required this.isLibero, required this.onPressed});

  final Player player;

  /// Poste occupé (1 à n), ou null si la joueuse est sur le banc.
  final int? post;
  final bool isLibero;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = [
      '#${player.number} ${player.firstName}',
      if (post != null) 'poste $post',
      if (isLibero) 'libero',
    ].join(' · ');
    final style = post != null
        ? FilledButton.styleFrom(minimumSize: const Size(0, TmTouch.primaryTarget))
        : OutlinedButton.styleFrom(minimumSize: const Size(0, TmTouch.primaryTarget));
    return post != null
        ? FilledButton(onPressed: onPressed, style: style, child: Text(label))
        : OutlinedButton(onPressed: onPressed, style: style, child: Text(label));
  }
}
