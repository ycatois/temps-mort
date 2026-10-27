import 'lineup.dart';
import 'match_rules.dart';
import 'team.dart';

enum Side {
  us,
  them;

  Side get other => this == us ? them : us;
}

/// Action ayant conclu l'échange (facultative en mode simple).
enum RallyAction {
  ace('Ace', true),
  attaque('Attaque', true),
  contre('Contre', true),
  fauteAdverse('Faute adverse', true),
  serviceFaute('Faute de service', false),
  attaqueFaute('Attaque out / bloquée', false),
  receptionFaute('Réception ratée', false),
  autreFaute('Autre faute', false);

  const RallyAction(this.label, this.scoring);
  final String label;

  /// true = le point est pour nous (action gagnante ou faute adverse).
  final bool scoring;
}

// ---------------------------------------------------------------------------
// Événements : un match est une liste d'événements ; l'état se recalcule en les rejouant.
// Annuler = retirer le dernier. Synchroniser = envoyer la liste.
// ---------------------------------------------------------------------------

sealed class MatchEvent {
  const MatchEvent();
}

/// Début de set : qui sert en premier et la composition (index 0 = poste 1).
final class StartSet extends MatchEvent {
  StartSet(this.firstServer, List<String> lineup, {this.liberoId}) : lineup = List.unmodifiable(lineup);
  final Side firstServer;
  final List<String> lineup;
  final String? liberoId;

  StartSet withFirstServer(Side side) => StartSet(side, lineup, liberoId: liberoId);

  @override
  bool operator ==(Object other) =>
      other is StartSet &&
      other.firstServer == firstServer &&
      other.liberoId == liberoId &&
      _sameList(other.lineup, lineup);
  @override
  int get hashCode => Object.hash(firstServer, liberoId, Object.hashAll(lineup));
}

final class Rally extends MatchEvent {
  const Rally(this.winner, {this.playerId, this.action});
  final Side winner;
  final String? playerId;
  final RallyAction? action;
}

final class Substitution extends MatchEvent {
  const Substitution(this.outId, this.inId);
  final String outId;
  final String inId;
}

final class LiberoIn extends MatchEvent {
  const LiberoIn(this.replacedId);
  final String replacedId;
}

final class LiberoOut extends MatchEvent {
  const LiberoOut();
}

final class TimeoutTaken extends MatchEvent {
  const TimeoutTaken(this.side);
  final Side side;
}

bool _sameList(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

// ---------------------------------------------------------------------------
// État
// ---------------------------------------------------------------------------

class Score {
  const Score([this.us = 0, this.them = 0]);
  final int us;
  final int them;

  int operator [](Side side) => side == Side.us ? us : them;
  Score plus(Side side) => side == Side.us ? Score(us + 1, them) : Score(us, them + 1);

  @override
  bool operator ==(Object other) => other is Score && other.us == us && other.them == them;
  @override
  int get hashCode => Object.hash(us, them);
  @override
  String toString() => '$us–$them';
}

enum Phase { awaitingSet, inPlay, finished }

/// Trace d'un échange, base de toutes les statistiques. [rotation] = R1..Rn depuis le début du set.
class RallyRecord {
  const RallyRecord({
    required this.setIndex,
    required this.server,
    required this.rotation,
    required this.winner,
    this.playerId,
    this.action,
  });
  final int setIndex;
  final Side server;
  final int rotation;
  final Side winner;
  final String? playerId;
  final RallyAction? action;
}

class MatchState {
  const MatchState({
    required this.rules,
    this.phase = Phase.awaitingSet,
    this.setsDone = const [],
    this.score = const Score(),
    this.serving = Side.us,
    this.lineup = const [],
    this.rotation = 1,
    this.liberoId,
    this.liberoReplacing,
    this.substitutionsUsed = 0,
    this.timeoutsUsed = const Score(),
    this.history = const [],
  });

  final MatchRules rules;
  final Phase phase;
  final List<Score> setsDone;
  final Score score;
  final Side serving;

  /// Joueurs sur le terrain, index 0 = poste 1 (serveur quand on a le service).
  final List<String> lineup;
  final int rotation;
  final String? liberoId;

  /// Joueur remplacé par le libero (sur le banc tant que le libero est en jeu).
  final String? liberoReplacing;
  final int substitutionsUsed;
  final Score timeoutsUsed;
  final List<RallyRecord> history;

  int get setIndex => setsDone.length;

  Score get setsWon => setsDone.fold(const Score(), (acc, s) => acc.plus(s.us > s.them ? Side.us : Side.them));

  Side? get winner {
    if (phase != Phase.finished) return null;
    final won = setsWon;
    return won.us > won.them ? Side.us : Side.them;
  }

  int? get substitutionsLeft {
    final limit = rules.substitutionsPerSet;
    return limit == null ? null : limit - substitutionsUsed;
  }

  int timeoutsLeft(Side side) => rules.timeoutsPerSet - timeoutsUsed[side];

  static const Object _keep = Object();

  MatchState copyWith({
    Phase? phase,
    List<Score>? setsDone,
    Score? score,
    Side? serving,
    List<String>? lineup,
    int? rotation,
    Object? liberoId = _keep,
    Object? liberoReplacing = _keep,
    int? substitutionsUsed,
    Score? timeoutsUsed,
    List<RallyRecord>? history,
  }) =>
      MatchState(
        rules: rules,
        phase: phase ?? this.phase,
        setsDone: setsDone ?? this.setsDone,
        score: score ?? this.score,
        serving: serving ?? this.serving,
        lineup: lineup ?? this.lineup,
        rotation: rotation ?? this.rotation,
        liberoId: identical(liberoId, _keep) ? this.liberoId : liberoId as String?,
        liberoReplacing: identical(liberoReplacing, _keep) ? this.liberoReplacing : liberoReplacing as String?,
        substitutionsUsed: substitutionsUsed ?? this.substitutionsUsed,
        timeoutsUsed: timeoutsUsed ?? this.timeoutsUsed,
        history: history ?? this.history,
      );
}

// ---------------------------------------------------------------------------
// Refus : chaque action illégale a une raison lisible par le coach.
// ---------------------------------------------------------------------------

sealed class Rejection {
  const Rejection();
  String get message;
  @override
  String toString() => message;
}

final class SetNotStarted extends Rejection {
  const SetNotStarted();
  @override
  String get message => "Le set n'a pas commencé.";
}

final class SetInProgress extends Rejection {
  const SetInProgress();
  @override
  String get message => 'Un set est déjà en cours.';
}

final class MatchFinished extends Rejection {
  const MatchFinished();
  @override
  String get message => 'Le match est terminé.';
}

final class InvalidLineup extends Rejection {
  const InvalidLineup(this.issues);
  final List<LineupIssue> issues;
  @override
  String get message => 'Composition invalide : ${issues.join(', ')}';
}

final class NoSubstitutionLeft extends Rejection {
  const NoSubstitutionLeft();
  @override
  String get message => 'Plus de remplacement possible dans ce set.';
}

final class NotOnCourt extends Rejection {
  const NotOnCourt(this.playerId);
  final String playerId;
  @override
  String get message => "Cette joueuse n'est pas sur le terrain.";
}

final class AlreadyOnCourt extends Rejection {
  const AlreadyOnCourt(this.playerId);
  final String playerId;
  @override
  String get message => 'Cette joueuse est déjà sur le terrain.';
}

final class UnknownPlayerRejection extends Rejection {
  const UnknownPlayerRejection(this.playerId);
  final String playerId;
  @override
  String get message => "Cette joueuse ne fait pas partie de l'équipe.";
}

final class LiberoNotAllowed extends Rejection {
  const LiberoNotAllowed();
  @override
  String get message => 'Pas de libero dans ce format.';
}

final class LiberoAlreadyIn extends Rejection {
  const LiberoAlreadyIn();
  @override
  String get message => 'Le libero est déjà sur le terrain.';
}

final class LiberoNotIn extends Rejection {
  const LiberoNotIn();
  @override
  String get message => "Le libero n'est pas sur le terrain.";
}

final class LiberoFrontRow extends Rejection {
  const LiberoFrontRow();
  @override
  String get message => 'Le libero ne peut remplacer qu\'une joueuse de la ligne arrière.';
}

final class LiberoCannotServe extends Rejection {
  const LiberoCannotServe();
  @override
  String get message => 'Le libero ne peut pas servir.';
}

final class LiberoCannotBeSubstituted extends Rejection {
  const LiberoCannotBeSubstituted();
  @override
  String get message => 'Le libero et la joueuse qu\'il remplace ne passent pas par un remplacement.';
}

final class NotEnoughWomen extends Rejection {
  const NotEnoughWomen(this.required, this.actual);
  final int required;
  final int actual;
  @override
  String get message => 'Mixité : il faut au moins $required femmes sur le terrain ($actual).';
}

final class NoTimeoutLeft extends Rejection {
  const NoTimeoutLeft();
  @override
  String get message => 'Plus de temps mort dans ce set.';
}

class IllegalMatchEvent implements Exception {
  const IllegalMatchEvent(this.rejection);
  final Rejection rejection;
  @override
  String toString() => 'IllegalMatchEvent: ${rejection.message}';
}

// ---------------------------------------------------------------------------
// Moteur
// ---------------------------------------------------------------------------

class MatchEngine {
  MatchEngine(this.team, [MatchRules? rules]) : rules = rules ?? MatchRules.defaultFor(team.format);

  final Team team;
  final MatchRules rules;

  int get _n => team.format.playersOnCourt;

  MatchState initial() => MatchState(rules: rules);

  MatchState replay(List<MatchEvent> events) {
    var state = initial();
    for (final e in events) {
      state = apply(state, e);
    }
    return state;
  }

  /// Raison du refus, ou null si l'événement est applicable.
  Rejection? check(MatchState state, MatchEvent event) {
    if (state.phase == Phase.finished) return const MatchFinished();
    if (event is StartSet) {
      if (state.phase == Phase.inPlay) return const SetInProgress();
      final libero = event.liberoId;
      if (libero != null && (!rules.liberoAllowed || _n != 6)) return const LiberoNotAllowed();
      if (libero != null && team.player(libero) == null) return UnknownPlayerRejection(libero);
      final issues = validateLineup(team, event.lineup, liberoId: libero);
      return issues.isEmpty ? null : InvalidLineup(issues);
    }
    if (state.phase != Phase.inPlay) return const SetNotStarted();

    return switch (event) {
      Rally() => null,
      final TimeoutTaken t => state.timeoutsLeft(t.side) <= 0 ? const NoTimeoutLeft() : null,
      final Substitution s => _checkSubstitution(state, s),
      final LiberoIn l => _checkLiberoIn(state, l),
      LiberoOut() => state.liberoReplacing == null ? const LiberoNotIn() : null,
      StartSet() => throw StateError('traité plus haut'),
    };
  }

  MatchState apply(MatchState state, MatchEvent event) {
    final rejection = check(state, event);
    if (rejection != null) throw IllegalMatchEvent(rejection);
    return switch (event) {
      final StartSet s => state.copyWith(
          phase: Phase.inPlay,
          serving: s.firstServer,
          lineup: s.lineup,
          rotation: 1,
          liberoId: s.liberoId,
          liberoReplacing: null,
          substitutionsUsed: 0,
          timeoutsUsed: const Score(),
        ),
      final Rally r => _applyRally(state, r),
      final TimeoutTaken t => state.copyWith(timeoutsUsed: state.timeoutsUsed.plus(t.side)),
      final Substitution s => state.copyWith(
          lineup: List.unmodifiable(state.lineup.map((id) => id == s.outId ? s.inId : id)),
          substitutionsUsed: state.substitutionsUsed + 1,
        ),
      final LiberoIn l => state.copyWith(
          lineup: List.unmodifiable(state.lineup.map((id) => id == l.replacedId ? state.liberoId! : id)),
          liberoReplacing: l.replacedId,
        ),
      LiberoOut() => _liberoOut(state),
    };
  }

  MatchState _applyRally(MatchState state, Rally e) {
    final record = RallyRecord(
      setIndex: state.setIndex,
      server: state.serving,
      rotation: state.rotation,
      winner: e.winner,
      playerId: e.playerId,
      action: e.action,
    );
    var next = state.copyWith(score: state.score.plus(e.winner), history: List.unmodifiable([...state.history, record]));

    if (e.winner != state.serving) {
      // Changement de service. Si nous le récupérons, nous tournons.
      next = next.copyWith(serving: e.winner);
      if (e.winner == Side.us) {
        next = next.copyWith(lineup: rotate(next.lineup), rotation: next.rotation % _n + 1);
        // Le libero ne peut pas monter à l'avant : il sort automatiquement.
        final libero = next.liberoId;
        final liberoIndex = libero == null ? -1 : next.lineup.indexOf(libero);
        if (next.liberoReplacing != null && liberoIndex >= 0 && !backRow6x6.contains(liberoIndex)) {
          next = _liberoOut(next);
        }
      }
    }
    return _closeSetIfOver(next);
  }

  MatchState _closeSetIfOver(MatchState state) {
    final target = rules.targetFor(state.setIndex);
    final s = state.score;
    final high = s.us > s.them ? s.us : s.them;
    if (high < target || (s.us - s.them).abs() < rules.minLead) return state;
    // Fin de set : le libero rend sa place, la composition affichée redevient celle des titulaires.
    final done = _liberoOut(state).copyWith(
      setsDone: List.unmodifiable([...state.setsDone, s]),
      score: const Score(),
    );
    final won = done.setsWon;
    final finished = won.us == rules.setsToWin || won.them == rules.setsToWin;
    return done.copyWith(phase: finished ? Phase.finished : Phase.awaitingSet);
  }

  Rejection? _checkSubstitution(MatchState state, Substitution e) {
    final left = state.substitutionsLeft;
    if (left != null && left <= 0) return const NoSubstitutionLeft();
    if (!state.lineup.contains(e.outId)) return NotOnCourt(e.outId);
    if (team.player(e.inId) == null) return UnknownPlayerRejection(e.inId);
    if (state.lineup.contains(e.inId)) return AlreadyOnCourt(e.inId);
    if (e.outId == state.liberoId || e.inId == state.liberoId || e.inId == state.liberoReplacing) {
      return const LiberoCannotBeSubstituted();
    }
    return _womenCheck(state.lineup.map((id) => id == e.outId ? e.inId : id));
  }

  Rejection? _checkLiberoIn(MatchState state, LiberoIn e) {
    final libero = state.liberoId;
    if (libero == null || _n != 6) return const LiberoNotAllowed();
    if (state.liberoReplacing != null) return const LiberoAlreadyIn();
    final idx = state.lineup.indexOf(e.replacedId);
    if (idx < 0) return NotOnCourt(e.replacedId);
    if (!backRow6x6.contains(idx)) return const LiberoFrontRow();
    if (idx == 0 && state.serving == Side.us) return const LiberoCannotServe();
    return _womenCheck(state.lineup.map((id) => id == e.replacedId ? libero : id));
  }

  MatchState _liberoOut(MatchState state) {
    final back = state.liberoReplacing;
    if (back == null) return state;
    return state.copyWith(
      lineup: List.unmodifiable(state.lineup.map((id) => id == state.liberoId ? back : id)),
      liberoReplacing: null,
    );
  }

  Rejection? _womenCheck(Iterable<String> lineup) {
    if (team.gender != TeamGender.mixte) return null;
    final women = lineup.where((id) => team.player(id)?.gender == PlayerGender.f).length;
    return women < team.minWomenOnCourt ? NotEnoughWomen(team.minWomenOnCourt, women) : null;
  }
}
