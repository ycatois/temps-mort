import 'package:flutter/material.dart';

import '../../data/match_record.dart';
import '../../domain/domain.dart';
import '../common/labels.dart';
import '../common/store_scope.dart';
import '../common/widgets.dart';
import '../theme/tokens.dart';
import 'composition_draft.dart';

/// E04 — Composition d'un set (V1-PRE-04 à 09). Maquettes : design/maquettes/Tablette-Composition.dc.html
/// et Mobile-Composition.dc.html. On glisse les joueuses du banc sur les zones (ou on touche une joueuse
/// puis une zone), on choisit libero, capitaine, système et premier service. Renvoie le [StartSet] du set.
class CompositionScreen extends StatefulWidget {
  const CompositionScreen({
    super.key,
    required this.team,
    required this.rules,
    required this.match,
    this.setNumber = 1,
    this.initial,
    this.initialServer,
    this.serverLocked = false,
  });

  /// L'équipe dans le format du match.
  final Team team;
  final MatchRules rules;
  final MatchRecord match;
  final int setNumber;

  /// Composition proposée (celle du set précédent), ou null pour partir d'un terrain vide.
  final StartSet? initial;
  final Side? initialServer;

  /// Sets 2 et suivants (hors set décisif) : le premier service alterne, le coach ne le choisit pas.
  final bool serverLocked;

  @override
  State<CompositionScreen> createState() => _CompositionScreenState();
}

class _CompositionScreenState extends State<CompositionScreen> {
  late final CompositionDraft _draft =
      CompositionDraft(widget.team.format.playersOnCourt, lineup: widget.initial?.lineup);
  late String? _liberoId = widget.initial?.liberoId;
  late String? _captainId = widget.initial?.captainId;
  late GameSystem? _system = _sixes ? (widget.initial?.system ?? GameSystem.s51) : null;
  late Side? _firstServer = widget.initialServer;
  LineupTemplate? _template;

  /// Joueuse touchée, en attente d'une zone (banc ou terrain).
  String? _picked;

  Team get _team => widget.team;
  bool get _sixes => widget.team.format == GameFormat.six;
  bool get _liberoPossible => _sixes && widget.rules.liberoAllowed;
  List<LineupIssue> get _issues =>
      _draft.complete ? validateLineup(_team, _draft.lineup, liberoId: _liberoId) : const [];
  List<LineupWarning> get _warnings => _draft.complete ? lineupWarnings(_team, _draft.lineup, _system) : const [];
  bool get _canStart => _draft.complete && _firstServer != null && _issues.isEmpty;

  @override
  void initState() {
    super.initState();
    StoreScope.of(context).lineupTemplate(_team.id, _team.format).then((t) {
      if (mounted) setState(() => _template = t);
    });
  }

  void _place(String id, int slot) => setState(() {
        _draft.place(id, slot);
        if (_liberoId == id) _liberoId = null;
        // L'occupante renvoyée sur le banc perd le capitanat.
        if (_captainId != null && !_draft.onCourt(_captainId!)) _captainId = null;
        _picked = null;
      });

  void _toBench(String id) => setState(() {
        _draft.remove(id);
        if (_captainId == id) _captainId = null;
        _picked = null;
      });

  void _tapZone(int slot) {
    final picked = _picked;
    if (picked != null) {
      _place(picked, slot);
    } else if (_draft.slots[slot] != null) {
      setState(() => _picked = _draft.slots[slot]);
    }
  }

  void _loadTemplate() {
    final t = _template!;
    final active = {for (final p in _team.activePlayers) p.id};
    setState(() {
      _draft.load(t.lineup, active.contains);
      _liberoId = t.liberoId != null && active.contains(t.liberoId) && !_draft.onCourt(t.liberoId!) ? t.liberoId : null;
      _captainId = t.captainId != null && _draft.onCourt(t.captainId!) ? t.captainId : null;
      if (_sixes) _system = t.system ?? _system;
      _picked = null;
    });
  }

  Future<void> _saveTemplate() async {
    final t = LineupTemplate(
      teamId: _team.id,
      format: _team.format,
      lineup: _draft.lineup,
      liberoId: _liberoId,
      captainId: _captainId,
      system: _system,
    );
    await StoreScope.of(context).saveLineupTemplate(t);
    if (!mounted) return;
    setState(() => _template = t);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Composition type enregistrée')));
  }

  void _start() => Navigator.of(context).pop(StartSet(
        _firstServer!,
        _draft.lineup,
        liberoId: _liberoId,
        captainId: _captainId,
        system: _system,
      ));

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final tablet = box.maxWidth >= tabletWidth;
      final startLabel = 'Commencer le set ${widget.setNumber}';
      final m = widget.match;
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: 76,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${formatLongDate(m.date)} · ${formatTime(m.date)} · ${m.home ? 'Domicile' : 'Extérieur'}'
                    .toUpperCase(),
                style: const TextStyle(
                    fontSize: 13, color: TmColor.onNavyMuted, fontWeight: FontWeight.w600, letterSpacing: .8),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                tablet
                    ? 'Composition du set ${widget.setNumber} · contre ${m.opponent}'
                    : 'Composition · set ${widget.setNumber}',
                style: const TextStyle(fontFamily: TmFont.display, fontWeight: FontWeight.w700, fontSize: 28),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            if (tablet)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: YellowButton(label: startLabel, onPressed: _canStart ? _start : null),
              ),
          ],
        ),
        bottomNavigationBar: tablet
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: YellowButton(label: startLabel, onPressed: _canStart ? _start : null),
                ),
              ),
        body: tablet ? _tabletBody() : _phoneBody(),
      );
    });
  }

  Widget _tabletBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_sixes) Padding(padding: const EdgeInsets.fromLTRB(24, 14, 24, 0), child: _systemPicker()),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 540,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [_court(tokenSize: 84), const SizedBox(height: 12), ..._banners()],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(child: SingleChildScrollView(child: _benchCard(tablet: true))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Smartphone : le terrain et les bandeaux d'état restent fixes en haut, seul le banc défile dessous,
  /// pour toucher une joueuse puis sa zone sans faire défiler l'écran ni perdre une alerte de vue.
  Widget _phoneBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sur un petit écran, la partie fixe défile elle-même plutôt que de déborder.
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .62),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_sixes) ...[_systemPicker(), const SizedBox(height: 10)],
                _court(tokenSize: _sixes ? 60 : 64),
                const SizedBox(height: 8),
                ..._banners(),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            children: [_benchCard(tablet: false)],
          ),
        ),
      ],
    );
  }

  Widget _systemPicker() {
    return Row(
      children: [
        const Text(
          'SYSTÈME',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1, color: TmColor.muted),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: SegmentedButton<GameSystem>(
            segments: [for (final s in GameSystem.values) ButtonSegment(value: s, label: Text(s.label))],
            selected: {_system!},
            onSelectionChanged: (s) => setState(() => _system = s.single),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Terrain
  // ---------------------------------------------------------------------------

  Widget _court({required double tokenSize}) {
    // Avant (4 3 2) en haut, contre le filet ; arrière (5 6 1) en bas. Index 0 = poste 1.
    final rows = switch (_draft.slots.length) {
      6 => const [
          [3, 2, 1],
          [4, 5, 0],
        ],
      4 => const [
          [2, 1],
          [3, 0],
        ],
      _ => [List.generate(_draft.slots.length, (i) => i)],
    };
    return Semantics(
      label: 'Terrain : ${_draft.slots.length} zones',
      container: true,
      child: Container(
        decoration: BoxDecoration(color: TmColor.courtOut, borderRadius: BorderRadius.circular(TmRadius.lg)),
        padding: const EdgeInsets.fromLTRB(28, 14, 28, 14),
        child: Container(
          decoration: const BoxDecoration(
            color: TmColor.court,
            // Le filet en haut, plus épais que les lignes.
            border: Border(
              top: BorderSide(color: Colors.white, width: 6),
              left: BorderSide(color: Colors.white, width: 3),
              right: BorderSide(color: Colors.white, width: 3),
              bottom: BorderSide(color: Colors.white, width: 3),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              for (final (n, row) in rows.indexed) ...[
                // Ligne d'attaque entre l'avant et l'arrière.
                if (n > 0)
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(color: Colors.white, thickness: 3, height: 3)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [for (final i in row) _zone(i, tokenSize)],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _zone(int slot, double size) {
    final id = _draft.slots[slot];
    final p = id == null ? null : _team.player(id);
    final serving = slot == 0 && _firstServer == Side.us;
    final mixed = _team.gender == TeamGender.mixte;
    final caption = [
      if (mixed && p != null) p.gender == PlayerGender.f ? 'F' : 'H',
      zoneName(_team.format, slot),
      if (p != null && !mixed) roleShort(p.role, p.gender),
      if (p == null) 'à placer',
      if (serving && _team.format != GameFormat.two) 'sert',
    ].join(' · ');

    return DragTarget<String>(
      onWillAcceptWithDetails: (d) => d.data != id,
      onAcceptWithDetails: (d) => _place(d.data, slot),
      builder: (context, candidates, _) {
        final hovering = candidates.isNotEmpty;
        final token = p == null
            ? _EmptyToken(size: size, highlighted: hovering || _picked != null)
            : _PlayerToken(
                player: p,
                size: size,
                captain: p.id == _captainId,
                serving: serving,
                picked: p.id == _picked,
              );
        final body = SizedBox(
          width: size + 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              token,
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                child: Text(
                  caption,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: TmColor.navy),
                ),
              ),
            ],
          ),
        );
        final semantics = p == null
            ? '$caption, vide${_picked != null ? '. Toucher pour placer la joueuse choisie' : ''}'
            : '$caption : ${p.firstName}, numéro ${p.number}${p.id == _captainId ? ', capitaine' : ''}';
        final tappable = Semantics(
          button: true,
          label: semantics,
          excludeSemantics: true,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => _tapZone(slot), child: body),
        );
        if (p == null) return tappable;
        return _draggable(
            p.id, _PlayerToken(player: p, size: size, captain: false, serving: false, picked: false), tappable);
      },
    );
  }

  /// Tablette : on glisse directement. Smartphone : appui long, pour ne pas gêner le défilement.
  Widget _draggable(String id, Widget feedback, Widget child) {
    final tablet = MediaQuery.sizeOf(context).width >= tabletWidth;
    final f = Material(color: Colors.transparent, child: feedback);
    final ghost = Opacity(opacity: .35, child: child);
    return tablet
        ? Draggable<String>(data: id, feedback: f, childWhenDragging: ghost, child: child)
        : LongPressDraggable<String>(data: id, feedback: f, childWhenDragging: ghost, child: child);
  }

  // ---------------------------------------------------------------------------
  // Bandeaux d'état
  // ---------------------------------------------------------------------------

  List<Widget> _banners() {
    final word = playerWord(_team);
    final banners = <Widget>[];
    void warn(String text) => banners.add(_Banner(text: text, ok: false));

    final picked = _picked == null ? null : _team.player(_picked!);
    if (picked != null) {
      banners.add(_Banner(
        text: _draft.onCourt(picked.id)
            ? '${picked.firstName} choisie : touchez une autre zone pour l\'y déplacer, ou renvoyez-la sur le banc.'
            : '${picked.firstName} choisie : touchez une zone pour la placer.',
        ok: true,
      ));
    }
    final empty = _draft.emptySlots;
    if (empty.length == _draft.slots.length) {
      warn('Glissez les ${word}s du banc sur les zones, ou touchez une $word puis une zone.');
    } else if (empty.isNotEmpty) {
      final names = [for (final i in empty) zoneName(_team.format, i)];
      final list =
          names.length == 1 ? names.single : '${names.sublist(0, names.length - 1).join(', ')} et ${names.last}';
      warn('$list ${names.length == 1 ? 'vide' : 'vides'}. Placez une $word pour lancer le set.');
    }
    for (final issue in _issues) {
      warn(lineupIssueLabel(issue));
    }
    for (final w in _warnings) {
      warn('${lineupWarningLabel(w, _team)} Vous pouvez quand même commencer.');
    }
    if (_draft.complete && _issues.isEmpty && _team.gender == TeamGender.mixte) {
      final women = _draft.lineup.where((id) => _team.player(id)?.gender == PlayerGender.f).length;
      banners.add(_Banner(
        text:
            'Mixité respectée : $women ${women > 1 ? 'femmes' : 'femme'} sur le terrain, minimum requis ${_team.minWomenOnCourt}.',
        ok: true,
        strong: 'Mixité respectée',
      ));
    }
    if (_firstServer == null) warn('Choisissez qui sert en premier.');
    return [
      for (final (i, b) in banners.indexed) ...[if (i > 0) const SizedBox(height: 8), b],
    ];
  }

  // ---------------------------------------------------------------------------
  // Banc et réglages
  // ---------------------------------------------------------------------------

  Widget _benchCard({required bool tablet}) {
    final bench = _team.activePlayers.where((p) => !_draft.onCourt(p.id)).toList()
      ..sort((a, b) => a.number.compareTo(b.number));
    final picked = _picked;
    final pickedOnCourt = picked != null && _draft.onCourt(picked);
    final word = playerWord(_team);

    final list = bench.isEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('Tout l\'effectif est sur le terrain.', style: Theme.of(context).textTheme.bodyMedium),
          )
        : LayoutBuilder(builder: (context, box) {
            final columns = box.maxWidth >= 480 ? 2 : 1;
            final width = (box.maxWidth - (columns - 1) * 10) / columns;
            return Wrap(
              spacing: 10,
              runSpacing: tablet ? 10 : 6,
              children: [
                for (final p in bench)
                  SizedBox(
                    width: width,
                    child: _draggable(
                      p.id,
                      _PlayerToken(player: p, size: 68, captain: false, serving: false, picked: false),
                      _BenchCard(
                        team: _team,
                        player: p,
                        isLibero: p.id == _liberoId,
                        picked: p.id == picked,
                        compact: !tablet,
                        onTap: () => setState(() => _picked = _picked == p.id ? null : p.id),
                      ),
                    ),
                  ),
              ],
            );
          });

    return DragTarget<String>(
      onWillAcceptWithDetails: (d) => _draft.onCourt(d.data),
      onAcceptWithDetails: (d) => _toBench(d.data),
      builder: (context, candidates, _) => Container(
        decoration: BoxDecoration(
          color: TmColor.surface,
          border: Border.all(
              color: candidates.isNotEmpty ? TmColor.accent : TmColor.line, width: candidates.isNotEmpty ? 3 : 1),
          borderRadius: BorderRadius.circular(TmRadius.lg),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 4,
              children: [
                Text('Banc · ${bench.length}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                Text(
                  tablet ? 'Glissez une $word sur une zone' : 'Touchez une $word puis une zone',
                  style: const TextStyle(fontSize: 14, color: TmColor.muted),
                ),
              ],
            ),
            if (pickedOnCourt) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _toBench(picked),
                icon: const Icon(Icons.arrow_downward),
                label: Text('Renvoyer ${_team.player(picked)!.firstName} sur le banc'),
              ),
            ],
            const SizedBox(height: 14),
            list,
            const SizedBox(height: 14),
            const Divider(color: TmColor.line, height: 1),
            const SizedBox(height: 14),
            _settings(bench),
          ],
        ),
      ),
    );
  }

  Widget _settings(List<Player> bench) {
    final onCourt = [
      for (final id in _draft.slots)
        if (id != null) _team.player(id)!
    ];
    final items = <Widget>[
      if (_liberoPossible)
        _Setting(
          label: 'Libero',
          child: DropdownButton<String?>(
            value: _liberoId,
            isExpanded: true,
            items: [
              const DropdownMenuItem(value: null, child: Text('Aucune')),
              for (final p in bench) DropdownMenuItem(value: p.id, child: Text('#${p.number} ${p.firstName}')),
            ],
            onChanged: (id) => setState(() => _liberoId = id),
          ),
        ),
      _Setting(
        label: 'Capitaine',
        child: DropdownButton<String?>(
          value: _captainId,
          isExpanded: true,
          hint: const Text('Sur le terrain'),
          items: [
            const DropdownMenuItem(value: null, child: Text('Non désignée')),
            for (final p in onCourt) DropdownMenuItem(value: p.id, child: Text('#${p.number} ${p.firstName}')),
          ],
          onChanged: (id) => setState(() => _captainId = id),
        ),
      ),
      _Setting(
        label: 'Premier service',
        child: widget.serverLocked
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '${_firstServer == Side.us ? 'Nous' : 'Adversaire'} (alternance)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              )
            : SegmentedButton<Side>(
                emptySelectionAllowed: true,
                segments: const [
                  ButtonSegment(value: Side.us, label: Text('Nous')),
                  ButtonSegment(value: Side.them, label: Text('Adversaire')),
                ],
                selected: _firstServer == null ? const {} : {_firstServer!},
                onSelectionChanged: (s) => setState(() => _firstServer = s.isEmpty ? null : s.single),
              ),
      ),
      _Setting(
        label: 'Modèle',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_template != null)
              OutlinedButton(
                onPressed: _loadTemplate,
                child: Text(
                  _template!.system == null
                      ? 'Charger la compo type'
                      : 'Charger « Compo type ${_template!.system!.label} »',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (_template != null) const SizedBox(height: 6),
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(0, TmTouch.minTarget)),
              onPressed: _draft.complete ? _saveTemplate : null,
              child: const Text('Enregistrer comme compo type'),
            ),
          ],
        ),
      ),
    ];
    return LayoutBuilder(builder: (context, box) {
      final columns = box.maxWidth >= 480 ? 2 : 1;
      final width = (box.maxWidth - (columns - 1) * 16) / columns;
      return Wrap(
        spacing: 16,
        runSpacing: 14,
        children: [for (final item in items) SizedBox(width: width, child: item)],
      );
    });
  }
}

// -----------------------------------------------------------------------------
// Petits éléments
// -----------------------------------------------------------------------------

class _PlayerToken extends StatelessWidget {
  const _PlayerToken(
      {required this.player, required this.size, required this.captain, required this.serving, required this.picked});

  final Player player;
  final double size;
  final bool captain;
  final bool serving;
  final bool picked;

  @override
  Widget build(BuildContext context) {
    final ring = picked
        ? const BorderSide(color: TmColor.accent, width: 4)
        : BorderSide(color: serving ? TmColor.yellow : Colors.white, width: 3);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: TmColor.navy, shape: BoxShape.circle, border: Border.fromBorderSide(ring)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${player.number}',
            style: TextStyle(
                fontFamily: TmFont.display,
                fontWeight: FontWeight.w700,
                fontSize: size / 3,
                color: Colors.white,
                height: 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              captain ? '${player.firstName} (C)' : player.firstName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: size > 72 ? 14 : 12, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyToken extends StatelessWidget {
  const _EmptyToken({required this.size, required this.highlighted});

  final double size;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedCircle(color: TmColor.navy, width: highlighted ? 4 : 3),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            highlighted ? 'Ici' : 'Déposer',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: TmColor.navy),
          ),
        ),
      ),
    );
  }
}

/// Cercle en pointillés : zone vide en attente d'une joueuse.
class _DashedCircle extends CustomPainter {
  const _DashedCircle({required this.color, required this.width});

  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    final rect = Offset(width / 2, width / 2) & Size(size.width - width, size.height - width);
    const dashes = 24;
    const sweep = 2 * 3.141592653589793 / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect, i * sweep, sweep * .55, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedCircle old) => old.color != color || old.width != width;
}

class _BenchCard extends StatelessWidget {
  const _BenchCard({
    required this.team,
    required this.player,
    required this.isLibero,
    required this.picked,
    required this.compact,
    required this.onTap,
  });

  final Team team;
  final Player player;
  final bool isLibero;
  final bool picked;

  /// Smartphone : une ligne de 48 dp (prénom seul), pour garder banc et terrain sur le même écran.
  /// Tablette : 56 dp avec le poste et la poignée de glissement.
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mixed = team.gender == TeamGender.mixte;
    return Semantics(
      button: true,
      selected: picked,
      label: '${player.firstName}, numéro ${player.number}, ${roleLabel(player.role, player.gender)}'
          '${isLibero ? ', libero du set' : ''}${picked ? ', choisie' : ''}',
      excludeSemantics: true,
      child: Material(
        color: TmColor.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: picked ? TmColor.accent : TmColor.line, width: picked ? 3 : 1),
          borderRadius: BorderRadius.circular(TmRadius.md),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(TmRadius.md),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: compact ? TmTouch.minTarget : TmTouch.primaryTarget),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12, vertical: compact ? 4 : 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: compact ? 18 : 21,
                    backgroundColor: TmColor.groundApp,
                    child: Text(
                      '${player.number}',
                      style: const TextStyle(
                          fontFamily: TmFont.display, fontWeight: FontWeight.w700, fontSize: 22, color: TmColor.navy),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(player.firstName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        if (!compact || isLibero)
                          Text(
                            isLibero ? 'Libero du set' : roleLabel(player.role, player.gender),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, color: TmColor.muted),
                          ),
                      ],
                    ),
                  ),
                  if (mixed) _Tag(player.gender == PlayerGender.f ? 'F' : 'H'),
                  if (picked) const Icon(Icons.check_circle, color: TmColor.accent),
                  if (!compact && !picked) const Icon(Icons.drag_indicator, color: TmColor.muted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(border: Border.all(color: TmColor.line), borderRadius: BorderRadius.circular(6)),
        child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: TmColor.muted)),
      );
}

class _Setting extends StatelessWidget {
  const _Setting({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1, color: TmColor.muted),
          ),
          const SizedBox(height: 4),
          child,
        ],
      );
}

/// Bandeau d'état sous le terrain : alerte (jaune) ou tout va bien (bleu), toujours avec une icône
/// et un texte, jamais la couleur seule. Teintes dérivées des tokens jaune et bleu.
class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.ok, this.strong});

  final String text;
  final bool ok;

  /// Début du texte à mettre en gras.
  final String? strong;

  @override
  Widget build(BuildContext context) {
    final tint = ok ? TmColor.accent : TmColor.yellow;
    final bold = strong != null && text.startsWith(strong!) ? strong! : '';
    return Semantics(
      liveRegion: true,
      child: Container(
        decoration: BoxDecoration(
          color: tint.withValues(alpha: ok ? .10 : .22),
          border: Border.all(color: ok ? tint.withValues(alpha: .5) : tint),
          borderRadius: BorderRadius.circular(TmRadius.md),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(ok ? Icons.check_circle_outline : Icons.error_outline,
                color: ok ? TmColor.accent : TmColor.navy, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(children: [
                  if (bold.isNotEmpty) TextSpan(text: bold, style: const TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: text.substring(bold.length)),
                ]),
                style: const TextStyle(fontSize: 15, color: TmColor.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
