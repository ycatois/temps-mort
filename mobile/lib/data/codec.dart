import '../domain/domain.dart';
import 'match_record.dart';

/// Conversion JSON des équipes, matchs et événements pour le stockage local (et plus tard la synchro).
/// Les énumérations sont écrites par leur nom : ne jamais renommer une valeur déjà publiée.

typedef Json = Map<String, Object?>;

Json teamToJson(Team t) => {
      'id': t.id,
      'name': t.name,
      'format': t.format.name,
      'gender': t.gender.name,
      'category': t.category.name,
      'minWomenOnCourt': t.minWomenOnCourt,
      'players': [for (final p in t.players) playerToJson(p)],
    };

Team teamFromJson(Json j) => Team(
      id: j['id']! as String,
      name: j['name']! as String,
      format: GameFormat.values.byName(j['format']! as String),
      gender: TeamGender.values.byName(j['gender']! as String),
      category: AgeCategory.values.byName(j['category']! as String),
      minWomenOnCourt: j['minWomenOnCourt'] as int?,
      players: [for (final p in j['players']! as List<Object?>) playerFromJson(p! as Json)],
    );

Json playerToJson(Player p) => {
      'id': p.id,
      'firstName': p.firstName,
      'number': p.number,
      'gender': p.gender.name,
      'role': p.role.name,
      if (p.archived) 'archived': true,
    };

Player playerFromJson(Json j) => Player(
      id: j['id']! as String,
      firstName: j['firstName']! as String,
      number: j['number']! as int,
      gender: PlayerGender.values.byName(j['gender']! as String),
      role: Role.values.byName(j['role']! as String),
      archived: j['archived'] as bool? ?? false,
    );

Json rulesToJson(MatchRules r) => {
      'setsToWin': r.setsToWin,
      'pointsPerSet': r.pointsPerSet,
      'pointsDecidingSet': r.pointsDecidingSet,
      'minLead': r.minLead,
      'substitutionsPerSet': r.substitutionsPerSet,
      'timeoutsPerSet': r.timeoutsPerSet,
      'liberoAllowed': r.liberoAllowed,
      'pairedSubstitutions': r.pairedSubstitutions,
    };

MatchRules rulesFromJson(Json j) => MatchRules(
      setsToWin: j['setsToWin']! as int,
      pointsPerSet: j['pointsPerSet']! as int,
      pointsDecidingSet: j['pointsDecidingSet']! as int,
      minLead: j['minLead']! as int,
      substitutionsPerSet: j['substitutionsPerSet'] as int?,
      timeoutsPerSet: j['timeoutsPerSet']! as int,
      liberoAllowed: j['liberoAllowed']! as bool,
      // Absente des matchs enregistrés avant E06 : désactivée, pour que leurs remplacements se rejouent.
      pairedSubstitutions: j['pairedSubstitutions'] as bool? ?? false,
    );

Json matchToJson(MatchRecord m) => {
      'id': m.id,
      'teamId': m.teamId,
      'opponent': m.opponent,
      'date': m.date.toIso8601String(),
      'venue': m.venue,
      'home': m.home,
      'competition': m.competition,
      'format': m.format.name,
      'rules': rulesToJson(m.rules),
    };

MatchRecord matchFromJson(Json j) => MatchRecord(
      id: j['id']! as String,
      teamId: j['teamId']! as String,
      opponent: j['opponent']! as String,
      date: DateTime.parse(j['date']! as String),
      venue: j['venue'] as String? ?? '',
      home: j['home'] as bool? ?? true,
      competition: j['competition'] as String? ?? '',
      format: GameFormat.values.byName(j['format']! as String),
      rules: rulesFromJson(j['rules']! as Json),
    );

Json eventToJson(MatchEvent e) => switch (e) {
      StartSet() => {
          'type': 'startSet',
          'firstServer': e.firstServer.name,
          'lineup': e.lineup,
          if (e.liberoId != null) 'liberoId': e.liberoId,
          if (e.captainId != null) 'captainId': e.captainId,
          if (e.system != null) 'system': e.system!.name,
        },
      Rally() => {
          'type': 'rally',
          'winner': e.winner.name,
          if (e.playerId != null) 'playerId': e.playerId,
          if (e.action != null) 'action': e.action!.name,
        },
      Substitution() => {'type': 'substitution', 'outId': e.outId, 'inId': e.inId},
      LiberoIn() => {'type': 'liberoIn', 'replacedId': e.replacedId},
      LiberoOut() => {'type': 'liberoOut'},
      TimeoutTaken() => {'type': 'timeout', 'side': e.side.name},
    };

MatchEvent eventFromJson(Json j) {
  Side side(String key) => Side.values.byName(j[key]! as String);
  final type = j['type']! as String;
  return switch (type) {
    'startSet' => StartSet(
        side('firstServer'),
        [for (final id in j['lineup']! as List<Object?>) id! as String],
        liberoId: j['liberoId'] as String?,
        captainId: j['captainId'] as String?,
        system: j['system'] == null ? null : GameSystem.values.byName(j['system']! as String),
      ),
    'rally' => Rally(
        side('winner'),
        playerId: j['playerId'] as String?,
        action: j['action'] == null ? null : RallyAction.values.byName(j['action']! as String),
      ),
    'substitution' => Substitution(j['outId']! as String, j['inId']! as String),
    'liberoIn' => LiberoIn(j['replacedId']! as String),
    'liberoOut' => const LiberoOut(),
    'timeout' => TimeoutTaken(side('side')),
    _ => throw FormatException('Événement inconnu : $type'),
  };
}

Json templateToJson(LineupTemplate t) => {
      'teamId': t.teamId,
      'format': t.format.name,
      'lineup': t.lineup,
      if (t.liberoId != null) 'liberoId': t.liberoId,
      if (t.captainId != null) 'captainId': t.captainId,
      if (t.system != null) 'system': t.system!.name,
    };

LineupTemplate templateFromJson(Json j) => LineupTemplate(
      teamId: j['teamId']! as String,
      format: GameFormat.values.byName(j['format']! as String),
      lineup: [for (final id in j['lineup']! as List<Object?>) id! as String],
      liberoId: j['liberoId'] as String?,
      captainId: j['captainId'] as String?,
      system: j['system'] == null ? null : GameSystem.values.byName(j['system']! as String),
    );
