import '../domain/domain.dart';

/// Export des données brutes du match en CSV (V1-FIN-04) : une ligne par événement, dans l'ordre de saisie,
/// rejoué depuis le début pour connaître le set, le score et la rotation au moment de chaque échange.
/// Point-virgule et BOM UTF-8 : le fichier s'ouvre directement dans un tableur réglé en français.
String matchCsv(Team team, MatchRules rules, List<MatchEvent> events) {
  final rows = <List<String>>[
    ['Set', 'Échange', 'Score', 'Service', 'Rotation', 'Point pour', 'Numéro', 'Prénom', 'Événement'],
  ];
  final session = MatchSession(team, rules: rules);
  var rally = 0;

  List<String> who(String? id) {
    final p = id == null ? null : team.player(id);
    return [p == null ? '' : '${p.number}', p?.firstName ?? ''];
  }

  String side(Side s) => s == Side.us ? 'nous' : 'adversaire';

  for (final e in events) {
    final before = session.state;
    if (session.record(e) != null) continue; // un événement refusé n'est pas dans le match
    final after = session.state;
    final set = '${before.setIndex + 1}';
    switch (e) {
      case StartSet():
        rally = 0;
        rows.add([
          '${after.setIndex + 1}', '', '0–0', side(e.firstServer), '1', '', '', '', 'Début du set',
        ]);
      case Rally(:final winner, :final playerId, :final action):
        rally++;
        // Le set vient de se terminer : le score final est le dernier set joué.
        final score = after.setIndex > before.setIndex ? after.setsDone.last : after.score;
        rows.add([
          set,
          '$rally',
          '$score',
          side(before.serving),
          '${before.rotation}',
          side(winner),
          ...who(playerId),
          action?.label ?? (winner == Side.us ? 'Point' : 'Point adverse'),
        ]);
      case Touch(:final playerId, :final kind):
        rows.add([set, '${rally + 1}', '${before.score}', side(before.serving), '${before.rotation}', '', ...who(playerId), touchLabel(kind)]);
      case Substitution(:final outId, :final inId):
        final inPlayer = team.player(inId);
        rows.add([
          set, '', '${before.score}', '', '', '', ...who(outId),
          'Remplacement : sort pour ${inPlayer == null ? '?' : '${inPlayer.number} ${inPlayer.firstName}'}',
        ]);
      case LiberoIn(:final replacedId):
        rows.add([set, '', '${before.score}', '', '', '', ...who(replacedId), 'Entrée du libero à sa place']);
      case LiberoOut():
        rows.add([set, '', '${before.score}', '', '', '', '', '', 'Sortie du libero']);
      case LiberoSwap():
        final entering = team.player(after.liberoId ?? '');
        rows.add([
          set, '', '${before.score}', '', '', '', ...who(before.liberoId),
          'Changement de libero : laisse sa place à ${entering == null ? '?' : '${entering.number} ${entering.firstName}'}',
        ]);
      case TimeoutTaken(side: final s):
        rows.add([set, '', '${before.score}', '', '', '', '', '', 'Temps mort ${s == Side.us ? '' : 'adverse'}'.trim()]);
    }
  }
  return '﻿${rows.map((r) => r.map(_cell).join(';')).join('\r\n')}\r\n';
}

/// Libellé d'un geste en jeu, sans ambiguïté hors de la grille de saisie (« En jeu » y désigne deux gestes).
String touchLabel(TouchKind kind) => switch (kind) {
      TouchKind.serveInPlay => 'Service en jeu',
      TouchKind.reception3 => 'Réception notée 3',
      TouchKind.reception2 => 'Réception notée 2',
      TouchKind.reception1 => 'Réception notée 1',
      TouchKind.attackInPlay => 'Attaque en jeu',
      TouchKind.blockTouch => 'Contre touché',
      TouchKind.digOk => 'Défense réussie',
    };

String _cell(String v) =>
    v.contains(';') || v.contains('"') || v.contains('\n') ? '"${v.replaceAll('"', '""')}"' : v;
