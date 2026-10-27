import 'package:flutter/material.dart';

import '../../demo/demo_team.dart';
import '../../domain/domain.dart';
import '../theme/tokens.dart';
import 'match_controller.dart';

/// E05 — Match en direct. Tablette (≥ 840 px de large) : terrain et saisie côte à côte ;
/// smartphone : empilés, avec défilement. Maquettes : design/maquettes/Main.dc.html et Mobile-Match.dc.html.
class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  late final MatchController _c = MatchController(demoTeam, demoStartSet);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: _c,
        builder: (context, _) => Column(
          children: [
            _ScoreBar(c: _c),
            Expanded(
              child: SafeArea(
                top: false,
                child: LayoutBuilder(
                  builder: (context, box) {
                    if (box.maxWidth >= 840) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 11, child: SingleChildScrollView(child: _Court(c: _c))),
                            const SizedBox(width: 16),
                            Expanded(flex: 10, child: SingleChildScrollView(child: _ActionPanel(c: _c))),
                          ],
                        ),
                      );
                    }
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [_Court(c: _c), const SizedBox(height: 12), _ActionPanel(c: _c)],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.c});
  final MatchController c;

  @override
  Widget build(BuildContext context) {
    final s = c.state;
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.phase == Phase.finished
              ? 'FIN DU MATCH · ${c.team.format.label}'
              : 'SET ${s.setIndex + 1} · ${c.team.format.label} ${c.team.gender.label.toLowerCase()}',
          style: const TextStyle(color: TmColor.onNavyMuted, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        Text('Sets ${s.setsWon.us}–${s.setsWon.them}', style: const TextStyle(color: TmColor.onNavy, fontSize: 15)),
      ],
    );
    final score = Semantics(
      label: 'Score ${s.score.us} à ${s.score.them}',
      excludeSemantics: true,
      child: Text(
        '${s.score.us} – ${s.score.them}',
        style: const TextStyle(fontFamily: TmFont.display, fontWeight: FontWeight.w700, fontSize: 56, color: Colors.white, height: 1),
      ),
    );
    final timeout = FilledButton(
      onPressed: s.phase == Phase.inPlay && s.timeoutsLeft(Side.us) > 0 ? c.timeout : null,
      style: FilledButton.styleFrom(
        backgroundColor: TmColor.yellow,
        foregroundColor: TmColor.navy,
        minimumSize: const Size(0, TmTouch.minTarget),
      ),
      child: Text('Temps mort ${s.timeoutsUsed.us}/${s.rules.timeoutsPerSet}'),
    );

    return Container(
      color: TmColor.navy,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: LayoutBuilder(
            builder: (context, box) {
              if (box.maxWidth < 600) {
                // Smartphone : score sur la première ligne, temps mort sur la seconde.
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [Expanded(child: info), score]),
                    const SizedBox(height: 8),
                    timeout,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: info),
                  score,
                  Expanded(child: Align(alignment: Alignment.centerRight, child: timeout)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Court extends StatelessWidget {
  const _Court({required this.c});
  final MatchController c;

  @override
  Widget build(BuildContext context) {
    final s = c.state;
    final lineup = s.lineup;
    // Avant (4 3 2) en haut, arrière (5 6 1) en bas ; index 0 = poste 1.
    final rows = switch (lineup.length) {
      6 => const [
          [3, 2, 1],
          [4, 5, 0],
        ],
      4 => const [
          [2, 1],
          [3, 0],
        ],
      _ => [List.generate(lineup.length, (i) => i)],
    };

    return Container(
      decoration: BoxDecoration(color: TmColor.courtOut, borderRadius: BorderRadius.circular(TmRadius.lg)),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'R${s.rotation} · ${s.serving == Side.us ? 'au service' : 'en réception'}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 10),
          AspectRatio(
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
                      children: [
                        for (final idx in row.where((i) => i < lineup.length))
                          _PlayerToken(
                            number: c.label(lineup[idx]).number,
                            name: c.label(lineup[idx]).name,
                            serving: idx == 0 && s.serving == Side.us,
                            libero: lineup[idx] == s.liberoId,
                            selected: lineup[idx] == c.selectedPlayerId,
                            onTap: () => c.select(lineup[idx]),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerToken extends StatelessWidget {
  const _PlayerToken({
    required this.number,
    required this.name,
    required this.serving,
    required this.libero,
    required this.selected,
    required this.onTap,
  });

  final int number;
  final String name;
  final bool serving;
  final bool libero;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = libero ? Colors.white : TmColor.navy;
    final fg = libero ? TmColor.navy : Colors.white;
    final ring = selected
        ? const BorderSide(color: TmColor.accent, width: 4)
        : serving
            ? const BorderSide(color: TmColor.yellow, width: 3)
            : BorderSide(color: libero ? TmColor.navy : Colors.white, width: 2);

    return Semantics(
      button: true,
      selected: selected,
      label: '$name, numéro $number${serving ? ', au service' : ''}',
      excludeSemantics: true,
      child: Material(
        color: bg,
        shape: CircleBorder(side: ring),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 76,
            height: 76,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$number', style: TextStyle(fontFamily: TmFont.display, fontWeight: FontWeight.w700, fontSize: 24, color: fg, height: 1)),
                Text(libero ? '$name · L' : name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({required this.c});
  final MatchController c;

  static const _gains = [RallyAction.attaque, RallyAction.ace, RallyAction.contre];
  static const _faults = [RallyAction.attaqueFaute, RallyAction.serviceFaute, RallyAction.receptionFaute];

  @override
  Widget build(BuildContext context) {
    final s = c.state;
    final selectedId = c.selectedPlayerId;
    final selected = selectedId == null ? null : c.label(selectedId);
    final playing = s.phase == Phase.inPlay;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (s.phase == Phase.finished)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '${s.winner == Side.us ? 'Match gagné' : 'Match perdu'} ${s.setsWon}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 28),
            ),
          ),
        if (c.canStartNextSet && !c.nextSetIsDeciding)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _BigButton(
              label: 'Set ${s.setIndex + 1} : même composition',
              background: TmColor.yellow,
              foreground: TmColor.navy,
              onPressed: c.startNextSet,
            ),
          ),
        if (c.canStartNextSet && c.nextSetIsDeciding)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: _BigButton(
                    label: 'Set décisif : nous servons',
                    background: TmColor.yellow,
                    foreground: TmColor.navy,
                    onPressed: () => c.startNextSet(firstServer: Side.us),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _BigButton(
                    label: 'Set décisif : ils servent',
                    background: TmColor.yellow,
                    foreground: TmColor.navy,
                    onPressed: () => c.startNextSet(firstServer: Side.them),
                  ),
                ),
              ],
            ),
          ),
        Text(
          selected == null ? "Touchez une joueuse, puis l'action" : "#${selected.number} ${selected.name} : choisir l'action",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final a in _gains) ...[
              Expanded(
                child: _BigButton(
                  label: a.label,
                  background: TmColor.accent,
                  foreground: Colors.white,
                  onPressed: playing ? () => c.action(a) : null,
                ),
              ),
              if (a != _gains.last) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final a in _faults) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: playing ? () => c.action(a) : null,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, TmTouch.primaryTarget),
                    side: const BorderSide(color: TmColor.error, width: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  child: Text(a.label, textAlign: TextAlign.center),
                ),
              ),
              if (a != _faults.last) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _BigButton(
                label: '+1 faute adverse',
                background: TmColor.navy,
                foreground: Colors.white,
                onPressed: playing ? c.opponentError : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _BigButton(
                label: '+1 adversaire',
                background: TmColor.surfaceAlt,
                foreground: TmColor.navy,
                onPressed: playing ? c.opponentPoint : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        OutlinedButton(onPressed: c.canUndo ? c.undo : null, child: const Text('Annuler la dernière saisie')),
        if (c.lastRejection != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(c.lastRejection!.message, style: const TextStyle(color: TmColor.error, fontSize: 15)),
          ),
      ],
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({required this.label, required this.background, required this.foreground, required this.onPressed});

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        minimumSize: const Size(0, TmTouch.primaryTarget),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}
