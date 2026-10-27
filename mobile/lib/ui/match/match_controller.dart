import 'package:flutter/foundation.dart';

import '../../domain/domain.dart';

/// État de l'écran Match en direct (E05). Toute la logique vit dans lib/domain ;
/// ici on relaie les gestes du coach et on prévient l'interface.
/// TODO V1 : persistance locale des événements (V1-TEC-02) et choix de l'équipe.
class MatchController extends ChangeNotifier {
  MatchController(this.team, StartSet firstSet) : _session = MatchSession(team) {
    _lastRejection = _session.record(firstSet);
  }

  final Team team;
  final MatchSession _session;
  String? _selectedPlayerId;
  Rejection? _lastRejection;

  MatchState get state => _session.state;
  String? get selectedPlayerId => _selectedPlayerId;
  Rejection? get lastRejection => _lastRejection;
  bool get canUndo => _session.canUndo;
  bool get canStartNextSet => _session.nextSetStart() != null;
  bool get nextSetIsDeciding => _session.nextSetIsDeciding;

  void select(String playerId) {
    _selectedPlayerId = _selectedPlayerId == playerId ? null : playerId;
    notifyListeners();
  }

  /// Deux touches : la joueuse (facultatif), puis l'action.
  void action(RallyAction action) {
    _record(Rally(action.scoring ? Side.us : Side.them, playerId: _selectedPlayerId, action: action));
    _selectedPlayerId = null;
    notifyListeners();
  }

  void opponentError() {
    _selectedPlayerId = null;
    _record(const Rally(Side.us, action: RallyAction.fauteAdverse));
  }

  void opponentPoint() {
    _selectedPlayerId = null;
    _record(const Rally(Side.them));
  }

  void timeout() => _record(const TimeoutTaken(Side.us));

  /// Set suivant avec la composition du set précédent (l'écran E04 permettra de la modifier).
  /// [firstServer] : à préciser pour le set décisif (tirage au sort).
  void startNextSet({Side? firstServer}) {
    final next = _session.nextSetStart(firstServer: firstServer);
    if (next != null) _record(next);
  }

  void undo() {
    _selectedPlayerId = null;
    _session.undo();
    _lastRejection = null;
    notifyListeners();
  }

  ({int number, String name}) label(String id) {
    final p = team.player(id);
    return p == null ? (number: 0, name: '?') : (number: p.number, name: p.firstName);
  }

  void _record(MatchEvent event) {
    _lastRejection = _session.record(event);
    notifyListeners();
  }
}
