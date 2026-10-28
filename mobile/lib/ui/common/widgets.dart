import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Largeur à partir de laquelle on passe en mise en page tablette (deux colonnes).
const double tabletWidth = 840;

/// Carte blanche à bordure, avec un surtitre facultatif.
class TmCard extends StatelessWidget {
  const TmCard({super.key, this.title, required this.child});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Material plutôt que Container : les lignes de liste y dessinent leur effet au toucher.
    return Material(
      color: TmColor.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: TmColor.line),
        borderRadius: BorderRadius.circular(TmRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[Eyebrow(title!), const SizedBox(height: 12)],
            child,
          ],
        ),
      ),
    );
  }
}

/// Surtitre : petites capitales espacées, bleu sur fond clair.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(color: TmColor.accent, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.2),
      );
}

/// Pastille du numéro de maillot.
class NumberBadge extends StatelessWidget {
  const NumberBadge(this.number, {super.key, this.muted = false});
  final int number;
  final bool muted;

  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: 22,
        backgroundColor: muted ? TmColor.surfaceAlt : TmColor.navy,
        child: Text(
          '$number',
          style: TextStyle(
            fontFamily: TmFont.display,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: muted ? TmColor.muted : TmColor.onNavy,
          ),
        ),
      );
}

/// Choix d'un nombre avec − et +, cibles de 48 dp.
class NumberStepper extends StatelessWidget {
  const NumberStepper({super.key, required this.label, required this.value, required this.min, required this.max, required this.onChanged});

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
        IconButton.outlined(
          tooltip: '$label : moins',
          constraints: const BoxConstraints.tightFor(width: TmTouch.minTarget, height: TmTouch.minTarget),
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 56,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: TmFont.display, fontWeight: FontWeight.w700, fontSize: 26),
          ),
        ),
        IconButton.outlined(
          tooltip: '$label : plus',
          constraints: const BoxConstraints.tightFor(width: TmTouch.minTarget, height: TmTouch.minTarget),
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

/// Bouton d'appel à l'action jaune (un seul par zone d'écran).
class YellowButton extends StatelessWidget {
  const YellowButton({super.key, required this.label, required this.onPressed, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(backgroundColor: TmColor.yellow, foregroundColor: TmColor.navy);
    return icon == null
        ? FilledButton(onPressed: onPressed, style: style, child: Text(label))
        : FilledButton.icon(onPressed: onPressed, style: style, icon: Icon(icon), label: Text(label));
  }
}
