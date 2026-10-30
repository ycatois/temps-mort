import 'package:flutter/material.dart';

import '../../data/match_record.dart';
import '../../data/store.dart';
import '../../domain/domain.dart';
import '../common/labels.dart';
import '../common/store_scope.dart';
import '../common/widgets.dart';

/// Résultat de E03 : le match enregistré, et si le coach veut composer son six tout de suite.
typedef NewMatchResult = ({MatchRecord match, bool composeNow});

/// E03 — Nouveau match (V1-PRE-01, V1-PRE-02). Tablette : informations et règles côte à côte.
/// Avec [match], modification d'un match existant (E11) : une fois le match commencé ([started]),
/// format et règles ne bougent plus, car ils donnent leur sens aux points déjà saisis.
class NewMatchScreen extends StatefulWidget {
  const NewMatchScreen({super.key, required this.team, this.match, this.started = false});

  final Team team;
  final MatchRecord? match;
  final bool started;

  @override
  State<NewMatchScreen> createState() => _NewMatchScreenState();
}

class _NewMatchScreenState extends State<NewMatchScreen> {
  final _form = GlobalKey<FormState>();
  late final _opponent = TextEditingController(text: widget.match?.opponent);
  late final _venue = TextEditingController(text: widget.match?.venue);
  late final _competition = TextEditingController(text: widget.match?.competition);
  late DateTime _date = widget.match?.date ?? _nextHour();
  late bool _home = widget.match?.home ?? true;
  late bool _fullInput = widget.match?.fullInput ?? false;
  late GameFormat _format = widget.match?.format ?? widget.team.format;
  late MatchRules _rules = widget.match?.rules ?? MatchRules.defaultFor(_format);

  bool get _editing => widget.match != null;
  bool _saving = false;

  static DateTime _nextHour() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour + 1);
  }

  @override
  void dispose() {
    _opponent.dispose();
    _venue.dispose();
    _competition.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(_date.year - 1),
      lastDate: DateTime(_date.year + 2),
    );
    if (d != null) setState(() => _date = DateTime(d.year, d.month, d.day, _date.hour, _date.minute));
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_date));
    if (t != null) setState(() => _date = DateTime(_date.year, _date.month, _date.day, t.hour, t.minute));
  }

  Future<void> _save({required bool composeNow}) async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final old = widget.match;
    final match = MatchRecord(
      id: old?.id ?? newId(),
      teamId: widget.team.id,
      opponent: _opponent.text.trim(),
      date: _date,
      venue: _venue.text.trim(),
      home: _home,
      competition: _competition.text.trim(),
      format: _format,
      rules: _rules,
      fullInput: _fullInput,
    );
    await StoreScope.of(context).saveMatch(match);
    if (mounted) Navigator.of(context).pop<NewMatchResult>((match: match, composeNow: composeNow));
  }

  /// Match commencé : les règles s'affichent sans pouvoir être changées ; seul le mode de saisie reste libre.
  Widget _locked(BuildContext context) {
    final r = _rules;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${_format.label} · ${r.setsToWin} sets gagnants · ${r.pointsPerSet} points, ${r.pointsDecidingSet} au set décisif',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 4),
        Text('Le match a commencé : format et règles ne se modifient plus.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        Text('Saisie des statistiques', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Simple')),
            ButtonSegment(value: true, label: Text('Complète')),
          ],
          selected: {_fullInput},
          onSelectionChanged: (s) => setState(() => _fullInput = s.single),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = TmCard(
      title: 'Le match',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _opponent,
            autofocus: !_editing,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Adversaire', hintText: 'ex. Rennes EC'),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Indiquez l\'adversaire' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event),
                  label: Text(formatDate(_date)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(onPressed: _pickTime, icon: const Icon(Icons.schedule), label: Text(formatTime(_date))),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Domicile')),
              ButtonSegment(value: false, label: Text('Extérieur')),
            ],
            selected: {_home},
            onSelectionChanged: (s) => setState(() => _home = s.single),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _venue,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Lieu (facultatif)', hintText: 'ex. Gymnase Colette'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _competition,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Compétition (facultatif)', hintText: 'ex. Championnat départemental'),
          ),
        ],
      ),
    );

    final rules = TmCard(
      title: 'Format et règles',
      child: widget.started ? _locked(context) : Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<GameFormat>(
            segments: [for (final f in GameFormat.values) ButtonSegment(value: f, label: Text(f.label))],
            selected: {_format},
            onSelectionChanged: (s) => setState(() {
              _format = s.single;
              _rules = MatchRules.defaultFor(_format);
            }),
          ),
          if (_format != widget.team.format)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'L\'équipe joue habituellement en ${widget.team.format.label} : ce format ne vaut que pour ce match.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          const SizedBox(height: 16),
          Text('Sets gagnants', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 2, label: Text('2')),
              ButtonSegment(value: 3, label: Text('3')),
            ],
            selected: {_rules.setsToWin},
            onSelectionChanged: (s) => setState(() => _rules = _rules.copyWith(setsToWin: s.single)),
          ),
          const SizedBox(height: 16),
          NumberStepper(
            label: 'Points par set',
            value: _rules.pointsPerSet,
            min: 5,
            max: 50,
            onChanged: (v) => setState(() => _rules = _rules.copyWith(pointsPerSet: v)),
          ),
          const SizedBox(height: 8),
          NumberStepper(
            label: 'Points du set décisif',
            value: _rules.pointsDecidingSet,
            min: 5,
            max: 50,
            onChanged: (v) => setState(() => _rules = _rules.copyWith(pointsDecidingSet: v)),
          ),
          const SizedBox(height: 8),
          Text('Deux points d\'écart pour gagner un set.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          Text('Saisie des statistiques', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Simple')),
              ButtonSegment(value: true, label: Text('Complète')),
            ],
            selected: {_fullInput},
            onSelectionChanged: (s) => setState(() => _fullInput = s.single),
          ),
          const SizedBox(height: 4),
          Text(
            _fullInput
                ? 'Chaque geste noté : réceptions de 0 à 3, attaques en jeu, défenses. Pour un adjoint au bord du terrain.'
                : 'L\'action qui termine l\'échange. Modifiable pendant le match.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (_rules.substitutionsPerSet != 0) ...[
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _rules.pairedSubstitutions,
              onChanged: (v) => setState(() => _rules = _rules.copyWith(pairedSubstitutions: v)),
              title: const Text('Retour à la place d\'origine'),
              subtitle: const Text(
                  'Une titulaire ne sort qu\'une fois par set et ne revient qu\'à la place de sa remplaçante.'),
            ),
          ],
        ],
      ),
    );

    final actions = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _editing
          ? [YellowButton(label: 'Enregistrer les modifications', onPressed: _saving ? null : () => _save(composeNow: false))]
          : [
        YellowButton(label: 'Composer le six de départ', onPressed: _saving ? null : () => _save(composeNow: true)),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: _saving ? null : () => _save(composeNow: false), child: const Text('Enregistrer pour plus tard')),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: Text('${_editing ? 'Modifier le match' : 'Nouveau match'} · ${widget.team.name}')),
      body: Form(
        key: _form,
        child: LayoutBuilder(builder: (context, box) {
          if (box.maxWidth >= tabletWidth) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Expanded(child: info), const SizedBox(width: 16), Expanded(child: rules)],
                  ),
                  const SizedBox(height: 16),
                  Align(alignment: Alignment.centerRight, child: SizedBox(width: 420, child: actions)),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [info, const SizedBox(height: 16), rules, const SizedBox(height: 16), actions],
          );
        }),
      ),
    );
  }
}
