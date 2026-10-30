import 'package:flutter_test/flutter_test.dart';
import 'package:temps_mort/domain/domain.dart';

const lineup = ['p1', 'p2', 'p3', 'p4', 'p5', 'p6'];

Stroke line(List<BoardPoint> points, {StrokeTool tool = StrokeTool.pen}) =>
    Stroke(tool: tool, color: StrokeColor.yellow, points: points);

void main() {
  group('pions placés sur la rotation (V1-TAC-01, 02)', () {
    test('6x6 : le poste 1 est arrière droit, le 4 avant gauche, tous dans notre camp', () {
      final board = TacticBoard.forLineup(GameFormat.six, lineup);
      expect(board.players.length, 6);
      final p1 = board.token('p:p1')!.position;
      final p4 = board.token('p:p4')!.position;
      expect(p1.x, greaterThan(0.5));
      expect(p4.x, lessThan(0.5));
      expect(p4.y, lessThan(p1.y), reason: 'la zone 4 est au filet, la zone 1 au fond');
      for (final t in board.players) {
        expect(t.position.y, greaterThan(netY));
      }
    });

    test('après une rotation, chaque joueuse passe à la zone suivante', () {
      final before = TacticBoard.forLineup(GameFormat.six, lineup);
      final after = TacticBoard.forLineup(GameFormat.six, rotate(lineup));
      // p2 était en zone 2 ; elle passe au service, en zone 1.
      expect(after.token('p:p2')!.position, before.token('p:p1')!.position);
    });

    test('4x4 et 2x2 : autant de pions que de joueurs', () {
      expect(TacticBoard.forLineup(GameFormat.four, lineup.sublist(0, 4)).players.length, 4);
      expect(TacticBoard.forLineup(GameFormat.two, lineup.sublist(0, 2)).players.length, 2);
      expect(courtPositions(GameFormat.four).length, 4);
    });

    test('replacer sur la rotation garde les dessins et les adversaires', () {
      final board = TacticBoard.forLineup(GameFormat.six, lineup)
          .moveToken('p:p1', const BoardPoint(0.1, 0.1))
          .addOpponent()
          .addStroke(line(const [BoardPoint(0.2, 0.8), BoardPoint(0.4, 0.6)]))
          .withLineup(rotate(lineup));
      expect(board.token('p:p2')!.position, courtPositions(GameFormat.six).first);
      expect(board.opponents.length, 1);
      expect(board.strokes.length, 1);
    });
  });

  group('déplacer et dessiner (V1-TAC-03 à 05)', () {
    test('un pion déplacé reste dans les limites, marges comprises', () {
      final board = TacticBoard.forLineup(GameFormat.six, lineup).moveToken('p:p1', const BoardPoint(3, -2));
      expect(board.token('p:p1')!.position, const BoardPoint(1 + BoardPoint.marginX, -BoardPoint.marginY));
      // Le serveur peut se placer derrière la ligne de fond.
      final serving = board.moveToken('p:p1', const BoardPoint(0.8, 1.05));
      expect(serving.token('p:p1')!.position.y, 1.05);
    });

    test('un pion inconnu ne change rien', () {
      final board = TacticBoard.forLineup(GameFormat.six, lineup);
      final moved = board.moveToken('inconnu', const BoardPoint(0.5, 0.5));
      expect([for (final t in moved.tokens) t.position], [for (final t in board.tokens) t.position]);
    });

    test('un simple toucher ne fait pas de trait', () {
      final board = TacticBoard(format: GameFormat.six).addStroke(line(const [BoardPoint(0.5, 0.5)]));
      expect(board.strokes, isEmpty);
    });

    test('annuler retire le dernier trait seulement, puis rien', () {
      var board = TacticBoard(format: GameFormat.six)
          .addStroke(line(const [BoardPoint(0.1, 0.9), BoardPoint(0.2, 0.8)]))
          .addStroke(line(const [BoardPoint(0.5, 0.9), BoardPoint(0.6, 0.7)], tool: StrokeTool.zone));
      board = board.undoStroke();
      expect(board.strokes.single.tool, StrokeTool.pen);
      board = board.undoStroke().undoStroke();
      expect(board.strokes, isEmpty);
    });

    test('tout effacer retire traits, adversaires et ballon, garde les joueuses à leur place', () {
      final board = TacticBoard.forLineup(GameFormat.six, lineup)
          .moveToken('p:p3', const BoardPoint(0.5, 0.55))
          .addOpponent()
          .addBall()
          .addStroke(line(const [BoardPoint(0.1, 0.9), BoardPoint(0.2, 0.8)]))
          .clear();
      expect(board.isBlank, isTrue);
      expect(board.players.length, 6);
      expect(board.token('p:p3')!.position, const BoardPoint(0.5, 0.55));
    });
  });

  group('adversaires et ballon (V1-TAC-06)', () {
    test('autant d\'adversaires que de joueurs du format, dans le camp d\'en face', () {
      var board = TacticBoard(format: GameFormat.four);
      for (var i = 0; i < 6; i++) {
        board = board.addOpponent();
      }
      expect(board.opponents.length, 4);
      expect(board.canAddOpponent, isFalse);
      for (final t in board.opponents) {
        expect(t.position.y, lessThan(netY));
      }
      expect({for (final t in board.opponents) t.id}.length, 4, reason: 'identifiants distincts');
    });

    test('un seul ballon', () {
      final board = TacticBoard(format: GameFormat.six).addBall().addBall();
      expect(board.tokens.where((t) => t.kind == TokenKind.ball).length, 1);
      expect(board.hasBall, isTrue);
    });
  });
}
