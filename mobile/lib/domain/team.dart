/// Équipe, joueuses, formats et catégories. Dart pur : aucun import Flutter dans lib/domain.
library;

/// Format de jeu : nombre de joueurs sur le terrain.
enum GameFormat {
  six(6, '6x6'),
  four(4, '4x4'),
  two(2, '2x2');

  const GameFormat(this.playersOnCourt, this.label);
  final int playersOnCourt;
  final String label;
}

/// Genre de l'équipe. Une équipe mixte impose un minimum de femmes sur le terrain.
enum TeamGender {
  feminine('Féminine'),
  masculine('Masculine'),
  mixte('Mixte');

  const TeamGender(this.label);
  final String label;
}

enum PlayerGender { f, m }

/// Catégories d'âge, des plus jeunes aux vétérans, plus le loisir.
/// [suggestedFormat] n'est qu'une valeur par défaut à la création d'équipe : le coach choisit librement.
/// (Nommée AgeCategory car Flutter définit déjà une classe `Category`.)
enum AgeCategory {
  m7('M7 · baby-volley', GameFormat.two),
  m9('M9', GameFormat.two),
  m11('M11', GameFormat.two),
  m13('M13', GameFormat.four),
  m15('M15', GameFormat.six),
  m18('M18', GameFormat.six),
  m21('M21', GameFormat.six),
  seniors('Seniors', GameFormat.six),
  veterans('Vétérans', GameFormat.six),
  loisir('Loisir', GameFormat.six);

  const AgeCategory(this.label, this.suggestedFormat);
  final String label;
  final GameFormat suggestedFormat;
}

enum Role { passeur, pointu, central, receptionneurAttaquant, libero, polyvalent }

class Player {
  const Player({
    required this.id,
    required this.firstName,
    required this.number,
    required this.gender,
    this.role = Role.polyvalent,
  });

  final String id;
  final String firstName;
  final int number;
  final PlayerGender gender;
  final Role role;
}

class Team {
  Team({
    required this.id,
    required this.name,
    required this.format,
    required this.gender,
    required this.category,
    required List<Player> players,
    int? minWomenOnCourt,
  })  : players = List.unmodifiable(players),
        minWomenOnCourt = minWomenOnCourt ??
            (gender == TeamGender.mixte ? format.playersOnCourt ~/ 2 : 0);

  final String id;
  final String name;
  final GameFormat format;
  final TeamGender gender;
  final AgeCategory category;
  final List<Player> players;

  /// Pour une équipe mixte : nombre minimum de femmes sur le terrain (par défaut la moitié).
  final int minWomenOnCourt;

  Player? player(String id) {
    for (final p in players) {
      if (p.id == id) return p;
    }
    return null;
  }

  Team copyWith({GameFormat? format, int? minWomenOnCourt}) => Team(
        id: id,
        name: name,
        format: format ?? this.format,
        gender: gender,
        category: category,
        players: players,
        minWomenOnCourt: minWomenOnCourt ?? this.minWomenOnCourt,
      );
}
