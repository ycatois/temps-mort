import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../common/labels.dart';
import '../common/widgets.dart';
import '../theme/tokens.dart';
import 'match_controller.dart';

/// E06 — Remplacement et libero (V1-MAT-04, V1-MAT-05). Panneau latéral sur tablette, feuille du bas
/// sur smartphone. Aucune règle ici : chaque choix impossible est grisé avec la raison donnée par le moteur.
Future<void> showSubstitutionPanel(BuildContext context, MatchController c) {
  final tablet = MediaQuery.sizeOf(context).width >= tabletWidth;
  if (!tablet) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: TmColor.groundApp,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(TmRadius.xl))),
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .88),
      builder: (_) => SubstitutionPanel(c: c),
    );
  }
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fermer le panneau',
    barrierColor: Colors.black38,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondary) => Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 460,
        height: double.infinity,
        child: Material(color: TmColor.groundApp, child: SafeArea(left: false, child: SubstitutionPanel(c: c))),
      ),
    ),
    transitionBuilder: (context, animation, _, child) => SlideTransition(
      position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    ),
  );
}

class SubstitutionPanel extends StatefulWidget {
  const SubstitutionPanel({super.key, required this.c});

  final MatchController c;

  @override
  State<SubstitutionPanel> createState() => _SubstitutionPanelState();
}

class _SubstitutionPanelState extends State<SubstitutionPanel> {
  String? _outId;
  String? _inId;

  MatchController get c => widget.c;

  void _confirm() {
    if (c.substitute(_outId!, _inId!) == null) Navigator.of(context).pop();
  }

  void _liberoIn(String id) {
    if (c.liberoIn(id) == null) Navigator.of(context).pop();
  }

  void _liberoOut() {
    if (c.liberoOut() == null) Navigator.of(context).pop();
  }

  void _liberoSwap() {
    if (c.liberoSwap() == null) Navigator.of(context).pop();
  }

  /// Changement de libero (V1-PRE-05) : proposé dès qu'un second libero est désigné pour le set.
  Widget? _swapButton() {
    final s = c.state;
    final second = s.secondLiberoId == null ? null : c.team.player(s.secondLiberoId!);
    if (second == null) return null;
    final libero = c.team.player(s.liberoId!)!;
    final refusal = c.check(const LiberoSwap());
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, TmTouch.primaryTarget)),
        onPressed: refusal == null ? _liberoSwap : null,
        icon: const Icon(Icons.swap_horiz),
        label: Text(refusal?.message ??
            (s.liberoReplacing == null
                ? 'Changer de libero : ${second.firstName} au lieu de ${libero.firstName}'
                : 'Changer de libero : ${second.firstName} remplace ${libero.firstName}')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final s = c.state;
        final team = c.team;
        final word = playerWord(team);
        final limit = s.substitutionsLeft == null ? null : s.rules.substitutionsPerSet;
        final onCourt = [
          for (final (i, id) in s.lineup.indexed)
            if (id != s.liberoId) (index: i, player: team.player(id)!),
        ];
        final out = _outId == null ? null : team.player(_outId!);
        final partner = _outId == null ? null : s.partnerOf(_outId!);
        final substitutionsPossible = limit != 0 && s.phase == Phase.inPlay;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Remplacement',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 30)),
                ),
                IconButton(
                  tooltip: 'Fermer',
                  constraints: const BoxConstraints.tightFor(width: TmTouch.minTarget, height: TmTouch.minTarget),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(
              limit == null
                  ? 'Remplacements illimités dans ce set'
                  : limit == 0
                      ? 'Pas de remplacement dans ce format'
                      : 'Remplacements : ${s.substitutionsUsed} / $limit dans ce set',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: TmColor.muted),
            ),
            if (s.rules.pairedSubstitutions && substitutionsPossible)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Retour à la place d\'origine : une titulaire ne revient qu\'à la place de sa remplaçante.',
                  style: TextStyle(fontSize: 14, color: TmColor.muted),
                ),
              ),
            if (substitutionsPossible) ...[
              const SizedBox(height: 18),
              TmCard(
                title: '1 · Qui sort ?',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final e in onCourt)
                      _Choice(
                        number: e.player.number,
                        name: e.player.firstName,
                        detail: zoneName(team.format, e.index),
                        selected: e.player.id == _outId,
                        onPressed: () => setState(() {
                          _outId = e.player.id == _outId ? null : e.player.id;
                          _inId = null;
                        }),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TmCard(
                title: '2 · Qui entre ?',
                child: out == null
                    ? Text('Choisissez d\'abord la $word qui sort.', style: Theme.of(context).textTheme.bodyLarge)
                    : _benchChoices(out, partner),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _outId != null && _inId != null ? _confirm : null,
                child: Text(_outId != null && _inId != null
                    ? '${team.player(_inId!)!.firstName} entre, ${out!.firstName} sort'
                    : 'Valider le remplacement'),
              ),
            ],
            if (s.liberoId != null && s.phase == Phase.inPlay) ...[
              const SizedBox(height: 24),
              _liberoCard(),
            ],
            if (c.lastRejection != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(c.lastRejection!.message, style: const TextStyle(color: TmColor.error, fontSize: 15)),
              ),
          ],
        );
      },
    );
  }

  Widget _benchChoices(Player out, String? partner) {
    final bench = c.bench;
    if (bench.isEmpty) {
      return Text('Personne sur le banc.', style: Theme.of(context).textTheme.bodyLarge);
    }
    // La titulaire qui peut revenir est proposée en premier.
    bench.sort((a, b) => (a.id == partner ? 0 : 1).compareTo(b.id == partner ? 0 : 1));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final p in bench)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Builder(builder: (context) {
              final refusal = c.check(Substitution(out.id, p.id));
              return _Choice(
                number: p.number,
                name: p.firstName,
                detail: refusal?.message ??
                    (p.id == partner ? 'Revient à sa place d\'origine' : roleLabel(p.role, p.gender)),
                selected: p.id == _inId,
                expand: true,
                onPressed: refusal == null ? () => setState(() => _inId = p.id) : null,
              );
            }),
          ),
      ],
    );
  }

  Widget _liberoCard() {
    final s = c.state;
    final team = c.team;
    final libero = team.player(s.liberoId!)!;
    final replaced = s.liberoReplacing == null ? null : team.player(s.liberoReplacing!);
    if (replaced != null) {
      return TmCard(
        title: 'Libero',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${libero.firstName} est sur le terrain à la place de ${replaced.firstName}.',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, TmTouch.primaryTarget)),
              onPressed: _liberoOut,
              child: Text('${libero.firstName} sort, ${replaced.firstName} revient'),
            ),
            if (_swapButton() case final swap?) swap,
          ],
        ),
      );
    }
    // Le libero entre à la place d'une joueuse de la ligne arrière (zones 1, 6 et 5).
    final back = [for (final i in backRow6x6) if (i < s.lineup.length) (index: i, player: team.player(s.lineup[i])!)];
    return TmCard(
      title: 'Libero · ${libero.firstName} entre à la place de',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in back)
                Builder(builder: (context) {
                  final refusal = c.check(LiberoIn(e.player.id));
                  return _Choice(
                    number: e.player.number,
                    name: e.player.firstName,
                    detail: refusal == null ? zoneName(team.format, e.index) : refusal.message,
                    selected: false,
                    onPressed: refusal == null ? () => _liberoIn(e.player.id) : null,
                  );
                }),
            ],
          ),
          if (_swapButton() case final swap?) swap,
        ],
      ),
    );
  }
}

/// Bouton de choix d'une joueuse : numéro, prénom, détail ; 56 dp de haut (action de match).
class _Choice extends StatelessWidget {
  const _Choice({
    required this.number,
    required this.name,
    required this.detail,
    required this.selected,
    required this.onPressed,
    this.expand = false,
  });

  final int number;
  final String name;
  final String detail;
  final bool selected;
  final VoidCallback? onPressed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final fg = selected ? Colors.white : (enabled ? TmColor.text : TmColor.muted);
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: 'Numéro $number, $name, $detail',
      excludeSemantics: true,
      child: Material(
        color: selected ? TmColor.navy : (enabled ? TmColor.surface : TmColor.surfaceAlt),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: selected ? TmColor.navy : TmColor.line, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(TmRadius.md),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(TmRadius.md),
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: TmTouch.primaryTarget, minWidth: 120),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  Text(
                    '$number',
                    style: TextStyle(fontFamily: TmFont.display, fontWeight: FontWeight.w700, fontSize: 24, color: fg),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    fit: expand ? FlexFit.tight : FlexFit.loose,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: fg)),
                        Text(detail, style: TextStyle(fontSize: 13, color: fg)),
                      ],
                    ),
                  ),
                  if (selected) ...[const SizedBox(width: 8), const Icon(Icons.check_circle, color: Colors.white)],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
