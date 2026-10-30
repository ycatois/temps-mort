import 'team.dart';

/// Tableau tactique (E08) : pions, ballon et traits sur un terrain vu du dessus.
///
/// Coordonnées sur le terrain entier, indépendantes de l'écran : x de 0 (ligne de côté gauche, vue
/// depuis notre camp) à 1 (côté droit) ; y de 0 (fond du camp adverse) à 1 (notre ligne de fond).
/// Le filet est en y = 0,5. On peut sortir un peu du terrain (service, couverture) : voir [BoardPoint.clamped].
class BoardPoint {
  const BoardPoint(this.x, this.y);

  final double x;
  final double y;

  /// Marges autorisées hors du terrain, en fraction de sa largeur (x) et de sa longueur (y).
  static const double marginX = 0.15;
  static const double marginY = 0.1;

  BoardPoint get clamped => BoardPoint(
        x.clamp(-marginX, 1 + marginX).toDouble(),
        y.clamp(-marginY, 1 + marginY).toDouble(),
      );

  /// Même place vue depuis l'autre camp.
  BoardPoint get mirrored => BoardPoint(1 - x, 1 - y);

  @override
  bool operator ==(Object other) => other is BoardPoint && other.x == x && other.y == y;
  @override
  int get hashCode => Object.hash(x, y);
  @override
  String toString() => '(${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)})';
}

/// Le filet, en y.
const double netY = 0.5;

enum TokenKind { player, opponent, ball }

/// Un pion : une joueuse de l'équipe ([playerId]), un adversaire ou le ballon.
class BoardToken {
  const BoardToken({required this.id, required this.kind, required this.position, this.playerId});

  final String id;
  final TokenKind kind;
  final BoardPoint position;
  final String? playerId;

  BoardToken moved(BoardPoint to) => BoardToken(id: id, kind: kind, position: to.clamped, playerId: playerId);
}

/// Outil de dessin (V1-TAC-04) : trait à main levée, trajectoire terminée par une flèche, ou zone
/// rectangulaire entre le premier et le dernier point.
enum StrokeTool { pen, arrow, zone }

/// Les trois couleurs du tableau. Un trait se distingue aussi par sa forme : la couleur n'est jamais
/// la seule information.
enum StrokeColor { yellow, red, white }

class Stroke {
  Stroke({required this.tool, required this.color, required List<BoardPoint> points}) : points = List.unmodifiable(points);

  final StrokeTool tool;
  final StrokeColor color;
  final List<BoardPoint> points;
}

/// Place de chaque poste sur notre demi-terrain, dans l'ordre de la composition (index 0 = poste 1).
/// 6x6 : zones 1 à 6 ; 4x4 : arrière droit, avant droit, avant gauche, arrière gauche (comme l'écran E04) ;
/// 2x2 : côte à côte.
List<BoardPoint> courtPositions(GameFormat format) => switch (format) {
      GameFormat.six => const [
          BoardPoint(5 / 6, 0.86), // zone 1, arrière droit (au service)
          BoardPoint(5 / 6, 0.6), // zone 2, avant droit
          BoardPoint(0.5, 0.6), // zone 3, avant centre
          BoardPoint(1 / 6, 0.6), // zone 4, avant gauche
          BoardPoint(1 / 6, 0.86), // zone 5, arrière gauche
          BoardPoint(0.5, 0.86), // zone 6, arrière centre
        ],
      GameFormat.four => const [
          BoardPoint(0.75, 0.85),
          BoardPoint(0.75, 0.6),
          BoardPoint(0.25, 0.6),
          BoardPoint(0.25, 0.85),
        ],
      GameFormat.two => const [BoardPoint(0.3, 0.75), BoardPoint(0.7, 0.75)],
    };

/// Le tableau : pions et traits. Immuable : chaque geste renvoie un nouveau tableau.
class TacticBoard {
  TacticBoard({required this.format, List<BoardToken> tokens = const [], List<Stroke> strokes = const []})
      : tokens = List.unmodifiable(tokens),
        strokes = List.unmodifiable(strokes);

  /// Pions de [lineup] placés sur leurs zones (V1-TAC-01, 02). [lineup] suit l'ordre de la
  /// composition en cours du match : index 0 = poste 1, donc la rotation est déjà appliquée.
  factory TacticBoard.forLineup(GameFormat format, List<String> lineup) =>
      TacticBoard(format: format, tokens: _playerTokens(format, lineup));

  final GameFormat format;
  final List<BoardToken> tokens;
  final List<Stroke> strokes;

  /// Autant d'adversaires que de joueurs sur le terrain dans ce format (V1-TAC-06).
  int get maxOpponents => format.playersOnCourt;

  Iterable<BoardToken> get players => tokens.where((t) => t.kind == TokenKind.player);
  Iterable<BoardToken> get opponents => tokens.where((t) => t.kind == TokenKind.opponent);
  bool get hasBall => tokens.any((t) => t.kind == TokenKind.ball);
  bool get canAddOpponent => opponents.length < maxOpponents;
  bool get isBlank => strokes.isEmpty && opponents.isEmpty && !hasBall;

  BoardToken? token(String id) {
    for (final t in tokens) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Déplace un pion au doigt (V1-TAC-03). Un pion inconnu ne change rien.
  TacticBoard moveToken(String id, BoardPoint to) =>
      _with(tokens: [for (final t in tokens) t.id == id ? t.moved(to) : t]);

  /// Ajoute un trait ; un simple toucher (moins de deux points) n'en est pas un.
  TacticBoard addStroke(Stroke stroke) {
    if (stroke.points.length < 2) return this;
    return _with(strokes: [
      ...strokes,
      Stroke(tool: stroke.tool, color: stroke.color, points: [for (final p in stroke.points) p.clamped]),
    ]);
  }

  /// Annule le dernier trait (V1-TAC-05).
  TacticBoard undoStroke() => strokes.isEmpty ? this : _with(strokes: strokes.sublist(0, strokes.length - 1));

  /// Tout effacer (V1-TAC-05) : traits, adversaires et ballon. Les joueuses restent où elles sont.
  TacticBoard clear() => _with(tokens: [...players], strokes: const []);

  /// Adversaire suivant, sur sa zone en face de la nôtre ; sans effet quand ils sont tous là.
  TacticBoard addOpponent() {
    if (!canAddOpponent) return this;
    final used = {for (final t in opponents) t.id};
    var n = 1;
    while (used.contains('o$n')) {
      n++;
    }
    final place = courtPositions(format)[(n - 1) % format.playersOnCourt].mirrored;
    return _with(tokens: [...tokens, BoardToken(id: 'o$n', kind: TokenKind.opponent, position: place)]);
  }

  /// Le ballon, au centre de notre camp ; un seul.
  TacticBoard addBall() => hasBall
      ? this
      : _with(tokens: [...tokens, const BoardToken(id: 'ball', kind: TokenKind.ball, position: BoardPoint(0.5, 0.72))]);

  /// Replace les joueuses sur la rotation du match (V1-TAC-02) ; dessins et adversaires sont gardés.
  TacticBoard withLineup(List<String> lineup) =>
      _with(tokens: [..._playerTokens(format, lineup), ...tokens.where((t) => t.kind != TokenKind.player)]);

  TacticBoard _with({List<BoardToken>? tokens, List<Stroke>? strokes}) =>
      TacticBoard(format: format, tokens: tokens ?? this.tokens, strokes: strokes ?? this.strokes);

  static List<BoardToken> _playerTokens(GameFormat format, List<String> lineup) {
    final places = courtPositions(format);
    return [
      for (var i = 0; i < lineup.length && i < places.length; i++)
        BoardToken(id: 'p:${lineup[i]}', kind: TokenKind.player, position: places[i], playerId: lineup[i]),
    ];
  }
}
