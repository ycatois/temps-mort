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

/// Problème dans la liste des présentes d'un match (V1-PRE-03).
sealed class SquadIssue {
  const SquadIssue();
}

/// Trop de joueuses inscrites : 14 au plus en 6x6, libero(s) compris (FIVB 4.1.1).
final class TooManyInSquad extends SquadIssue {
  const TooManyInSquad(this.max, this.actual);
  final int max;
  final int actual;

  @override
  bool operator ==(Object other) => other is TooManyInSquad && other.max == max && other.actual == actual;
  @override
  int get hashCode => Object.hash(max, actual);
}

/// Pas assez de joueuses pour composer le terrain.
final class NotEnoughInSquad extends SquadIssue {
  const NotEnoughInSquad(this.required, this.actual);
  final int required;
  final int actual;

  @override
  bool operator ==(Object other) => other is NotEnoughInSquad && other.required == required && other.actual == actual;
  @override
  int get hashCode => Object.hash(required, actual);
}

/// Équipe mixte : pas assez de femmes présentes pour respecter le minimum sur le terrain.
final class NotEnoughWomenInSquad extends SquadIssue {
  const NotEnoughWomenInSquad(this.required, this.actual);
  final int required;
  final int actual;

  @override
  bool operator ==(Object other) => other is NotEnoughWomenInSquad && other.required == required && other.actual == actual;
  @override
  int get hashCode => Object.hash(required, actual);
}

/// Nombre maximum de joueuses inscrites sur la feuille de match, ou null sans limite.
/// 6x6 : 14, dont deux liberos au plus (FIVB 4.1.1, 19.1.1). Ailleurs, pas de limite connue.
int? maxSquad(GameFormat format) => format == GameFormat.six ? 14 : null;

/// Contrôle la liste des présentes d'un match ([present] : identifiants de l'effectif).
List<SquadIssue> validateSquad(Team team, Iterable<String> present) {
  final ids = present.toSet();
  final issues = <SquadIssue>[];
  final max = maxSquad(team.format);
  if (max != null && ids.length > max) issues.add(TooManyInSquad(max, ids.length));
  if (ids.length < team.format.playersOnCourt) issues.add(NotEnoughInSquad(team.format.playersOnCourt, ids.length));
  if (team.gender == TeamGender.mixte) {
    final women = ids.where((id) => team.player(id)?.gender == PlayerGender.f).length;
    if (women < team.minWomenOnCourt) issues.add(NotEnoughWomenInSquad(team.minWomenOnCourt, women));
  }
  return issues;
}

/// Rotation dans le sens des aiguilles d'une montre : le joueur du poste 2 passe au service (poste 1).
List<String> rotate(List<String> lineup) =>
    lineup.isEmpty ? lineup : List.unmodifiable(List.generate(lineup.length, (i) => lineup[(i + 1) % lineup.length]));

/// Postes arrière (index à partir de 0) où le libero peut entrer : 1, 6 et 5 en 6x6.
const Set<int> backRow6x6 = {0, 4, 5};

/// Système de jeu en 6x6 (V1-PRE-06) : nombre de passeuses et leur placement.
enum GameSystem {
  s51('5-1', 1),
  s42('4-2', 2),
  s62('6-2', 2);

  const GameSystem(this.label, this.setters);
  final String label;

  /// Passeuses attendues sur le terrain.
  final int setters;
}

/// Alerte de composition (V1-PRE-08) : la composition reste jouable, le coach décide.
sealed class LineupWarning {
  const LineupWarning();
}

/// Pas le nombre de passeuses attendu par le système.
final class SetterCount extends LineupWarning {
  const SetterCount(this.system, this.actual);
  final GameSystem system;
  final int actual;

  @override
  bool operator ==(Object other) => other is SetterCount && other.system == system && other.actual == actual;
  @override
  int get hashCode => Object.hash(system, actual);
}

/// En 4-2 et 6-2, les deux passeuses doivent être opposées (trois postes d'écart) : jamais côte à côte.
final class SettersNotOpposite extends LineupWarning {
  const SettersNotOpposite(this.firstId, this.secondId);
  final String firstId;
  final String secondId;

  @override
  bool operator ==(Object other) => other is SettersNotOpposite && other.firstId == firstId && other.secondId == secondId;
  @override
  int get hashCode => Object.hash(firstId, secondId);
}

/// Une joueuse dont le poste est libero est placée en zone avant comme joueuse de champ.
final class LiberoRoleInFrontRow extends LineupWarning {
  const LiberoRoleInFrontRow(this.playerId);
  final String playerId;

  @override
  bool operator ==(Object other) => other is LiberoRoleInFrontRow && other.playerId == playerId;
  @override
  int get hashCode => playerId.hashCode;
}

/// Postes avant (index à partir de 0) en 6x6 : 2, 3 et 4.
const Set<int> frontRow6x6 = {1, 2, 3};

/// Alertes sur une composition complète de 6x6, d'après les postes déclarés de l'effectif.
/// Hors 6x6, ou sans système, il n'y a rien à contrôler.
List<LineupWarning> lineupWarnings(Team team, List<String> lineup, GameSystem? system) {
  if (team.format != GameFormat.six || lineup.length != 6) return const [];
  final warnings = <LineupWarning>[];
  if (system != null) {
    final setters = [for (var i = 0; i < 6; i++) if (team.player(lineup[i])?.role == Role.passeur) i];
    if (setters.length != system.setters) {
      warnings.add(SetterCount(system, setters.length));
    } else if (setters.length == 2 && setters[1] - setters[0] != 3) {
      warnings.add(SettersNotOpposite(lineup[setters[0]], lineup[setters[1]]));
    }
  }
  for (final i in frontRow6x6) {
    if (team.player(lineup[i])?.role == Role.libero) warnings.add(LiberoRoleInFrontRow(lineup[i]));
  }
  return warnings;
}
