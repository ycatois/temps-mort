import 'package:flutter/material.dart';

import '../../data/match_record.dart';
import '../../data/store.dart';
import '../../domain/domain.dart';
import '../common/store_scope.dart';
import '../composition/composition_screen.dart';
import '../summary/summary_screen.dart';
import 'match_screen.dart';

/// Un match de la liste, avec son état recalculé depuis ses événements (null = pas encore commencé).
typedef MatchRow = ({MatchRecord record, MatchState? state});

extension MatchRowStatus on MatchRow {
  bool get notStarted => state == null;
  bool get inProgress => state != null && state!.phase != Phase.finished;
  bool get finished => state?.phase == Phase.finished;
}

/// Matchs de l'équipe, du plus récent au plus ancien, chacun rejoué pour connaître son état.
Future<List<MatchRow>> loadMatchRows(AppStore store, Team team) async {
  final rows = <MatchRow>[];
  for (final m in await store.matches(team.id)) {
    final events = await store.events(m.id);
    rows.add((record: m, state: events.isEmpty ? null : MatchSession(m.teamFor(team), rules: m.rules, events: events).state));
  }
  return rows;
}

/// Ouvre un match : pas encore commencé, composition d'abord (E04) ; sinon on le reprend là où il en
/// était (V1-MAT-12). Utilisé depuis l'accueil (E01) et la liste des matchs de l'équipe (E11).
Future<void> openMatch(BuildContext context, Team team, MatchRecord match) async {
  final store = StoreScope.of(context);
  final navigator = Navigator.of(context);
  final playing = match.teamFor(team);
  if ((await store.events(match.id)).isEmpty) {
    final start = await navigator.push<StartSet>(
        MaterialPageRoute(builder: (_) => CompositionScreen(team: playing, rules: match.rules, match: match)));
    if (start == null) return;
    await store.saveEvents(match.id, [start]);
  }
  final events = await store.events(match.id);
  await navigator.push(MaterialPageRoute<void>(
    builder: (_) => MatchScreen(
      team: playing,
      rules: match.rules,
      events: events,
      onEventsChanged: (e) => store.saveEvents(match.id, e),
      fullInput: match.fullInput,
      onFullInputChanged: (v) => store.saveMatch(match.withFullInput(v)),
      opponent: match.opponent,
      date: match.date,
      composeNextSet: (context, suggested, {required setNumber, required serverLocked}) =>
          Navigator.of(context).push<StartSet>(MaterialPageRoute(
        builder: (_) => CompositionScreen(
          team: playing,
          rules: match.rules,
          match: match,
          setNumber: setNumber,
          initial: suggested,
          initialServer: serverLocked ? suggested.firstServer : null,
          serverLocked: serverLocked,
        ),
      )),
    ),
  ));
}

/// Résumé (E10) d'un match commencé, sans passer par l'écran de match.
Future<void> openSummary(BuildContext context, Team team, MatchRecord match) async {
  final navigator = Navigator.of(context);
  final events = await StoreScope.of(context).events(match.id);
  await navigator.push(MaterialPageRoute<void>(
    builder: (_) => SummaryScreen(
      team: match.teamFor(team),
      rules: match.rules,
      events: events,
      opponent: match.opponent,
      date: match.date,
    ),
  ));
}
