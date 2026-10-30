import '../domain/domain.dart';

/// Schéma enregistré dans la bibliothèque de l'équipe (V1-TAC-07), rappelé d'un match à l'autre.
/// Les pions des joueuses ne gardent que l'identifiant : prénom et numéro viennent de l'effectif.
class TacticPlay {
  const TacticPlay({required this.id, required this.teamId, required this.name, required this.savedAt, required this.board});

  final String id;
  final String teamId;
  final String name;
  final DateTime savedAt;
  final TacticBoard board;
}
