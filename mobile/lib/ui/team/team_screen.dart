import 'package:flutter/material.dart';

import '../../data/match_record.dart';
import '../../domain/domain.dart';
import '../common/labels.dart';
import '../common/store_scope.dart';
import '../common/widgets.dart';
import '../match/match_access.dart';
import '../match_setup/new_match_screen.dart';
import '../tactics/tactics_screen.dart';
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

class _TeamScreenState extends State<TeamScreen> {
  late Team _team = widget.team;
  List<MatchRow> _matches = const [];

  /// Tablette : joueuse ouverte dans la fiche, ou [_adding] pour une nouvelle.
  Player? _selected;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    final rows = await loadMatchRows(StoreScope.of(context), _team);
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

  /// Hors match (entraînement, causerie) : pions sur la composition type, sinon sur les premiers numéros.
  Future<void> _openTactics() async {
    final navigator = Navigator.of(context);
    final template = await StoreScope.of(context).lineupTemplate(_team.id, _team.format);
    final lineup = template?.lineup ??
        [
          for (final p in (_team.activePlayers.where((p) => p.role != Role.libero).toList()
                ..sort((a, b) => a.number.compareTo(b.number)))
              .take(_team.format.playersOnCourt))
            p.id,
        ];
    await navigator.push(MaterialPageRoute<void>(
      builder: (_) => TacticsScreen(team: _team, lineup: lineup, liberoId: template?.liberoId),
    ));
  }

  Future<void> _openMatch(MatchRecord match) async {
    await openMatch(context, _team, match);
    await _loadMatches();
  }

  /// E11 : informations du match (adversaire, date, lieu…) ; règles verrouillées s'il a commencé.
  Future<void> _editMatch(MatchRow row) async {
    await Navigator.of(context).push<NewMatchResult>(MaterialPageRoute(
      builder: (_) => NewMatchScreen(team: _team, match: row.record, started: row.state != null),
    ));
    await _loadMatches();
  }

  Future<void> _deleteMatch(MatchRow row) async {
    final store = StoreScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer le match contre ${row.record.opponent} ?'),
        content: Text(row.state == null
            ? 'Le match sera retiré de la liste.'
            : 'Le match et toutes ses statistiques seront effacés de cet appareil. Cette action est définitive.'),
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
    await store.deleteMatch(row.record.id);
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
            IconButton(tooltip: 'Tableau tactique', onPressed: _openTactics, icon: const Icon(Icons.draw_outlined)),
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
            _MatchList(
              matches: _matches,
              onOpen: _openMatch,
              onNew: _newMatch,
              onEdit: _editMatch,
              onDelete: _deleteMatch,
              onSummary: (row) => openSummary(context, _team, row.record),
              onSquad: (row) async {
                if (await editSquad(context, _team, row.record)) await _loadMatches();
              },
            ),
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

/// E11 — Historique des matchs de l'équipe (V1-FIN-05) : en cours, à venir, terminés.
/// Chaque match s'ouvre au toucher ; son menu permet de le modifier, d'en voir le résumé ou de le supprimer.
class _MatchList extends StatelessWidget {
  const _MatchList({
    required this.matches,
    required this.onOpen,
    required this.onNew,
    required this.onEdit,
    required this.onDelete,
    required this.onSummary,
    required this.onSquad,
  });

  final List<MatchRow> matches;
  final ValueChanged<MatchRecord> onOpen;
  final VoidCallback onNew;
  final ValueChanged<MatchRow> onEdit;
  final ValueChanged<MatchRow> onDelete;
  final ValueChanged<MatchRow> onSummary;
  final ValueChanged<MatchRow> onSquad;

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
    // À venir : le plus proche d'abord ; en cours et terminés : le plus récent d'abord.
    final upcoming = matches.where((m) => m.notStarted).toList()..sort((a, b) => a.record.date.compareTo(b.record.date));
    final sections = [
      ('En cours', matches.where((m) => m.inProgress).toList()),
      ('À venir', upcoming),
      ('Terminés', matches.where((m) => m.finished).toList()),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (title, rows) in sections)
                  if (rows.isNotEmpty) ...[
                    TmCard(
                      title: '$title (${rows.length})',
                      child: Column(
                        children: [
                          for (final m in rows)
                            MatchTile(
                              row: m,
                              onTap: () => onOpen(m.record),
                              onEdit: () => onEdit(m),
                              onDelete: () => onDelete(m),
                              onSummary: m.notStarted ? null : () => onSummary(m),
                              onSquad: () => onSquad(m),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Une ligne de match : adversaire, date, lieu, état, et le menu des actions (s'il y en a).
class MatchTile extends StatelessWidget {
  const MatchTile({
    super.key,
    required this.row,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onSummary,
    this.onSquad,
    this.teamName,
  });

  final MatchRow row;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onSummary;
  final VoidCallback? onSquad;

  /// Sur l'accueil, l'équipe concernée.
  final String? teamName;

  @override
  Widget build(BuildContext context) {
    final r = row.record;
    final actions = onEdit != null || onDelete != null || onSummary != null || onSquad != null;
    return ListTile(
      minTileHeight: TmTouch.primaryTarget,
      contentPadding: EdgeInsets.zero,
      title: Text(teamName == null ? r.opponent : '$teamName contre ${r.opponent}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text([
            '${formatDate(r.date)} · ${formatTime(r.date)}',
            r.home ? 'Domicile' : 'Extérieur',
            if (r.venue.isNotEmpty) r.venue,
            if (r.competition.isNotEmpty) r.competition,
            r.format.label,
          ].join(' · ')),
          const SizedBox(height: 2),
          Text(matchStatus(row.state), style: const TextStyle(color: TmColor.accent, fontWeight: FontWeight.w700, fontSize: 15)),
        ],
      ),
      trailing: actions
          ? PopupMenuButton<String>(
              tooltip: 'Actions du match contre ${r.opponent}',
              onSelected: (v) => switch (v) {
                'edit' => onEdit?.call(),
                'summary' => onSummary?.call(),
                'squad' => onSquad?.call(),
                _ => onDelete?.call(),
              },
              itemBuilder: (_) => [
                if (onSummary != null)
                  const PopupMenuItem(value: 'summary', child: ListTile(leading: Icon(Icons.summarize_outlined), title: Text('Voir le résumé'))),
                if (onSquad != null)
                  PopupMenuItem(
                    value: 'squad',
                    child: ListTile(
                      leading: const Icon(Icons.how_to_reg_outlined),
                      title: Text(r.present == null ? 'Joueuses présentes' : 'Joueuses présentes (${r.present!.length})'),
                    ),
                  ),
                if (onEdit != null)
                  const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Modifier les informations'))),
                if (onDelete != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline, color: TmColor.error),
                      title: Text('Supprimer le match', style: TextStyle(color: TmColor.error)),
                    ),
                  ),
              ],
            )
          : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

/// État du match en toutes lettres : à composer, en cours (sets, score), gagné ou perdu avec les sets.
String matchStatus(MatchState? s) => switch (s) {
      null => 'À jouer · toucher pour composer',
      MatchState(phase: Phase.finished) =>
        '${s.winner == Side.us ? 'Gagné' : 'Perdu'} ${s.setsWon} · ${s.setsDone.map((x) => '$x').join(', ')}',
      _ => 'En cours · sets ${s.setsWon}${s.phase == Phase.inPlay ? ' · set ${s.setIndex + 1} à ${s.score}' : ''}'
          ' · toucher pour reprendre',
    };
