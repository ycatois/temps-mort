import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../domain/domain.dart';
import '../common/store_scope.dart';
import '../common/team_colors.dart';
import '../common/widgets.dart';
import '../theme/tokens.dart';

/// Création ou modification d'une équipe (V1-EQU-02, V1-FOR-01 à 04). Renvoie l'équipe enregistrée.
class TeamFormScreen extends StatefulWidget {
  const TeamFormScreen({super.key, this.team});

  /// null = nouvelle équipe.
  final Team? team;

  @override
  State<TeamFormScreen> createState() => _TeamFormScreenState();
}

class _TeamFormScreenState extends State<TeamFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.team?.name);
  late AgeCategory _category = widget.team?.category ?? AgeCategory.m15;
  late GameFormat _format = widget.team?.format ?? _category.suggestedFormat;
  late TeamGender _gender = widget.team?.gender ?? TeamGender.feminine;
  late int _minWomen = widget.team?.minWomenOnCourt ?? _format.playersOnCourt ~/ 2;
  late String _season = widget.team?.season ?? seasonOf(DateTime.now());
  late TeamColor? _color = widget.team?.color;
  bool _saving = false;

  /// Saisons proposées : la précédente, l'actuelle, la suivante (et celle de l'équipe si elle est plus ancienne).
  List<String> get _seasons {
    final now = DateTime.now();
    final list = [
      seasonOf(DateTime(now.year - 1, now.month)),
      seasonOf(now),
      seasonOf(DateTime(now.year + 1, now.month)),
    ];
    return {_season, ...list}.toList()..sort();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final name = _name.text.trim();
    final minWomen = _gender == TeamGender.mixte ? _minWomen : 0;
    final existing = widget.team;
    final team = existing == null
        ? Team(
            id: newId(),
            name: name,
            format: _format,
            gender: _gender,
            category: _category,
            players: const [],
            minWomenOnCourt: minWomen,
            season: _season,
            color: _color,
          )
        : existing.copyWith(
            name: name,
            format: _format,
            gender: _gender,
            category: _category,
            minWomenOnCourt: minWomen,
            season: _season,
            color: _color,
          );
    await StoreScope.of(context).saveTeam(team);
    if (mounted) Navigator.of(context).pop(team);
  }

  /// RGPD : l'équipe, son effectif, ses matchs, compos types et schémas disparaissent de l'appareil.
  Future<void> _delete() async {
    final team = widget.team!;
    final store = StoreScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer l\'équipe ${team.name} ?'),
        content: const Text('L\'effectif, tous les matchs et leurs statistiques, la composition type et les schémas '
            'seront effacés de cet appareil. Cette action est définitive.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: TmColor.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await store.deleteTeam(team.id);
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.team == null ? 'Nouvelle équipe' : 'Modifier l\'équipe')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: TmCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _name,
                        autofocus: widget.team == null,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(labelText: 'Nom de l\'équipe', hintText: 'ex. M15 filles'),
                        validator: (v) => (v ?? '').trim().isEmpty ? 'Donnez un nom à l\'équipe' : null,
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<AgeCategory>(
                        initialValue: _category,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Catégorie'),
                        items: [for (final c in AgeCategory.values) DropdownMenuItem(value: c, child: Text(c.label))],
                        onChanged: (c) => setState(() {
                          _category = c!;
                          // Le format proposé suit la catégorie ; le coach peut toujours le changer ensuite.
                          _setFormat(c.suggestedFormat);
                        }),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        initialValue: _season,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Saison'),
                        items: [for (final s in _seasons) DropdownMenuItem(value: s, child: Text(s))],
                        onChanged: (s) => setState(() => _season = s!),
                      ),
                      const SizedBox(height: 20),
                      const Eyebrow('Couleur du maillot'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Aucune'),
                            selected: _color == null,
                            onSelected: (_) => setState(() => _color = null),
                          ),
                          for (final c in TeamColor.values)
                            ChoiceChip(
                              avatar: TeamColorDot(c, size: 18),
                              label: Text(c.label),
                              selected: _color == c,
                              onSelected: (_) => setState(() => _color = c),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Eyebrow('Format de jeu'),
                      const SizedBox(height: 8),
                      SegmentedButton<GameFormat>(
                        segments: [for (final f in GameFormat.values) ButtonSegment(value: f, label: Text(f.label))],
                        selected: {_format},
                        onSelectionChanged: (s) => setState(() => _setFormat(s.single)),
                      ),
                      const SizedBox(height: 20),
                      const Eyebrow('Type d\'équipe'),
                      const SizedBox(height: 8),
                      SegmentedButton<TeamGender>(
                        segments: [for (final g in TeamGender.values) ButtonSegment(value: g, label: Text(g.label))],
                        selected: {_gender},
                        onSelectionChanged: (s) => setState(() => _gender = s.single),
                      ),
                      if (_gender == TeamGender.mixte) ...[
                        const SizedBox(height: 16),
                        NumberStepper(
                          label: 'Femmes au minimum sur le terrain',
                          value: _minWomen,
                          min: 0,
                          max: _format.playersOnCourt,
                          onChanged: (v) => setState(() => _minWomen = v),
                        ),
                        Text(
                          'Selon le règlement de votre championnat. Vérifié à la composition et à chaque remplacement.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(onPressed: _saving ? null : _save, child: const Text('Enregistrer')),
                      if (widget.team != null) ...[
                        const SizedBox(height: 24),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: TmColor.error,
                            minimumSize: const Size(0, TmTouch.minTarget),
                          ),
                          onPressed: _saving ? null : _delete,
                          icon: const Icon(Icons.delete_forever_outlined),
                          label: const Text('Supprimer l\'équipe et toutes ses données'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setFormat(GameFormat format) {
    if (format == _format) return;
    _format = format;
    _minWomen = format.playersOnCourt ~/ 2;
  }
}
