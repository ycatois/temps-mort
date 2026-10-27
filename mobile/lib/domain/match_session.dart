import 'match.dart';
import 'match_rules.dart';
import 'stats.dart';
import 'team.dart';

/// Point d'entrée des écrans : garde la liste d'événements, expose l'état courant,
/// refuse les actions illégales et annule sans limite.
class MatchSession {
  MatchSession(Team team, {MatchRules? rules, List<MatchEvent> events = const []})
      : _engine = MatchEngine(team, rules),
        _log = [...events] {
    _state = _engine.replay(_log);
  }

  final MatchEngine _engine;
  final List<MatchEvent> _log;
  late MatchState _state;

  MatchState get state => _state;
  List<MatchEvent> get events => List.unmodifiable(_log);

  /// On n'annule pas le début du premier set : il vient de l'écran Composition, pas d'une saisie de match.
  bool get canUndo => _log.length > 1;

  /// Enregistre l'événement et renvoie null, ou renvoie la raison du refus sans rien changer.
  Rejection? record(MatchEvent event) {
    final rejection = _engine.check(_state, event);
    if (rejection != null) return rejection;
    _state = _engine.apply(_state, event);
    _log.add(event);
    return null;
  }

  void undo() {
    if (!canUndo) return;
    _log.removeLast();
    _state = _engine.replay(_log);
  }

  /// Le prochain set est-il le set décisif ? Son premier service se tire au sort : le coach doit choisir.
  bool get nextSetIsDeciding => _state.phase == Phase.awaitingSet && _state.setIndex == _state.rules.maxSets - 1;

  /// Début du set suivant proposé par défaut : même composition et même libero que le set précédent.
  /// Service : [firstServer] s'il est donné (obligatoire en pratique pour le set décisif, tiré au sort),
  /// sinon l'équipe qui a reçu en premier au set précédent. Null si aucun set n'est à démarrer.
  StartSet? nextSetStart({Side? firstServer}) {
    if (_state.phase != Phase.awaitingSet) return null;
    for (final e in _log.reversed) {
      if (e is StartSet) return e.withFirstServer(firstServer ?? e.firstServer.other);
    }
    return null;
  }

  MatchStats stats({int? setIndex}) => computeStats(_state.history, setIndex: setIndex);
}
