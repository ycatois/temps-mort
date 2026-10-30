import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../theme/tokens.dart';

/// Teinte de la couleur d'équipe choisie par le coach. Ce sont des couleurs de maillot (des données),
/// pas des couleurs de l'interface : elles ne passent donc pas par design/tokens.json.
Color teamColorValue(TeamColor c) => switch (c) {
      TeamColor.navy => const Color(0xFF1B2A57),
      TeamColor.blue => const Color(0xFF1E5BD6),
      TeamColor.sky => const Color(0xFF6FB6E8),
      TeamColor.red => const Color(0xFFD12A2A),
      TeamColor.green => const Color(0xFF1F8A4C),
      TeamColor.yellow => const Color(0xFFFFD23F),
      TeamColor.orange => const Color(0xFFF07F1A),
      TeamColor.purple => const Color(0xFF7A3FB8),
      TeamColor.pink => const Color(0xFFE85C9C),
      TeamColor.black => const Color(0xFF16181D),
      TeamColor.white => const Color(0xFFFFFFFF),
    };

/// Pastille de la couleur d'équipe, bordée pour rester visible sur fond blanc (maillot blanc).
class TeamColorDot extends StatelessWidget {
  const TeamColorDot(this.color, {super.key, this.size = 20});
  final TeamColor color;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Maillot ${color.label.toLowerCase()}',
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: teamColorValue(color),
            shape: BoxShape.circle,
            border: Border.all(color: TmColor.line, width: 2),
          ),
        ),
      );
}
