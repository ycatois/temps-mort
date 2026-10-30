import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/store.dart';
import '../../data/tactic_play.dart';
import '../../domain/domain.dart';
import '../common/labels.dart';
import '../common/store_scope.dart';
import '../common/widgets.dart';
import '../theme/tokens.dart';
import 'tactics_board.dart';

/// E08 — Tableau tactique. Tablette : outils à gauche, terrain, schémas enregistrés à droite ;
/// smartphone : terrain, puis barre d'outils en bas. Maquettes : design/maquettes/Tablette-Tactique.dc.html
/// et Mobile-Tactique.dc.html.
///
/// Ouvert depuis le match, les pions sont placés sur la rotation en cours ([lineup], index 0 = poste 1) ;
/// depuis l'équipe, sur la composition type.
///
/// E09 — Temps mort : le même écran, ouvert par le bouton « Temps mort » du match, avec le chrono
/// ([timeoutSeconds]) et les trois chiffres clés du set ([setStats]).
class TacticsScreen extends StatefulWidget {
  const TacticsScreen({
    super.key,
    required this.team,
    this.lineup = const [],
    this.liberoId,
    this.rotation,
    this.serving,
    this.score,
    this.setStats,
    this.timeoutSeconds,
  });

  /// L'équipe dans le format joué.
  final Team team;
  final List<String> lineup;
  final String? liberoId;

  /// Rotation en cours (R1..Rn) et service, quand le tableau est ouvert depuis le match.
  final int? rotation;
  final bool? serving;

  /// Score du set, ex. « 18 – 15 ».
  final String? score;

  /// Statistiques du set en cours : side-out, break et fautes directes (V1-TMO-01).
  final MatchStats? setStats;

  /// Durée du temps mort à décompter (V1-TMO-02) ; null hors temps mort.
  final int? timeoutSeconds;

  @override
  State<TacticsScreen> createState() => _TacticsScreenState();
}

class _TacticsScreenState extends State<TacticsScreen> {
  late TacticBoard _board = TacticBoard.forLineup(widget.team.format, widget.lineup);
  TacticsTool _tool = TacticsTool.move;
  StrokeColor _color = StrokeColor.yellow;

  /// Terrain entier ou demi-terrain (V1-TAC-09) ; null = selon l'écran (entier sur tablette).
  bool? _full;

  AppStore? _store;
  List<TacticPlay> _plays = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_store == null) {
      _store = StoreScope.maybeOf(context);
      _loadPlays();
    }
  }

  Future<void> _loadPlays() async {
    final store = _store;
    if (store == null) return;
    final plays = await store.plays(widget.team.id);
    if (mounted) setState(() => _plays = [for (final p in plays) if (p.board.format == widget.team.format) p]);
  }

  void _set(TacticBoard board) => setState(() => _board = board);
  void _setTool(TacticsTool tool) => setState(() => _tool = tool);
  void _setColor(StrokeColor color) => setState(() => _color = color);

  String get _title {
    final r = widget.rotation;
    if (r == null) return 'Tableau tactique';
    final phase = widget.serving == null ? '' : (widget.serving! ? ' au service' : ' en réception');
    return 'Tableau tactique · rotation $r$phase';
  }

  String get _shortTitle => widget.rotation == null ? 'Tactique' : 'Tactique · R${widget.rotation}';

  Future<void> _save() async {
    final store = _store;
    if (store == null) return;
    final r = widget.rotation;
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(initial: r == null ? '' : 'Rotation $r${widget.serving == false ? ' en réception' : ''}'),
    );
    if (name == null || name.trim().isEmpty) return;
    await store.savePlay(
        TacticPlay(id: newId(), teamId: widget.team.id, name: name.trim(), savedAt: DateTime.now(), board: _board));
    await _loadPlays();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Schéma « ${name.trim()} » enregistré')));
  }

  Future<void> _delete(TacticPlay play) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer « ${play.name} » ?'),
        content: const Text('Le schéma sera retiré de la bibliothèque de l\'équipe.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: TmColor.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _store?.deletePlay(play.id);
    await _loadPlays();
  }

  void _replace() => _set(_board.withLineup(widget.lineup));

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final tablet = box.maxWidth >= tabletWidth;
      final full = _full ?? tablet;
      // Le choix de vue au-dessus du terrain, pas par-dessus : il ne cache jamais un pion.
      final board = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: _ViewToggle(full: full, onChanged: (v) => setState(() => _full = v)),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TacticsBoardView(
              board: _board,
              team: widget.team,
              liberoId: widget.liberoId,
              full: full,
              tool: _tool,
              color: _color,
              onChanged: _set,
            ),
          ),
        ],
      );
      final library = _Library(
        plays: _plays,
        canSave: _store != null,
        onReplace: widget.lineup.isEmpty ? null : _replace,
        onLoad: (p) => _set(p.board),
        onDelete: _delete,
        onSave: _save,
      );

      return Scaffold(
        backgroundColor: TmColor.groundApp,
        appBar: AppBar(
          toolbarHeight: tablet ? 72 : 60,
          title: Text(tablet ? _title : _shortTitle,
              style: const TextStyle(fontFamily: TmFont.display, fontWeight: FontWeight.w700, fontSize: 26)),
          actions: [
            if (widget.timeoutSeconds != null && !tablet)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TimeoutClock(seconds: widget.timeoutSeconds!, compact: true),
              ),
            if (widget.score != null)
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Text(widget.score!,
                    style: const TextStyle(
                        fontFamily: TmFont.display, fontWeight: FontWeight.w700, fontSize: 26, color: Colors.white)),
              ),
            if (widget.timeoutSeconds != null && tablet)
              Padding(padding: const EdgeInsets.only(right: 24), child: TimeoutClock(seconds: widget.timeoutSeconds!)),
          ],
        ),
        body: SafeArea(
          top: false,
          child: tablet
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: 84, child: _ToolRail(state: this)),
                      const SizedBox(width: 16),
                      Expanded(child: board),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 300,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (widget.setStats != null) ...[_KeyFigures(stats: widget.setStats!), const SizedBox(height: 12)],
                            Expanded(child: TmCard(child: Expanded(child: library))),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.setStats != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: _KeyFigures(stats: widget.setStats!, compact: true),
                      ),
                    Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 10), child: board)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(minimumSize: const Size(0, TmTouch.minTarget)),
                              onPressed: () => showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                showDragHandle: true,
                                builder: (sheet) => SafeArea(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                    child: _Library(
                                      plays: _plays,
                                      canSave: _store != null,
                                      shrinkWrap: true,
                                      onReplace: widget.lineup.isEmpty
                                          ? null
                                          : () {
                                              Navigator.pop(sheet);
                                              _replace();
                                            },
                                      onLoad: (p) {
                                        Navigator.pop(sheet);
                                        _set(p.board);
                                      },
                                      onDelete: (p) async {
                                        Navigator.pop(sheet);
                                        await _delete(p);
                                      },
                                      onSave: () {
                                        Navigator.pop(sheet);
                                        _save();
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              child: Text('Schémas enregistrés · ${_plays.length}'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _AddMenu(state: this),
                        ],
                      ),
                    ),
                    _ToolBar(state: this),
                  ],
                ),
        ),
      );
    });
  }
}

/// Bouton d'outil carré : fond navy quand il est choisi (et annoncé « sélectionné »).
class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.icon, required this.label, required this.onPressed, this.selected = false, this.danger = false, this.size});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool selected;
  final bool danger;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : (danger ? TmColor.error : TmColor.navy);
    return Semantics(
      selected: selected,
      button: true,
      child: Tooltip(
        message: label,
        child: SizedBox(
          width: size,
          height: size ?? 52,
          child: Material(
            color: selected ? TmColor.navy : (danger ? Colors.white : TmColor.surfaceAlt),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TmRadius.md),
              side: danger ? const BorderSide(color: TmColor.error, width: 2) : BorderSide.none,
            ),
            child: InkWell(
              customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TmRadius.md)),
              onTap: onPressed,
              child: Icon(icon, color: onPressed == null ? TmColor.muted : fg, size: 26),
            ),
          ),
        ),
      ),
    );
  }
}

const _toolIcons = {
  TacticsTool.move: (Icons.open_with, 'Déplacer les pions'),
  TacticsTool.pen: (Icons.edit, 'Crayon'),
  TacticsTool.arrow: (Icons.north_east, 'Flèche'),
  TacticsTool.zone: (Icons.crop_square, 'Zone'),
};

String _colorName(StrokeColor c) => switch (c) {
      StrokeColor.yellow => 'jaune',
      StrokeColor.red => 'rouge',
      StrokeColor.white => 'blanche',
    };

/// Pastille de couleur : le choix en cours porte une coche, pas seulement une bordure.
class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color, required this.selected, required this.onTap});

  final StrokeColor color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = strokeColor(color);
    return Semantics(
      button: true,
      selected: selected,
      label: 'Couleur ${_colorName(color)}',
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: TmTouch.minTarget / 2,
        child: Container(
          width: TmTouch.minTarget,
          height: TmTouch.minTarget,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: selected ? TmColor.navy : TmColor.line, width: selected ? 3 : 2),
          ),
          child: selected ? Icon(Icons.check, color: color == StrokeColor.red ? Colors.white : TmColor.navy) : null,
        ),
      ),
    );
  }
}

/// Tablette : barre d'outils verticale.
class _ToolRail extends StatelessWidget {
  const _ToolRail({required this.state});
  final _TacticsScreenState state;

  @override
  Widget build(BuildContext context) {
    final s = state;
    return Container(
      decoration: BoxDecoration(
        color: TmColor.surface,
        border: Border.all(color: TmColor.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  for (final t in TacticsTool.values) ...[
                    _ToolButton(
                      size: 56,
                      icon: _toolIcons[t]!.$1,
                      label: _toolIcons[t]!.$2,
                      selected: s._tool == t,
                      onPressed: () => s._setTool(t),
                    ),
                    const SizedBox(height: 8),
                  ],
                  _ToolButton(
                    size: 56,
                    icon: Icons.sports_volleyball,
                    label: 'Ajouter un ballon',
                    onPressed: s._board.hasBall ? null : () => s._set(s._board.addBall()),
                  ),
                  const SizedBox(height: 8),
                  _ToolButton(
                    size: 56,
                    icon: Icons.person_add_alt,
                    label: 'Ajouter un adversaire',
                    onPressed: s._board.canAddOpponent ? () => s._set(s._board.addOpponent()) : null,
                  ),
                  const Divider(height: 20),
                  for (final c in StrokeColor.values) ...[
                    _ColorDot(color: c, selected: s._color == c, onTap: () => s._setColor(c)),
                    const SizedBox(height: 6),
                  ],
                  const Spacer(),
                  const SizedBox(height: 8),
                  _ToolButton(
                    size: 56,
                    icon: Icons.undo,
                    label: 'Annuler le dernier trait',
                    onPressed: s._board.strokes.isEmpty ? null : () => s._set(s._board.undoStroke()),
                  ),
                  const SizedBox(height: 8),
                  _ToolButton(
                    size: 56,
                    icon: Icons.delete_outline,
                    label: 'Tout effacer',
                    danger: true,
                    onPressed: s._board.isBlank ? null : () => s._set(s._board.clear()),
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

/// Smartphone : barre d'outils en bas ; la couleur change à chaque toucher.
class _ToolBar extends StatelessWidget {
  const _ToolBar({required this.state});
  final _TacticsScreenState state;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final next = StrokeColor.values[(s._color.index + 1) % StrokeColor.values.length];
    final items = <Widget>[
      for (final t in TacticsTool.values)
        _ToolButton(
          icon: _toolIcons[t]!.$1,
          label: _toolIcons[t]!.$2,
          selected: s._tool == t,
          onPressed: () => s._setTool(t),
        ),
      Semantics(
        button: true,
        label: 'Couleur ${_colorName(s._color)}, toucher pour passer en ${_colorName(next)}',
        excludeSemantics: true,
        child: Material(
          color: TmColor.surfaceAlt,
          borderRadius: BorderRadius.circular(TmRadius.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(TmRadius.md),
            onTap: () => s._setColor(next),
            child: SizedBox(
              height: 52,
              child: Center(
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: strokeColor(s._color),
                    shape: BoxShape.circle,
                    border: Border.all(color: TmColor.navy, width: 2),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      _ToolButton(
        icon: Icons.undo,
        label: 'Annuler le dernier trait',
        onPressed: s._board.strokes.isEmpty ? null : () => s._set(s._board.undoStroke()),
      ),
      _ToolButton(
        icon: Icons.delete_outline,
        label: 'Tout effacer',
        danger: true,
        onPressed: s._board.isBlank ? null : () => s._set(s._board.clear()),
      ),
    ];
    return Container(
      decoration: const BoxDecoration(color: TmColor.surface, border: Border(top: BorderSide(color: TmColor.line))),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(child: items[i]),
          ],
        ],
      ),
    );
  }
}

/// Smartphone : ballon et adversaires, rangés dans un menu faute de place dans la barre.
class _AddMenu extends StatelessWidget {
  const _AddMenu({required this.state});
  final _TacticsScreenState state;

  @override
  Widget build(BuildContext context) {
    final s = state;
    return PopupMenuButton<String>(
      tooltip: 'Ajouter un ballon ou un adversaire',
      onSelected: (v) => s._set(v == 'ball' ? s._board.addBall() : s._board.addOpponent()),
      itemBuilder: (_) => [
        PopupMenuItem(value: 'ball', enabled: !s._board.hasBall, child: const Text('Ajouter un ballon')),
        PopupMenuItem(value: 'opponent', enabled: s._board.canAddOpponent, child: const Text('Ajouter un adversaire')),
      ],
      child: Container(
        width: TmTouch.minTarget,
        height: TmTouch.minTarget,
        decoration: BoxDecoration(
          border: Border.all(color: TmColor.navy, width: 2),
          borderRadius: BorderRadius.circular(TmRadius.sm),
        ),
        child: const Icon(Icons.add, color: TmColor.navy),
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.full, required this.onChanged});
  final bool full;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: SegmentedButton<bool>(
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: TmColor.navy,
          selectedForegroundColor: Colors.white,
          minimumSize: const Size(0, TmTouch.minTarget),
        ),
        segments: const [
          ButtonSegment(value: false, label: Text('Demi-terrain')),
          ButtonSegment(value: true, label: Text('Terrain entier')),
        ],
        selected: {full},
        onSelectionChanged: (v) => onChanged(v.single),
      ),
    );
  }
}

/// Schémas enregistrés de l'équipe (V1-TAC-07).
class _Library extends StatelessWidget {
  const _Library({
    required this.plays,
    required this.canSave,
    required this.onReplace,
    required this.onLoad,
    required this.onDelete,
    required this.onSave,
    this.shrinkWrap = false,
  });

  final List<TacticPlay> plays;
  final bool canSave;
  final VoidCallback? onReplace;
  final ValueChanged<TacticPlay> onLoad;
  final ValueChanged<TacticPlay> onDelete;
  final VoidCallback onSave;

  /// Dans une feuille du bas : hauteur selon le contenu.
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final list = plays.isEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              canSave ? 'Aucun schéma pour l\'instant. Placez les pions, dessinez, puis enregistrez.' : 'Bibliothèque indisponible.',
              style: const TextStyle(color: TmColor.muted, fontSize: 15),
            ),
          )
        : ListView.separated(
            shrinkWrap: shrinkWrap,
            itemCount: plays.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final p = plays[i];
              return Material(
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: TmColor.line),
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  minTileHeight: TmTouch.minTarget,
                  contentPadding: const EdgeInsets.only(left: 12),
                  title: Text(p.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: Text('Enregistré le ${formatDate(p.savedAt)}', style: const TextStyle(fontSize: 13, color: TmColor.muted)),
                  onTap: () => onLoad(p),
                  trailing: IconButton(
                    tooltip: 'Supprimer « ${p.name} »',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => onDelete(p),
                  ),
                ),
              );
            },
          );
    return Column(
      mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Schémas enregistrés', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (onReplace != null) ...[
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
            onPressed: onReplace,
            child: const Text('Replacer sur la rotation du match', textAlign: TextAlign.center),
          ),
          const SizedBox(height: 12),
        ],
        if (shrinkWrap) Flexible(child: list) else Expanded(child: list),
        const SizedBox(height: 12),
        OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
          onPressed: canSave ? onSave : null,
          child: const Text('Enregistrer ce schéma'),
        ),
      ],
    );
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});
  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enregistrer ce schéma'),
      content: TextField(
        controller: _text,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(labelText: 'Nom du schéma', hintText: 'ex. Couverture d\'attaque zone 4'),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(onPressed: () => Navigator.pop(context, _text.text), child: const Text('Enregistrer')),
      ],
    );
  }
}

/// Chrono du temps mort (V1-TMO-02) : décompte, puis « reprise » en toutes lettres (pas seulement
/// un changement de couleur) et une vibration.
class TimeoutClock extends StatefulWidget {
  const TimeoutClock({super.key, required this.seconds, this.compact = false});

  final int seconds;
  final bool compact;

  @override
  State<TimeoutClock> createState() => _TimeoutClockState();
}

class _TimeoutClockState extends State<TimeoutClock> {
  late int _left = widget.seconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _left--);
      if (_left <= 0) {
        t.cancel();
        HapticFeedback.heavyImpact();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final over = _left <= 0;
    final clock = '${_left ~/ 60}:${(_left % 60).toString().padLeft(2, '0')}';
    final text = over
        ? (widget.compact ? 'Reprise' : 'Temps mort · reprise')
        : (widget.compact ? 'TM $clock' : 'Temps mort · $clock');
    return Semantics(
      liveRegion: over,
      label: over ? 'Temps mort terminé, reprise du jeu' : 'Temps mort, $_left secondes',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: widget.compact ? 10 : 12, vertical: widget.compact ? 6 : 8),
        decoration: BoxDecoration(
          color: over ? Colors.white : TmColor.yellow,
          borderRadius: BorderRadius.circular(TmRadius.sm),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: TmColor.navy,
            fontSize: widget.compact ? 14 : 15,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

/// Les trois chiffres du set à dire pendant le temps mort (V1-TMO-01).
class _KeyFigures extends StatelessWidget {
  const _KeyFigures({required this.stats, this.compact = false});

  final MatchStats stats;
  final bool compact;

  static String _percent(double? v) => v == null ? '—' : '${(v * 100).round()}\u202f%';

  @override
  Widget build(BuildContext context) {
    final figures = [
      ('Side-out', _percent(stats.sideOutRate), 'en réception'),
      ('Break', _percent(stats.breakRate), 'au service'),
      ('Fautes', '${stats.teamErrors}', 'directes'),
    ];
    final tiles = [
      for (final (label, value, caption) in figures)
        Expanded(
          child: Semantics(
            label: '$label : $value $caption',
            excludeSemantics: true,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: compact ? 6 : 10, horizontal: 8),
              decoration: BoxDecoration(
                color: TmColor.surface,
                border: Border.all(color: TmColor.line),
                borderRadius: BorderRadius.circular(TmRadius.md),
              ),
              child: Column(
                children: [
                  Text(label.toUpperCase(),
                      style: const TextStyle(color: TmColor.accent, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  Text(value,
                      style: TextStyle(
                          fontFamily: TmFont.display, fontWeight: FontWeight.w700, fontSize: compact ? 24 : 32, height: 1.1)),
                  if (!compact) Text(caption, style: const TextStyle(color: TmColor.muted, fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!compact) ...[
          const Text('Ce set', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
        ],
        // Même hauteur pour les trois tuiles, même si un libellé passe à la ligne.
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (var i = 0; i < tiles.length; i++) ...[if (i > 0) const SizedBox(width: 8), tiles[i]],
          ]),
        ),
      ],
    );
  }
}
