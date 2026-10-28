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
class NewMatchScreen extends StatefulWidget {
  const NewMatchScreen({super.key, required this.team});

  final Team team;

  @override
  State<NewMatchScreen> createState() => _NewMatchScreenState();
}

class _NewMatchScreenState extends State<NewMatchScreen> {
  final _form = GlobalKey<FormState>();
  final _opponent = TextEditingController();
  final _venue = TextEditingController();
  final _competition = TextEditingController();
  late DateTime _date = _nextHour();
  bool _home = true;
  late GameFormat _format = widget.team.format;
  late MatchRules _rules = MatchRules.defaultFor(_format);
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
    final match = MatchRecord(
      id: newId(),
      teamId: widget.team.id,
      opponent: _opponent.text.trim(),
      date: _date,
      venue: _venue.text.trim(),
      home: _home,
      competition: _competition.text.trim(),
      format: _format,
      rules: _rules,
    );
    await StoreScope.of(context).saveMatch(match);
    if (mounted) Navigator.of(context).pop<NewMatchResult>((match: match, composeNow: composeNow));
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
            autofocus: true,
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
      child: Column(
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
        ],
      ),
    );

    final actions = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        YellowButton(label: 'Composer le six de départ', onPressed: _saving ? null : () => _save(composeNow: true)),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: _saving ? null : () => _save(composeNow: false), child: const Text('Enregistrer pour plus tard')),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: Text('Nouveau match · ${widget.team.name}')),
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
