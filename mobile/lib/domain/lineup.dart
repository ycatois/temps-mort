import 'team.dart';

sealed class LineupIssue {
  const LineupIssue();
}

final class WrongSize extends LineupIssue {
  const WrongSize(this.expected, this.actual);
  final int expected;
  final int actual;

  @override
  bool operator ==(Object other) => other is WrongSize && other.expected == expected && other.actual == actual;
  @override
  int get hashCode => Object.hash(expected, actual);
  @override
  String toString() => 'Il faut $expected joueurs sur le terrain, il y en a $actual';
}

final class Duplicate extends LineupIssue {
  const Duplicate(this.playerId);
  final String playerId;
}

final class UnknownPlayer extends LineupIssue {
  const UnknownPlayer(this.playerId);
  final String playerId;
}

final class LiberoInLineup extends LineupIssue {
  const LiberoInLineup(this.playerId);
  final String playerId;
}

final class NotEnoughWomenInLineup extends LineupIssue {
  const NotEnoughWomenInLineup(this.required, this.actual);
  final int required;
  final int actual;
}

/// Vérifie une composition de départ. [lineup] est ordonnée par poste : index 0 = poste 1 (serveur).
/// Le libero n'apparaît jamais dans la composition : il remplace ensuite un joueur arrière.
List<LineupIssue> validateLineup(Team team, List<String> lineup, {String? liberoId}) {
  final issues = <LineupIssue>[];
  final expected = team.format.playersOnCourt;
  if (lineup.length != expected) issues.add(WrongSize(expected, lineup.length));

  final seen = <String>{};
  final reported = <String>{};
  for (final id in lineup) {
    if (!seen.add(id) && reported.add(id)) issues.add(Duplicate(id));
  }
  for (final id in lineup) {
    if (team.player(id) == null) issues.add(UnknownPlayer(id));
  }
  if (liberoId != null && lineup.contains(liberoId)) issues.add(LiberoInLineup(liberoId));
  if (team.gender == TeamGender.mixte) {
    final women = lineup.toSet().where((id) => team.player(id)?.gender == PlayerGender.f).length;
    if (women < team.minWomenOnCourt) issues.add(NotEnoughWomenInLineup(team.minWomenOnCourt, women));
  }
  return issues;
}

/// Rotation dans le sens des aiguilles d'une montre : le joueur du poste 2 passe au service (poste 1).
List<String> rotate(List<String> lineup) =>
    lineup.isEmpty ? lineup : List.unmodifiable(List.generate(lineup.length, (i) => lineup[(i + 1) % lineup.length]));

/// Postes arrière (index à partir de 0) où le libero peut entrer : 1, 6 et 5 en 6x6.
const Set<int> backRow6x6 = {0, 4, 5};
