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

/// Saison sportive d'une date, ex. « 2026-2027 ». Elle commence le 1er juillet (saison FFVB).
String seasonOf(DateTime date) {
  final start = date.month >= 7 ? date.year : date.year - 1;
  return '$start-${start + 1}';
}

/// Couleur de l'équipe (maillot), choisie par le coach pour reconnaître ses équipes (V1-EQU-02).
/// Toujours affichée avec son nom : la couleur seule ne porte aucune information.
enum TeamColor {
  navy('Bleu marine'),
  blue('Bleu'),
  sky('Bleu ciel'),
  red('Rouge'),
  green('Vert'),
  yellow('Jaune'),
  orange('Orange'),
  purple('Violet'),
  pink('Rose'),
  black('Noir'),
  white('Blanc');

  const TeamColor(this.label);
  final String label;
}

class Player {
  const Player({
    required this.id,
    required this.firstName,
    required this.number,
    required this.gender,
    this.role = Role.polyvalent,
    this.archived = false,
    this.deleted = false,
  });

  /// Ce qui reste d'une joueuse supprimée à sa demande (RGPD, V1-TEC-09) qui a déjà joué : ni prénom
  /// ni numéro, seulement l'identifiant (aléatoire) et le genre, pour que les matchs passés se rejouent
  /// à l'identique (mixité comprise). Ses statistiques restent, sans nom.
  factory Player.anonymized(Player p) =>
      Player(id: p.id, firstName: 'Anonyme', number: 0, gender: p.gender, archived: true, deleted: true);

  final String id;
  final String firstName;
  final int number;
  final PlayerGender gender;
  final Role role;

  /// Joueuse partie en cours de saison : absente des compositions, gardée pour l'historique des matchs.
  final bool archived;

  /// Données supprimées à la demande : n'apparaît plus dans l'effectif.
  final bool deleted;

  Player copyWith({String? firstName, int? number, PlayerGender? gender, Role? role, bool? archived}) => Player(
        id: id,
        firstName: firstName ?? this.firstName,
        number: number ?? this.number,
        gender: gender ?? this.gender,
        role: role ?? this.role,
        archived: archived ?? this.archived,
        deleted: deleted,
      );
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
    String? season,
    this.color,
  })  : players = List.unmodifiable(players),
        season = season ?? seasonOf(DateTime.now()),
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

  /// Saison de l'équipe, ex. « 2026-2027 » ; par défaut la saison en cours à la création.
  final String season;

  /// Couleur du maillot ; null = non choisie.
  final TeamColor? color;

  /// Joueuses que l'on peut convoquer et composer (les archivées restent pour l'historique).
  List<Player> get activePlayers => players.where((p) => !p.archived).toList();

  /// Joueuses archivées, sans celles dont les données ont été supprimées.
  List<Player> get archivedPlayers => players.where((p) => p.archived && !p.deleted).toList();

  /// Supprime les données d'une joueuse à sa demande (RGPD). [keepTrace] : elle a déjà joué un match,
  /// on garde une trace anonyme ([Player.anonymized]) pour rejouer ces matchs ; sinon elle disparaît.
  Team deletePlayer(String id, {required bool keepTrace}) => copyWith(players: [
        for (final p in players)
          if (p.id != id)
            p
          else if (keepTrace)
            Player.anonymized(p),
      ]);

  /// L'équipe réduite aux joueuses présentes d'un match (V1-PRE-03) : banc, composition et remplacements
  /// n'en voient pas d'autres. Null = toutes les joueuses de l'effectif.
  Team withSquad(Iterable<String>? present) {
    if (present == null) return this;
    final ids = present.toSet();
    return copyWith(players: [for (final p in players) if (ids.contains(p.id)) p]);
  }

  Player? player(String id) {
    for (final p in players) {
      if (p.id == id) return p;
    }
    return null;
  }

  Team copyWith({
    String? name,
    GameFormat? format,
    TeamGender? gender,
    AgeCategory? category,
    List<Player>? players,
    int? minWomenOnCourt,
    String? season,
    Object? color = _keep,
  }) =>
      Team(
        id: id,
        name: name ?? this.name,
        format: format ?? this.format,
        gender: gender ?? this.gender,
        category: category ?? this.category,
        players: players ?? this.players,
        minWomenOnCourt: minWomenOnCourt ?? this.minWomenOnCourt,
        season: season ?? this.season,
        color: identical(color, _keep) ? this.color : color as TeamColor?,
      );

  static const Object _keep = Object();

  /// L'équipe jouée dans un autre format pour un match précis (V1-FOR-08), par exemple une équipe
  /// 6x6 en tournoi 4x4. Même format : équipe inchangée. Autre format : le minimum de femmes reprend
  /// la valeur par défaut du nouveau format, car celui de l'équipe ne vaut que pour son format.
  Team withFormat(GameFormat format) => format == this.format
      ? this
      : Team(
          id: id,
          name: name,
          format: format,
          gender: gender,
          category: category,
          players: players,
          season: season,
          color: color,
        );
}
