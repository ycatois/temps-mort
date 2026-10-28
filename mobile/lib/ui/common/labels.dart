import '../../domain/domain.dart';

/// Libellés français des valeurs du moteur. Les postes s'accordent avec le genre de la personne.

String roleLabel(Role role, PlayerGender gender) {
  final f = gender == PlayerGender.f;
  return switch (role) {
    Role.passeur => f ? 'Passeuse' : 'Passeur',
    Role.pointu => f ? 'Pointue' : 'Pointu',
    Role.central => f ? 'Centrale' : 'Central',
    Role.receptionneurAttaquant => f ? 'Réceptionneuse-attaquante' : 'Réceptionneur-attaquant',
    Role.libero => 'Libero',
    Role.polyvalent => f ? 'Polyvalente' : 'Polyvalent',
  };
}

/// « joueuse » ou « joueur » selon l'équipe ; une équipe mixte garde « joueuse » comme le reste de l'app.
String playerWord(Team team) => team.gender == TeamGender.masculine ? 'joueur' : 'joueuse';

/// Genre proposé par défaut pour une nouvelle personne de l'effectif.
PlayerGender defaultGender(Team team) => team.gender == TeamGender.masculine ? PlayerGender.m : PlayerGender.f;

String teamSummary(Team team) => '${team.category.label} · ${team.format.label} · ${team.gender.label}';

String lineupIssueLabel(LineupIssue issue) => switch (issue) {
      WrongSize(:final expected, :final actual) => 'Il faut $expected personnes sur le terrain ($actual pour l\'instant)',
      Duplicate() => 'Une personne est placée deux fois',
      UnknownPlayer() => 'Une personne de la composition ne fait pas partie de l\'effectif',
      LiberoInLineup() => 'Le libero ne fait pas partie du six de départ',
      NotEnoughWomenInLineup(:final required, :final actual) =>
        'Il faut au moins $required femmes sur le terrain ($actual pour l\'instant)',
    };

const _days = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];
const _months = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];

/// « sam. 14 nov. 2026 »
String formatDate(DateTime d) => '${_days[d.weekday - 1]} ${d.day} ${_months[d.month - 1]} ${d.year}';

/// « 15 h 00 »
String formatTime(DateTime d) => '${d.hour} h ${d.minute.toString().padLeft(2, '0')}';
