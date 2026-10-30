import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../theme/tokens.dart';
import '../stats/stats_screen.dart';
import '../summary/summary_screen.dart';
import '../tactics/tactics_screen.dart';
import 'match_controller.dart';
import 'substitution_panel.dart';

/// Ouvre l'écran E04 pour composer le set [setNumber] à partir de [suggested] ; null si le coach renonce.
typedef ComposeSet = Future<StartSet?> Function(
  BuildContext context,
  StartSet suggested, {
  required int setNumber,
  required bool serverLocked,
});

/// E05 — Match en direct. Tablette (≥ 840 px de large) : terrain et saisie côte à côte ;
/// smartphone : empilés, avec défilement. Maquettes : design/maquettes/Main.dc.html et Mobile-Match.dc.html.
class MatchScreen extends StatefulWidget {
  const MatchScreen({
    super.key,
    required this.team,
    this.rules,
    required this.events,
    this.onEventsChanged,
    this.composeNextSet,
    this.fullInput = false,
    this.onFullInputChanged,
    this.opponent,
    this.date,
  });

  /// L'équipe dans le format du match.
  final Team team;
  final MatchRules? rules;

  /// Événements déjà saisis (au moins le début du premier set) : un match interrompu reprend où il en était.
  final List<MatchEvent> events;
  final ValueChanged<List<MatchEvent>>? onEventsChanged;

  /// Sans cette fonction, le set suivant ne peut reprendre que la même composition.
  final ComposeSet? composeNextSet;

  /// Mode de saisie au départ, et où enregistrer un changement de mode (V1-STA-11).
  final bool fullInput;
  final ValueChanged<bool>? onFullInputChanged;

  /// Adversaire et date, pour le résumé (E10).
  final String? opponent;
  final DateTime? date;

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  late final MatchController _c = MatchController(
    widget.team,
    rules: widget.rules,
    events: widget.events,
    onEventsChanged: widget.onEventsChanged,
    fullInput: widget.fullInput,
    onFullInputChanged: widget.onFullInputChanged,
  );

  void _openSummary() => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => SummaryScreen(
          team: widget.team,
          rules: widget.rules,
          events: _c.events,
          opponent: widget.opponent,
          date: widget.date,
        ),
      ));

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
                            Expanded(flex: 10, child: SingleChildScrollView(child: _ActionPanel(c: _c, compose: widget.composeNextSet, onSummary: _openSummary))),
                          ],
                        ),
                      );
                    }
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [_Court(c: _c), const SizedBox(height: 12), _ActionPanel(c: _c, compose: widget.composeNextSet, onSummary: _openSummary)],
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

/// Durée d'un temps mort (V1-TMO-02).
const timeoutDuration = 30;

/// E08 sur la rotation en cours ; avec [timeout], E09 : chrono et chiffres clés du set.
void _openTactics(BuildContext context, MatchController c, {bool timeout = false}) {
  final s = c.state;
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => TacticsScreen(
      team: c.team,
      lineup: s.lineup,
      liberoId: s.liberoId,
      rotation: s.lineup.isEmpty ? null : s.rotation,
      serving: s.lineup.isEmpty ? null : s.serving == Side.us,
      score: '${s.score.us} – ${s.score.them}',
      setStats: timeout ? computeStats(s.history, touches: s.touches, setIndex: s.setIndex) : null,
      timeoutSeconds: timeout ? timeoutDuration : null,
    ),
  ));
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
    // E09 : le temps mort est enregistré, puis le tableau tactique s'ouvre avec le chrono.
    final timeout = FilledButton(
      onPressed: s.phase == Phase.inPlay && s.timeoutsLeft(Side.us) > 0
          ? () {
              c.timeout();
              if (c.lastRejection == null) _openTactics(context, c, timeout: true);
            }
          : null,
      style: FilledButton.styleFrom(
        backgroundColor: TmColor.yellow,
        foregroundColor: TmColor.navy,
        minimumSize: const Size(0, TmTouch.minTarget),
      ),
      child: Text('Temps mort ${s.timeoutsUsed.us}/${s.rules.timeoutsPerSet}'),
    );
    // Le match est enregistré à chaque saisie : on peut le quitter et le reprendre depuis la liste des matchs.
    final back = [
      if (Navigator.of(context).canPop())
        IconButton(
          tooltip: 'Quitter le match (il est enregistré)',
          onPressed: () => Navigator.of(context).maybePop(),
          color: TmColor.onNavy,
          constraints: const BoxConstraints.tightFor(width: TmTouch.minTarget, height: TmTouch.minTarget),
          icon: const Icon(Icons.arrow_back),
        ),
    ];

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
                    Row(children: [...back, Expanded(child: info), score]),
                    const SizedBox(height: 8),
                    timeout,
                  ],
                );
              }
              return Row(
                children: [
                  ...back,
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
  const _ActionPanel({required this.c, this.compose, required this.onSummary});
  final MatchController c;
  final ComposeSet? compose;
  final VoidCallback onSummary;

  /// Libellé du bouton E06, ou null quand il n'y a ni remplacement ni libero (2x2).
  String? get _substitutionLabel {
    final s = c.state;
    final limit = s.rules.substitutionsPerSet;
    final libero = s.liberoId != null ? ' · libero' : '';
    if (limit == 0) return libero.isEmpty ? null : 'Libero';
    return limit == null ? 'Remplacement$libero' : 'Remplacement ${s.substitutionsUsed}/$limit$libero';
  }

  /// Ouvre E04 sur la composition du set précédent, puis démarre le set choisi.
  Future<void> _changeLineup(BuildContext context) async {
    final suggested = c.suggestedNextSet;
    if (suggested == null) return;
    final start = await compose!(
      context,
      suggested,
      setNumber: c.state.setIndex + 1,
      serverLocked: !c.nextSetIsDeciding,
    );
    if (start != null) c.startSet(start);
  }

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
        if (s.phase == Phase.finished)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _BigButton(
              label: 'Voir le résumé et le partager',
              background: TmColor.yellow,
              foreground: TmColor.navy,
              onPressed: onSummary,
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
        if (c.canStartNextSet && compose != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, TmTouch.primaryTarget)),
              onPressed: () => _changeLineup(context),
              child: Text('Set ${s.setIndex + 1} : changer la composition'),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: Text(
                selected == null
                    ? "Touchez une joueuse, puis l'action"
                    : "#${selected.number} ${selected.name} : choisir l'action",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(width: 8),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: false, label: Text('Simple')),
                ButtonSegment(value: true, label: Text('Complète')),
              ],
              selected: {c.fullInput},
              onSelectionChanged: (s) => c.setFullInput(s.single),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (c.fullInput)
          _FullInput(c: c, enabled: playing && selected != null)
        else ...[
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
        ],
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
        if (_substitutionLabel != null) ...[
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, TmTouch.primaryTarget)),
            onPressed: playing ? () => showSubstitutionPanel(context, c) : null,
            icon: const Icon(Icons.swap_horiz),
            label: Text(_substitutionLabel!),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, TmTouch.primaryTarget)),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => StatsScreen(c: c))),
          icon: const Icon(Icons.bar_chart),
          label: const Text('Statistiques'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, TmTouch.primaryTarget)),
          onPressed: () => _openTactics(context, c),
          icon: const Icon(Icons.draw_outlined),
          label: const Text('Tableau tactique'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, TmTouch.primaryTarget)),
          onPressed: onSummary,
          icon: const Icon(Icons.summarize_outlined),
          label: const Text('Résumé du match'),
        ),
        const SizedBox(height: 8),
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

/// Saisie complète (V1-STA-02 à 08) : la joueuse, puis son geste, en deux touches. Les gestes qui
/// terminent l'échange donnent le point ; les autres (réception notée, attaque en jeu…) le laissent en jeu.
class _FullInput extends StatelessWidget {
  const _FullInput({required this.c, required this.enabled});

  final MatchController c;
  final bool enabled;

  static const _skills = <(String, List<_Gesture>)>[
    ('Service', [_Gesture.end(RallyAction.ace, 'Ace'), _Gesture.play(TouchKind.serveInPlay), _Gesture.end(RallyAction.serviceFaute, 'Faute')]),
    ('Réception', [
      _Gesture.play(TouchKind.reception3, '3'),
      _Gesture.play(TouchKind.reception2, '2'),
      _Gesture.play(TouchKind.reception1, '1'),
      _Gesture.end(RallyAction.receptionFaute, '0 · ratée'),
    ]),
    ('Attaque', [
      _Gesture.end(RallyAction.attaque, 'Point'),
      _Gesture.play(TouchKind.attackInPlay),
      _Gesture.end(RallyAction.attaqueFaute, 'Faute / contrée'),
    ]),
    ('Contre', [_Gesture.end(RallyAction.contre, 'Point'), _Gesture.play(TouchKind.blockTouch), _Gesture.end(RallyAction.contreFaute, 'Faute')]),
    ('Défense', [_Gesture.play(TouchKind.digOk), _Gesture.end(RallyAction.defenseFaute, 'Ratée')]),
    ('Passe', [_Gesture.end(RallyAction.passeFaute, 'Faute (double, porté)')]),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (skill, gestures) in _skills)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 82,
                  child: Text(skill, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                for (final (i, g) in gestures.indexed) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(child: g.button(c, skill, enabled: enabled)),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// Un geste : soit il termine l'échange ([action]), soit il le laisse en jeu ([touch]).
class _Gesture {
  const _Gesture.end(RallyAction this.action, this.label) : touch = null;
  const _Gesture.play(TouchKind this.touch, [this.label]) : action = null;

  final RallyAction? action;
  final TouchKind? touch;
  final String? label;

  Widget button(MatchController c, String skill, {required bool enabled}) {
    final text = label ?? touch!.label;
    final a = action;
    final t = touch;
    final onPressed = !enabled ? null : (a != null ? () => c.action(a) : () => c.touch(t!));
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, TmTouch.primaryTarget)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 4)),
    );
    final child = Semantics(label: '$skill : $text', excludeSemantics: true, child: Text(text, textAlign: TextAlign.center));
    // Point gagné : plein bleu ; faute : bordure orange ; geste en jeu : neutre. Le libellé dit toujours lequel.
    if (a != null && a.scoring) {
      return FilledButton(
          onPressed: onPressed,
          style: style.merge(FilledButton.styleFrom(backgroundColor: TmColor.accent, foregroundColor: Colors.white)),
          child: child);
    }
    if (a != null) {
      return OutlinedButton(
          onPressed: onPressed,
          style: style.merge(OutlinedButton.styleFrom(side: const BorderSide(color: TmColor.error, width: 2))),
          child: child);
    }
    return FilledButton(
        onPressed: onPressed,
        style: style.merge(FilledButton.styleFrom(backgroundColor: TmColor.surfaceAlt, foregroundColor: TmColor.navy)),
        child: child);
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
