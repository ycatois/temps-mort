import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../theme/tokens.dart';

/// Ce que fait le doigt sur le terrain : déplacer un pion, ou dessiner avec un des outils.
enum TacticsTool { move, pen, arrow, zone }

extension on TacticsTool {
  StrokeTool? get stroke => switch (this) {
        TacticsTool.move => null,
        TacticsTool.pen => StrokeTool.pen,
        TacticsTool.arrow => StrokeTool.arrow,
        TacticsTool.zone => StrokeTool.zone,
      };
}

Color strokeColor(StrokeColor c) => switch (c) {
      StrokeColor.yellow => TmColor.yellow,
      StrokeColor.red => TmColor.zoneAlert,
      StrokeColor.white => Colors.white,
    };

/// Passage des coordonnées du tableau (voir [BoardPoint]) aux pixels de l'écran.
/// Terrain entier : le camp adverse est dessiné deux fois moins profond, comme dans la maquette,
/// pour laisser de la place à notre camp. Demi-terrain : notre camp seul, filet en haut.
class BoardViewport {
  factory BoardViewport.fit(Size available, {required bool full}) {
    final top = _depth(full ? -BoardPoint.marginY : netY - 0.03);
    final bottom = _depth(1 + BoardPoint.marginY);
    const widthM = (1 + 2 * BoardPoint.marginX) * courtWidthM;
    final scale = math.min(available.width / widthM, available.height / (bottom - top));
    return BoardViewport._(scale, top, Size(widthM * scale, (bottom - top) * scale));
  }

  BoardViewport._(this.scale, this._top, this.size);

  static const double courtWidthM = 9;
  static const double courtLengthM = 18;

  /// Profondeur relative du camp adverse à l'écran.
  static const double farSide = 0.5;

  /// Pixels par mètre.
  final double scale;
  final double _top;

  /// Taille du tableau à l'écran.
  final Size size;

  double get courtWidth => courtWidthM * scale;

  /// Distance au filet en mètres, en négatif côté adverse (compressée).
  static double _depth(double y) => (y - netY) * courtLengthM * (y >= netY ? 1 : farSide);

  Offset toScreen(BoardPoint p) => Offset((p.x + BoardPoint.marginX) * courtWidth, (_depth(p.y) - _top) * scale);

  BoardPoint fromScreen(Offset o) {
    final d = o.dy / scale + _top;
    return BoardPoint(o.dx / courtWidth - BoardPoint.marginX, netY + d / courtLengthM / (d >= 0 ? 1 : farSide));
  }

  /// Diamètre des pions des joueuses : 56 dp au moins, pour les attraper au doigt.
  double get playerSize => (courtWidth * 0.2).clamp(TmTouch.primaryTarget, 84).toDouble();

  double sizeOf(TokenKind kind) => switch (kind) {
        TokenKind.player => playerSize,
        TokenKind.opponent => math.max(44, playerSize * 0.6),
        TokenKind.ball => math.max(36, playerSize * 0.48),
      };
}

/// Le terrain du tableau tactique : pions et dessins, au doigt (V1-TAC-01 à 06, 09).
class TacticsBoardView extends StatefulWidget {
  const TacticsBoardView({
    super.key,
    required this.board,
    required this.team,
    required this.full,
    required this.tool,
    required this.color,
    required this.onChanged,
    this.liberoId,
  });

  final TacticBoard board;
  final Team team;
  final bool full;
  final TacticsTool tool;
  final StrokeColor color;
  final ValueChanged<TacticBoard> onChanged;
  final String? liberoId;

  @override
  State<TacticsBoardView> createState() => _TacticsBoardViewState();
}

class _TacticsBoardViewState extends State<TacticsBoardView> {
  /// Trait en cours de dessin.
  List<BoardPoint>? _drawing;

  /// Pion tenu au doigt, et l'écart entre son centre et le doigt.
  String? _dragged;
  Offset _grab = Offset.zero;

  BoardToken? _hit(BoardViewport v, Offset at) {
    BoardToken? best;
    var bestDistance = double.infinity;
    // Les derniers pions sont dessinés au-dessus : à distance égale, ce sont eux qu'on attrape.
    for (final t in widget.board.tokens.reversed) {
      final reach = math.max(v.sizeOf(t.kind) / 2, TmTouch.minTarget / 2) + 6;
      final d = (v.toScreen(t.position) - at).distance;
      if (d <= reach && d < bestDistance) {
        best = t;
        bestDistance = d;
      }
    }
    return best;
  }

  void _start(BoardViewport v, Offset at) {
    if (widget.tool == TacticsTool.move) {
      final t = _hit(v, at);
      _dragged = t?.id;
      if (t != null) _grab = v.toScreen(t.position) - at;
    } else {
      setState(() => _drawing = [v.fromScreen(at).clamped]);
    }
  }

  void _update(BoardViewport v, Offset at) {
    final dragged = _dragged;
    if (dragged != null) {
      widget.onChanged(widget.board.moveToken(dragged, v.fromScreen(at + _grab)));
    } else if (_drawing != null) {
      setState(() => _drawing = [..._drawing!, v.fromScreen(at).clamped]);
    }
  }

  void _end() {
    final points = _drawing;
    final tool = widget.tool.stroke;
    _dragged = null;
    if (points != null && tool != null) {
      widget.onChanged(widget.board.addStroke(Stroke(tool: tool, color: widget.color, points: points)));
    }
    setState(() => _drawing = null);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final v = BoardViewport.fit(box.biggest, full: widget.full);
      final drawing = _drawing;
      final tool = widget.tool.stroke;
      return Center(
        child: Semantics(
          label: 'Terrain${widget.full ? ' entier' : ', notre camp'} : '
              '${widget.board.tokens.length} pions, ${widget.board.strokes.length} traits',
          child: SizedBox.fromSize(
            size: v.size,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: GestureDetector(
                key: const Key('tactics-board'),
                behavior: HitTestBehavior.opaque,
                dragStartBehavior: DragStartBehavior.down,
                onPanStart: (d) => _start(v, d.localPosition),
                onPanUpdate: (d) => _update(v, d.localPosition),
                onPanEnd: (_) => _end(),
                onPanCancel: _end,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _BoardPainter(
                          viewport: v,
                          format: widget.board.format,
                          strokes: [
                            ...widget.board.strokes,
                            if (drawing != null && tool != null) Stroke(tool: tool, color: widget.color, points: drawing),
                          ],
                        ),
                      ),
                    ),
                    for (final t in widget.board.tokens) _positioned(v, t),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _positioned(BoardViewport v, BoardToken t) {
    final size = v.sizeOf(t.kind);
    final c = v.toScreen(t.position);
    return Positioned(
      key: ValueKey(t.id),
      left: c.dx - size / 2,
      top: c.dy - size / 2,
      width: size,
      height: size,
      child: IgnorePointer(child: _TokenFace(token: t, team: widget.team, liberoId: widget.liberoId, size: size)),
    );
  }
}

class _TokenFace extends StatelessWidget {
  const _TokenFace({required this.token, required this.team, required this.liberoId, required this.size});

  final BoardToken token;
  final Team team;
  final String? liberoId;
  final double size;

  @override
  Widget build(BuildContext context) {
    switch (token.kind) {
      case TokenKind.ball:
        return Semantics(
          label: 'Ballon',
          child: Container(
            decoration: BoxDecoration(
              color: TmColor.yellow,
              shape: BoxShape.circle,
              border: Border.all(color: TmColor.navy, width: 2),
            ),
            child: Icon(Icons.sports_volleyball, color: TmColor.navy, size: size * 0.7),
          ),
        );
      case TokenKind.opponent:
        return Semantics(
          label: 'Adversaire',
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: TmColor.error, width: 3),
            ),
            child: Text('A',
                style: TextStyle(color: TmColor.error, fontWeight: FontWeight.w700, fontSize: size * 0.34)),
          ),
        );
      case TokenKind.player:
        final p = team.player(token.playerId ?? '');
        final libero = p != null && (p.id == liberoId || p.role == Role.libero);
        final name = p == null ? '?' : (libero ? '${p.firstName} · L' : p.firstName);
        final fg = libero ? TmColor.navy : Colors.white;
        return Semantics(
          label: p == null ? 'Joueuse inconnue' : '${p.number} ${p.firstName}${libero ? ', libero' : ''}',
          excludeSemantics: true,
          child: Container(
            decoration: BoxDecoration(
              color: libero ? Colors.white : TmColor.navy,
              shape: BoxShape.circle,
              border: Border.all(color: libero ? TmColor.navy : Colors.white, width: 3),
            ),
            padding: const EdgeInsets.all(4),
            child: FittedBox(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(p == null ? '?' : '${p.number}',
                      style: TextStyle(
                          fontFamily: TmFont.display, fontWeight: FontWeight.w700, fontSize: 26, height: 1, color: fg)),
                  Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
                ],
              ),
            ),
          ),
        );
    }
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({required this.viewport, required this.format, required this.strokes});

  final BoardViewport viewport;
  final GameFormat format;
  final List<Stroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final v = viewport;
    canvas.drawRect(Offset.zero & size, Paint()..color = TmColor.courtOut);

    final far = Rect.fromPoints(v.toScreen(const BoardPoint(0, 0)), v.toScreen(const BoardPoint(1, netY)));
    final ours = Rect.fromPoints(v.toScreen(const BoardPoint(0, netY)), v.toScreen(const BoardPoint(1, 1)));
    canvas.drawRect(far, Paint()..color = Color.lerp(TmColor.court, Colors.white, 0.3)!);
    canvas.drawRect(ours, Paint()..color = TmColor.court);

    final line = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(Rect.fromPoints(far.topLeft, ours.bottomRight), line);
    // Ligne des 3 m (6x6 et 4x4 ; pas en 2x2).
    if (format != GameFormat.two) {
      for (final y in [netY - 1 / 6, netY + 1 / 6]) {
        canvas.drawLine(v.toScreen(BoardPoint(0, y)), v.toScreen(BoardPoint(1, y)), line);
      }
    }
    final net = Paint()
      ..color = Colors.white
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(v.toScreen(const BoardPoint(-0.04, netY)), v.toScreen(const BoardPoint(1.04, netY)), net);

    for (final s in strokes) {
      _stroke(canvas, s);
    }
  }

  void _stroke(Canvas canvas, Stroke s) {
    final v = viewport;
    final color = strokeColor(s.color);
    final pts = [for (final p in s.points) v.toScreen(p)];
    if (pts.length < 2) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (s.tool == StrokeTool.zone) {
      final rect = Rect.fromPoints(pts.first, pts.last);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
      canvas.drawRRect(rrect, Paint()..color = color.withValues(alpha: 0.18));
      _dashed(canvas, Path()..addRRect(rrect), paint..strokeWidth = 3);
      return;
    }

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);

    if (s.tool == StrokeTool.arrow) {
      // Direction d'arrivée : depuis un point assez éloigné de la fin pour ne pas trembler.
      final end = pts.last;
      var from = pts[pts.length - 2];
      for (final p in pts.reversed) {
        if ((end - p).distance > 14) {
          from = p;
          break;
        }
      }
      final angle = (end - from).direction;
      const head = 18.0;
      final head1 = end - Offset.fromDirection(angle - 0.5, head);
      final head2 = end - Offset.fromDirection(angle + 0.5, head);
      canvas.drawPath(
        Path()
          ..moveTo(head1.dx, head1.dy)
          ..lineTo(end.dx, end.dy)
          ..lineTo(head2.dx, head2.dy),
        paint,
      );
    }
  }

  void _dashed(Canvas canvas, Path path, Paint paint) {
    for (final PathMetric m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 16) {
        canvas.drawPath(m.extractPath(d, math.min(d + 9, m.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_BoardPainter old) => true;
}
