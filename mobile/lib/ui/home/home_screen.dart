import 'package:flutter/material.dart';

import '../../demo/demo_team.dart';
import '../../domain/domain.dart';
import '../common/labels.dart';
import '../common/store_scope.dart';
import '../common/widgets.dart';
import '../team/team_form_screen.dart';
import '../team/team_screen.dart';
import '../theme/tokens.dart';

/// Accueil (première version de E01) : les équipes du coach, et la création d'une équipe.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Team>? _teams;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final teams = await StoreScope.of(context).teams();
    if (mounted) setState(() => _teams = teams);
  }

  Future<void> _createTeam() async {
    final team = await Navigator.of(context).push<Team>(MaterialPageRoute(builder: (_) => const TeamFormScreen()));
    await _load();
    if (team != null) await _openTeam(team);
  }

  Future<void> _addDemo() async {
    await StoreScope.of(context).saveTeam(demoTeam);
    await _load();
  }

  /// Remet l'équipe de démonstration comme au premier jour : effectif d'origine, aucun match.
  Future<void> _resetDemo() async {
    final store = StoreScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser la démonstration ?'),
        content: const Text('Les matchs, la compo type et les schémas de l\'équipe de démonstration seront effacés, '
            'et son effectif remis d\'origine. Vos autres équipes ne changent pas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: TmColor.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await store.clearTeamData(demoTeam.id);
    await store.saveTeam(demoTeam);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Équipe de démonstration réinitialisée')));
    }
  }

  Future<void> _openTeam(Team team) async {
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TeamScreen(team: team)));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final teams = _teams;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Temps Mort', style: TextStyle(fontFamily: TmFont.display, fontWeight: FontWeight.w700, fontSize: 26)),
      ),
      body: teams == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Eyebrow('Mes équipes'),
                        const SizedBox(height: 12),
                        if (teams.isEmpty)
                          TmCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text('Bienvenue sur le banc.', style: Theme.of(context).textTheme.headlineMedium),
                                const SizedBox(height: 8),
                                Text(
                                  'Créez votre équipe, ajoutez l\'effectif, puis préparez votre premier match. '
                                  'Tout reste sur cette tablette, même sans réseau.',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 16),
                                YellowButton(label: 'Créer une équipe', icon: Icons.add, onPressed: _createTeam),
                                const SizedBox(height: 8),
                                OutlinedButton(onPressed: _addDemo, child: const Text('Essayer avec l\'équipe de démonstration')),
                              ],
                            ),
                          )
                        else ...[
                          for (final t in teams) ...[
                            _TeamCard(team: t, onTap: () => _openTeam(t)),
                            const SizedBox(height: 12),
                          ],
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              YellowButton(label: 'Créer une équipe', icon: Icons.add, onPressed: _createTeam),
                              if (teams.any((t) => t.id == demoTeam.id))
                                OutlinedButton.icon(
                                  onPressed: _resetDemo,
                                  icon: const Icon(Icons.restart_alt),
                                  label: const Text('Réinitialiser la démonstration'),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({required this.team, required this.onTap});

  final Team team;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = team.activePlayers.length;
    final word = playerWord(team);
    return Material(
      color: TmColor.surface,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: TmColor.line),
        borderRadius: BorderRadius.circular(TmRadius.lg),
      ),
      child: ListTile(
        minTileHeight: 72,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(team.name, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 26)),
        subtitle: Text('${teamSummary(team)} · $count ${count > 1 ? '${word}s' : word}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
