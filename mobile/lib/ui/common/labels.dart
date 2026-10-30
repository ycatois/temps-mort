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
/// Poste abrégé, sous les pions du terrain (« R-A » pour réceptionneuse-attaquante).
String roleShort(Role role, PlayerGender gender) =>
    role == Role.receptionneurAttaquant ? 'R-A' : roleLabel(role, gender);

String playerWord(Team team) => team.gender == TeamGender.masculine ? 'joueur' : 'joueuse';

/// Genre proposé par défaut pour une nouvelle personne de l'effectif.
PlayerGender defaultGender(Team team) => team.gender == TeamGender.masculine ? PlayerGender.m : PlayerGender.f;

String teamSummary(Team team) => '${team.category.label} · ${team.format.label} · ${team.gender.label} · ${team.season}';

String lineupIssueLabel(LineupIssue issue) => switch (issue) {
      WrongSize(:final expected, :final actual) => 'Il faut $expected personnes sur le terrain ($actual pour l\'instant)',
      Duplicate() => 'Une personne est placée deux fois',
      UnknownPlayer() => 'Une personne de la composition ne fait pas partie de l\'effectif',
      LiberoInLineup() => 'Le libero ne fait pas partie du six de départ',
      NotEnoughWomenInLineup(:final required, :final actual) =>
        'Il faut au moins $required femmes sur le terrain ($actual pour l\'instant)',
    };

String lineupWarningLabel(LineupWarning warning, Team team) {
  String name(String id) => team.player(id)?.firstName ?? '?';
  return switch (warning) {
    SetterCount(:final system, :final actual) =>
      'En ${system.label}, ${system.setters == 1 ? 'une passeuse est attendue' : 'deux passeuses sont attendues'} '
          "sur le terrain : $actual pour l'instant.",
    SettersNotOpposite(:final firstId, :final secondId) =>
      "${name(firstId)} et ${name(secondId)} ne sont pas opposées : les deux passeuses se placent à trois zones d'écart.",
    LiberoRoleInFrontRow(:final playerId) => '${name(playerId)}, libero de poste, est placée en zone avant.',
  };
}

/// Nom de la place [index] sur le terrain (index 0 = poste 1).
String zoneName(GameFormat format, int index) => switch (format) {
      GameFormat.six => 'Zone ${index + 1}',
      GameFormat.four => const ['Arrière droit', 'Avant droit', 'Avant gauche', 'Arrière gauche'][index],
      GameFormat.two => index == 0 ? 'Sert en premier' : 'Sert en second',
    };

const _longDays = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
const _longMonths = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
];

/// « Samedi 15 novembre »
String formatLongDate(DateTime d) => '${_longDays[d.weekday - 1]} ${d.day} ${_longMonths[d.month - 1]}';

const _days = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];
const _months = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];

/// « sam. 14 nov. 2026 »
String formatDate(DateTime d) => '${_days[d.weekday - 1]} ${d.day} ${_months[d.month - 1]} ${d.year}';

/// « 15 h 00 »
String formatTime(DateTime d) => '${d.hour} h ${d.minute.toString().padLeft(2, '0')}';
