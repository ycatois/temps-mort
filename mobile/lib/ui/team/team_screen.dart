import 'package:flutter/material.dart';

import '../../data/match_record.dart';
import '../../domain/domain.dart';
import '../common/labels.dart';
import '../common/store_scope.dart';
import '../common/widgets.dart';
import '../composition/composition_screen.dart';
import '../match/match_screen.dart';
import '../match_setup/new_match_screen.dart';
import '../theme/tokens.dart';
import 'player_form.dart';
import 'team_form_screen.dart';

/// E02 — Effectif de l'équipe, et ses matchs. Tablette : liste et fiche côte à côte ;
/// smartphone : la fiche s'ouvre en plein écran.
class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key, required this.team});

  final Team team;

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

/// Un match de la liste, avec son état recalculé depuis ses événements (null = pas encore commencé).
typedef _MatchRow = ({MatchRecord record, MatchState? state});

class _TeamScreenState extends State<TeamScreen> {
  late Team _team = widget.team;
  List<_MatchRow> _matches = const [];

  /// Tablette : joueuse ouverte dans la fiche, ou [_adding] pour une nouvelle.
  Player? _selected;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    final store = StoreScope.of(context);
    final rows = <_MatchRow>[];
    for (final m in await store.matches(_team.id)) {
      final events = await store.events(m.id);
      rows.add((record: m, state: events.isEmpty ? null : MatchSession(m.teamFor(_team), rules: m.rules, events: events).state));
    }
    if (mounted) setState(() => _matches = rows);
  }

  Future<void> _savePlayer(Player player) async {
    final players = [..._team.players];
    final i = players.indexWhere((p) => p.id == player.id);
    if (i < 0) {
      players.add(player);
    } else {
      players[i] = player;
    }
    final team = _team.copyWith(players: players);
    await StoreScope.of(context).saveTeam(team);
    setState(() {
      _team = team;
      _selected = null;
      _adding = false;
    });
  }

  Future<void> _openPlayer(BuildContext context, Player? player, {required bool tablet}) async {
    if (tablet) {
      setState(() {
        _selected = player;
        _adding = player == null;
      });
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (context) => Scaffold(
        appBar: AppBar(title: Text(player?.firstName ?? 'Nouvelle ${playerWord(_team)}')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: TmCard(
            child: PlayerForm(
              team: _team,
              player: player,
              onSaved: (p) async {
                await _savePlayer(p);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ),
        ),
      ),
    ));
  }

  Future<void> _editTeam() async {
    final team = await Navigator.of(context).push<Team>(MaterialPageRoute(builder: (_) => TeamFormScreen(team: _team)));
    if (team != null) setState(() => _team = team);
  }

  Future<void> _newMatch() async {
    final result = await Navigator.of(context).push<NewMatchResult>(MaterialPageRoute(builder: (_) => NewMatchScreen(team: _team)));
    await _loadMatches();
    if (result != null && result.composeNow) await _openMatch(result.match);
  }

  /// Pas encore commencé : composition d'abord. Sinon on reprend le match là où il en était (V1-MAT-12).
  Future<void> _openMatch(MatchRecord match) async {
    final store = StoreScope.of(context);
    final navigator = Navigator.of(context);
    final team = match.teamFor(_team);
    if ((await store.events(match.id)).isEmpty) {
      final start = await navigator.push<StartSet>(
          MaterialPageRoute(builder: (_) => CompositionScreen(team: team, rules: match.rules, match: match)));
      if (start == null) return;
      await store.saveEvents(match.id, [start]);
    }
    final events = await store.events(match.id);
    await navigator.push(MaterialPageRoute<void>(
      builder: (_) => MatchScreen(
        team: team,
        rules: match.rules,
        events: events,
        onEventsChanged: (e) => store.saveEvents(match.id, e),
        fullInput: match.fullInput,
        onFullInputChanged: (v) => store.saveMatch(match.withFullInput(v)),
        composeNextSet: (context, suggested, {required setNumber, required serverLocked}) =>
            Navigator.of(context).push<StartSet>(MaterialPageRoute(
          builder: (_) => CompositionScreen(
            team: team,
            rules: match.rules,
            match: match,
            setNumber: setNumber,
            initial: suggested,
            initialServer: serverLocked ? suggested.firstServer : null,
            serverLocked: serverLocked,
          ),
        )),
      ),
    ));
    await _loadMatches();
  }

  @override
  Widget build(BuildContext context) {
    final active = _team.activePlayers..sort((a, b) => a.number.compareTo(b.number));
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_team.name),
              Text(teamSummary(_team), style: const TextStyle(fontSize: 14, color: TmColor.onNavyMuted)),
            ],
          ),
          actions: [
            IconButton(tooltip: 'Modifier l\'équipe', onPressed: _editTeam, icon: const Icon(Icons.edit_outlined)),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: YellowButton(label: 'Nouveau match', icon: Icons.add, onPressed: _newMatch),
            ),
          ],
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: TmColor.onNavyMuted,
            indicatorColor: TmColor.yellow,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            tabs: [Tab(text: 'Effectif (${active.length})'), Tab(text: 'Matchs (${_matches.length})')],
          ),
        ),
        body: TabBarView(
          children: [
            LayoutBuilder(builder: (context, box) {
              final tablet = box.maxWidth >= tabletWidth;
              final list = _RosterList(
                team: _team,
                active: active,
                selectedId: tablet ? _selected?.id : null,
                onOpen: (p) => _openPlayer(context, p, tablet: tablet),
              );
              if (!tablet) return list;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: list),
                  Expanded(
                    flex: 6,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                      child: _selected == null && !_adding
                          ? TmCard(
                              child: Text(
                                'Touchez une ${playerWord(_team)} pour ouvrir sa fiche, ou ajoutez-en une.',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            )
                          : TmCard(
                              title: _selected?.firstName ?? 'Nouvelle ${playerWord(_team)}',
                              child: PlayerForm(
                                key: ValueKey(_selected?.id ?? 'nouvelle'),
                                team: _team,
                                player: _selected,
                                onSaved: _savePlayer,
                                onCancel: () => setState(() {
                                  _selected = null;
                                  _adding = false;
                                }),
                              ),
                            ),
                    ),
                  ),
                ],
              );
            }),
            _MatchList(matches: _matches, onOpen: _openMatch, onNew: _newMatch),
          ],
        ),
      ),
    );
  }
}

class _RosterList extends StatelessWidget {
  const _RosterList({required this.team, required this.active, required this.selectedId, required this.onOpen});

  final Team team;
  final List<Player> active;
  final String? selectedId;
  final ValueChanged<Player?> onOpen;

  @override
  Widget build(BuildContext context) {
    final archived = team.players.where((p) => p.archived).toList()..sort((a, b) => a.number.compareTo(b.number));
    final word = playerWord(team);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        OutlinedButton.icon(
          onPressed: () => onOpen(null),
          icon: const Icon(Icons.person_add_alt_1),
          label: Text('Ajouter une $word'),
        ),
        const SizedBox(height: 12),
        if (active.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'L\'effectif est vide. Ajoutez chaque $word avec son prénom et son numéro de maillot.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        if (active.isNotEmpty)
          TmCard(
            child: Column(
              children: [for (final p in active) _PlayerTile(team: team, player: p, selected: p.id == selectedId, onTap: () => onOpen(p))],
            ),
          ),
        if (archived.isNotEmpty) ...[
          const SizedBox(height: 12),
          TmCard(
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              shape: const Border(),
              title: Text('Archivées (${archived.length})', style: Theme.of(context).textTheme.titleMedium),
              children: [
                for (final p in archived) _PlayerTile(team: team, player: p, selected: p.id == selectedId, onTap: () => onOpen(p)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({required this.team, required this.player, required this.selected, required this.onTap});

  final Team team;
  final Player player;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final details = [
      roleLabel(player.role, player.gender),
      if (team.gender == TeamGender.mixte) player.gender == PlayerGender.f ? 'Femme' : 'Homme',
    ].join(' · ');
    return ListTile(
      minTileHeight: TmTouch.primaryTarget,
      contentPadding: EdgeInsets.zero,
      selected: selected,
      selectedTileColor: TmColor.surfaceAlt,
      leading: NumberBadge(player.number, muted: player.archived),
      title: Text(player.firstName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
      subtitle: Text(details),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _MatchList extends StatelessWidget {
  const _MatchList({required this.matches, required this.onOpen, required this.onNew});

  final List<_MatchRow> matches;
  final ValueChanged<MatchRecord> onOpen;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Aucun match pour l\'instant.', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onNew, child: const Text('Préparer le premier match')),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: TmCard(
              child: Column(
                children: [
                  for (final m in matches)
                    ListTile(
                      minTileHeight: TmTouch.primaryTarget,
                      contentPadding: EdgeInsets.zero,
                      title: Text(m.record.opponent, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                      subtitle: Text([
                        '${formatDate(m.record.date)} · ${formatTime(m.record.date)}',
                        m.record.home ? 'Domicile' : 'Extérieur',
                        if (m.record.competition.isNotEmpty) m.record.competition,
                        m.record.format.label,
                      ].join(' · ')),
                      trailing: _StatusChip(state: m.state),
                      onTap: () => onOpen(m.record),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.state});
  final MatchState? state;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final (text, color) = switch (s) {
      null => ('À jouer · composer', TmColor.accent),
      MatchState(phase: Phase.finished) => ('${s.winner == Side.us ? 'Gagné' : 'Perdu'} ${s.setsWon}', TmColor.navy),
      _ => ('En cours · sets ${s.setsWon} · reprendre', TmColor.accent),
    };
    return Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15));
  }
}
