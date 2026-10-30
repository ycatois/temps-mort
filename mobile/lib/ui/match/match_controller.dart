import 'package:flutter/foundation.dart';

import '../../domain/domain.dart';

/// État de l'écran Match en direct (E05). Toute la logique vit dans lib/domain ;
/// ici on relaie les gestes du coach et on prévient l'interface.
/// Après chaque saisie et chaque annulation, [onEventsChanged] reçoit la liste complète des
/// événements pour l'enregistrer sur l'appareil (V1-TEC-02).
class MatchController extends ChangeNotifier {
  MatchController(
    this.team, {
    MatchRules? rules,
    required List<MatchEvent> events,
    this.onEventsChanged,
    bool fullInput = false,
    this.onFullInputChanged,
  })  : _session = MatchSession(team, rules: rules, events: events),
        _fullInput = fullInput;

  final Team team;
  final ValueChanged<List<MatchEvent>>? onEventsChanged;
  final ValueChanged<bool>? onFullInputChanged;
  bool _fullInput;
  final MatchSession _session;
  String? _selectedPlayerId;
  Rejection? _lastRejection;

  MatchState get state => _session.state;
  List<MatchEvent> get events => _session.events;
  String? get selectedPlayerId => _selectedPlayerId;
  Rejection? get lastRejection => _lastRejection;
  bool get canUndo => _session.canUndo;
  bool get canStartNextSet => _session.nextSetStart() != null;
  bool get nextSetIsDeciding => _session.nextSetIsDeciding;

  /// Saisie complète : chaque geste d'une joueuse est noté, y compris ceux qui ne terminent pas l'échange.
  bool get fullInput => _fullInput;

  void setFullInput(bool value) {
    if (value == _fullInput) return;
    _fullInput = value;
    _selectedPlayerId = null;
    onFullInputChanged?.call(value);
    notifyListeners();
  }

  /// Saisie complète : geste en jeu de la joueuse choisie (réception notée, attaque en jeu…).
  void touch(TouchKind kind) {
    final id = _selectedPlayerId;
    if (id == null) return;
    _record(Touch(id, kind));
    _selectedPlayerId = null;
    notifyListeners();
  }

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

  /// Raison pour laquelle [event] serait refusé maintenant, ou null (pour griser les choix impossibles).
  Rejection? check(MatchEvent event) => _session.check(event);

  /// Joueuses sur le banc qui peuvent entrer : ni sur le terrain, ni libero, ni remplacée par le libero.
  List<Player> get bench => [
        for (final p in team.activePlayers)
          if (!state.lineup.contains(p.id) && p.id != state.liberoId && p.id != state.liberoReplacing) p,
      ]..sort((a, b) => a.number.compareTo(b.number));

  /// E06 : remplacement (V1-MAT-04). Renvoie le refus éventuel, sans rien changer dans ce cas.
  Rejection? substitute(String outId, String inId) => _record(Substitution(outId, inId));

  /// E06 : entrée du libero à la place d'une joueuse arrière, et sortie (V1-MAT-05).
  Rejection? liberoIn(String replacedId) => _record(LiberoIn(replacedId));
  Rejection? liberoOut() => _record(const LiberoOut());

  /// Proposition pour le set suivant (composition du set précédent), ou null si aucun set n'est à démarrer.
  StartSet? get suggestedNextSet => _session.nextSetStart();

  /// Set suivant avec une composition choisie sur l'écran E04.
  void startSet(StartSet start) => _record(start);

  void undo() {
    _selectedPlayerId = null;
    _session.undo();
    _lastRejection = null;
    onEventsChanged?.call(_session.events);
    notifyListeners();
  }

  ({int number, String name}) label(String id) {
    final p = team.player(id);
    return p == null ? (number: 0, name: '?') : (number: p.number, name: p.firstName);
  }

  Rejection? _record(MatchEvent event) {
    _lastRejection = _session.record(event);
    if (_lastRejection == null) onEventsChanged?.call(_session.events);
    notifyListeners();
    return _lastRejection;
  }
}
