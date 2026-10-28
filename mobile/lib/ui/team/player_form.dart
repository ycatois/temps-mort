import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/store.dart';
import '../../domain/domain.dart';
import '../common/labels.dart';
import '../common/widgets.dart';
import '../theme/tokens.dart';

/// Fiche d'une joueuse (V1-EQU-03, 05). Données minimales : prénom, numéro, poste, genre si l'équipe
/// est mixte. Pas de nom ni de photo : la plupart des joueuses sont mineures.
class PlayerForm extends StatefulWidget {
  const PlayerForm({super.key, required this.team, this.player, required this.onSaved, this.onCancel});

  final Team team;

  /// null = nouvelle joueuse.
  final Player? player;
  final ValueChanged<Player> onSaved;
  final VoidCallback? onCancel;

  @override
  State<PlayerForm> createState() => _PlayerFormState();
}

class _PlayerFormState extends State<PlayerForm> {
  final _form = GlobalKey<FormState>();
  late final _firstName = TextEditingController(text: widget.player?.firstName);
  late final _number = TextEditingController(text: widget.player?.number.toString());
  late PlayerGender _gender = widget.player?.gender ?? defaultGender(widget.team);
  late Role _role = widget.player?.role ?? Role.polyvalent;

  @override
  void dispose() {
    _firstName.dispose();
    _number.dispose();
    super.dispose();
  }

  String? _checkNumber(String? value) {
    final n = int.tryParse(value ?? '');
    if (n == null || n > 99) return 'Numéro de 0 à 99';
    for (final p in widget.team.activePlayers) {
      if (p.number == n && p.id != widget.player?.id) return 'Le numéro $n est déjà porté par ${p.firstName}';
    }
    return null;
  }

  void _save({bool? archived}) {
    if (!_form.currentState!.validate()) return;
    final firstName = _firstName.text.trim();
    final number = int.parse(_number.text);
    final existing = widget.player;
    widget.onSaved(existing == null
        ? Player(id: newId(), firstName: firstName, number: number, gender: _gender, role: _role)
        : existing.copyWith(firstName: firstName, number: number, gender: _gender, role: _role, archived: archived));
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.player;
    final word = playerWord(widget.team);
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _firstName,
                  autofocus: existing == null,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Prénom'),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Indiquez le prénom' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _number,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
                  decoration: const InputDecoration(labelText: 'Numéro'),
                  validator: _checkNumber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            word == 'joueur'
                ? 'Prénom seulement : ni nom ni photo, la plupart des joueurs sont mineurs.'
                : 'Prénom seulement : ni nom ni photo, la plupart des joueuses sont mineures.',
            style: const TextStyle(color: TmColor.muted, fontSize: 14),
          ),
          if (widget.team.gender == TeamGender.mixte) ...[
            const SizedBox(height: 16),
            const Eyebrow('Genre'),
            const SizedBox(height: 8),
            SegmentedButton<PlayerGender>(
              segments: const [
                ButtonSegment(value: PlayerGender.f, label: Text('Femme')),
                ButtonSegment(value: PlayerGender.m, label: Text('Homme')),
              ],
              selected: {_gender},
              onSelectionChanged: (s) => setState(() => _gender = s.single),
            ),
          ],
          const SizedBox(height: 16),
          DropdownButtonFormField<Role>(
            initialValue: _role,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Poste principal'),
            items: [for (final r in Role.values) DropdownMenuItem(value: r, child: Text(roleLabel(r, _gender)))],
            onChanged: (r) => setState(() => _role = r!),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: Text(existing == null ? 'Ajouter à l\'effectif' : 'Enregistrer')),
          if (existing != null) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _save(archived: !existing.archived),
              child: Text(existing.archived ? 'Réactiver' : 'Archiver (quitte l\'équipe, reste dans l\'historique)'),
            ),
          ],
          if (widget.onCancel != null) ...[
            const SizedBox(height: 8),
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(0, TmTouch.minTarget)),
              onPressed: widget.onCancel,
              child: const Text('Annuler'),
            ),
          ],
        ],
      ),
    );
  }
}
