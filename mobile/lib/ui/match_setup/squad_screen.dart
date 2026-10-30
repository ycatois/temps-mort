import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../common/labels.dart';
import '../common/widgets.dart';
import '../theme/tokens.dart';

/// Joueuses présentes au match (V1-PRE-03), juste avant la composition. Tout l'effectif actif est coché
/// par défaut : le coach décoche les absentes. Renvoie les identifiants cochés, ou null s'il renonce.
/// [locked] : joueuses déjà apparues dans le match, qu'on ne peut plus décocher.
class SquadScreen extends StatefulWidget {
  const SquadScreen({
    super.key,
    required this.team,
    required this.opponent,
    this.initial,
    this.locked = const {},
    this.confirmLabel = 'Continuer vers la composition',
  });

  /// L'équipe dans le format du match, avec tout son effectif.
  final Team team;
  final String opponent;
  final Iterable<String>? initial;
  final Set<String> locked;
  final String confirmLabel;

  @override
  State<SquadScreen> createState() => _SquadScreenState();
}

class _SquadScreenState extends State<SquadScreen> {
  late final List<Player> _players = [
    for (final p in widget.team.players)
      if (!p.archived || widget.locked.contains(p.id)) p,
  ]..sort((a, b) => a.number.compareTo(b.number));

  late final Set<String> _present = {
    ...(widget.initial ?? [for (final p in _players) p.id]),
    ...widget.locked,
  };

  List<SquadIssue> get _issues => validateSquad(widget.team, _present);

  String _issueLabel(SquadIssue issue) => switch (issue) {
        TooManyInSquad(:final max, :final actual) =>
          '$max ${playerWord(widget.team)}s au plus sur la feuille de match, liberos compris ($actual cochées).',
        NotEnoughInSquad(:final required, :final actual) =>
          'Il faut au moins $required ${playerWord(widget.team)}s pour composer le terrain ($actual cochées).',
        NotEnoughWomenInSquad(:final required, :final actual) =>
          'Il faut au moins $required femmes présentes pour la mixité ($actual cochées).',
      };

  @override
  Widget build(BuildContext context) {
    final word = playerWord(widget.team);
    final max = maxSquad(widget.team.format);
    final issues = _issues;
    final count = _present.length;

    Widget tile(Player p) {
      final locked = widget.locked.contains(p.id);
      return CheckboxListTile(
        value: _present.contains(p.id),
        onChanged: locked ? null : (v) => setState(() => v! ? _present.add(p.id) : _present.remove(p.id)),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        secondary: NumberBadge(p.number, muted: !_present.contains(p.id)),
        title: Text(p.firstName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        subtitle: Text(locked ? 'A déjà joué ce match' : roleLabel(p.role, p.gender)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Présentes · ${widget.opponent}')),
      body: LayoutBuilder(builder: (context, box) {
        final columns = box.maxWidth >= tabletWidth ? 2 : 1;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: TmCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          Text(
                            '$count ${count > 1 ? 'présentes' : 'présente'}${max == null ? '' : ' sur $max au plus'}',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 26),
                          ),
                          Wrap(spacing: 8, children: [
                            TextButton(
                              onPressed: () => setState(() => _present.addAll(_players.map((p) => p.id))),
                              child: const Text('Tout cocher'),
                            ),
                            TextButton(
                              onPressed: () => setState(() => _present
                                ..clear()
                                ..addAll(widget.locked)),
                              child: const Text('Tout décocher'),
                            ),
                          ]),
                        ],
                      ),
                      Text('Décochez les absentes : le banc, la composition et les remplacements ne proposeront que les ${word}s présentes.',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 12),
                      LayoutBuilder(builder: (context, inner) {
                        final width = (inner.maxWidth - (columns - 1) * 12) / columns;
                        return Wrap(
                          spacing: 12,
                          children: [for (final p in _players) SizedBox(width: width, child: tile(p))],
                        );
                      }),
                      for (final issue in issues)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error_outline, color: TmColor.error),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_issueLabel(issue), style: const TextStyle(color: TmColor.error, fontSize: 16)),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      YellowButton(
                        label: widget.confirmLabel,
                        onPressed: issues.isEmpty
                            ? () => Navigator.of(context).pop<List<String>>([
                                  for (final p in _players)
                                    if (_present.contains(p.id)) p.id,
                                ])
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
