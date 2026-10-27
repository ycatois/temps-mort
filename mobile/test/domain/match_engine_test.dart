import 'package:flutter_test/flutter_test.dart';
import 'package:temps_mort/domain/domain.dart';

// Équipe des maquettes : M18 féminine en 6x6
final six = Team(
  id: 't1',
  name: 'M18 F',
  format: GameFormat.six,
  gender: TeamGender.feminine,
  category: AgeCategory.m18,
  players: const [
    Player(id: 'manon', firstName: 'Manon', number: 5, gender: PlayerGender.f),
    Player(id: 'lucie', firstName: 'Lucie', number: 7, gender: PlayerGender.f),
    Player(id: 'emma', firstName: 'Emma', number: 12, gender: PlayerGender.f),
    Player(id: 'ines', firstName: 'Inès', number: 3, gender: PlayerGender.f),
    Player(id: 'chloe', firstName: 'Chloé', number: 9, gender: PlayerGender.f),
    Player(id: 'lea', firstName: 'Léa', number: 14, gender: PlayerGender.f),
    Player(id: 'jade', firstName: 'Jade', number: 1, gender: PlayerGender.f, role: Role.libero),
    Player(id: 'zoe', firstName: 'Zoé', number: 10, gender: PlayerGender.f),
  ],
);

const start = ['manon', 'chloe', 'emma', 'ines', 'lucie', 'lea']; // postes 1 à 6

MatchSession session([MatchRules? rules]) => MatchSession(six, rules: rules);

extension on MatchSession {
  void win([int times = 1]) {
    for (var i = 0; i < times; i++) {
      record(const Rally(Side.us));
    }
  }

  void lose([int times = 1]) {
    for (var i = 0; i < times; i++) {
      record(const Rally(Side.them));
    }
  }
}

Team mixed(GameFormat format, {int? minWomen}) => Team(
      id: 'mx',
      name: 'Loisir mixte',
      format: format,
      gender: TeamGender.mixte,
      category: AgeCategory.loisir,
      minWomenOnCourt: minWomen,
      players: const [
        Player(id: 'a', firstName: 'Anna', number: 1, gender: PlayerGender.f),
        Player(id: 'b', firstName: 'Bea', number: 2, gender: PlayerGender.f),
        Player(id: 'c', firstName: 'Cyril', number: 3, gender: PlayerGender.m),
        Player(id: 'd', firstName: 'David', number: 4, gender: PlayerGender.m),
        Player(id: 'e', firstName: 'Eric', number: 5, gender: PlayerGender.m),
      ],
    );

void main() {
  group('Moteur de match 6x6', () {
    test('un échange exige un set commencé', () {
      expect(session().record(const Rally(Side.us)), isA<SetNotStarted>());
    });

    test('un side-out gagné fait tourner dans le sens des aiguilles d\'une montre', () {
      final s = session()..record(StartSet(Side.them, start));
      s.win();
      expect(s.state.serving, Side.us);
      expect(s.state.lineup, equals(['chloe', 'emma', 'ines', 'lucie', 'lea', 'manon']));
      expect(s.state.rotation, 2);
    });

    test('un point sur notre service ne fait pas tourner', () {
      final s = session()..record(StartSet(Side.us, start));
      s.win(3);
      expect(s.state.lineup, equals(start));
      expect(s.state.score, const Score(3, 0));
    });

    test('perdre sur notre service donne le service sans rotation', () {
      final s = session()..record(StartSet(Side.us, start));
      s.lose();
      expect(s.state.serving, Side.them);
      expect(s.state.lineup, equals(start));
    });

    test('six rotations ramènent en R1', () {
      final s = session()..record(StartSet(Side.them, start));
      for (var i = 0; i < 6; i++) {
        s.win();
        s.lose();
      }
      expect(s.state.lineup, equals(start));
      expect(s.state.rotation, 1);
    });

    test('un set exige deux points d\'écart', () {
      final s = session()..record(StartSet(Side.us, start));
      s.win(24);
      s.lose(24);
      s.win();
      expect(s.state.phase, Phase.inPlay);
      s.win();
      expect(s.state.phase, Phase.awaitingSet);
      expect(s.state.setsDone, equals([const Score(26, 24)]));
    });

    test('le cinquième set se joue en 15 et termine le match', () {
      final s = session();
      for (var i = 0; i < 4; i++) {
        s.record(StartSet(Side.us, start));
        if (i.isEven) {
          s.win(25);
        } else {
          s.lose(25);
        }
      }
      expect(s.state.setsWon, const Score(2, 2));
      s.record(StartSet(Side.us, start));
      s.win(15);
      expect(s.state.phase, Phase.finished);
      expect(s.state.winner, Side.us);
      expect(s.record(const Rally(Side.us)), isA<MatchFinished>());
    });

    test('les remplacements sont limités par set', () {
      final s = session(MatchRules.defaultFor(GameFormat.six).copyWith(substitutionsPerSet: 1))
        ..record(StartSet(Side.us, start));
      expect(s.record(const Substitution('lea', 'zoe')), isNull);
      expect(s.record(const Substitution('zoe', 'lea')), isA<NoSubstitutionLeft>());
    });

    test('le libero entre en ligne arrière et sort avant de monter au poste 4', () {
      final s = session()..record(StartSet(Side.them, start, liberoId: 'jade'));
      expect(s.record(const LiberoIn('emma')), isA<LiberoFrontRow>()); // poste 3
      expect(s.record(const LiberoIn('lucie')), isNull); // poste 5
      expect(s.state.lineup[4], 'jade');
      s.win(); // rotation : le libero passerait du poste 5 au poste 4, il sort
      expect(s.state.liberoReplacing, isNull);
      expect(s.state.lineup[3], 'lucie');
      expect(s.state.lineup.contains('jade'), isFalse);
    });

    test('le libero ne sert pas', () {
      final s = session()..record(StartSet(Side.us, start, liberoId: 'jade'));
      expect(s.record(const LiberoIn('manon')), isA<LiberoCannotServe>());
    });

    test('les temps morts sont limités', () {
      final s = session()..record(StartSet(Side.us, start));
      s.record(const TimeoutTaken(Side.us));
      s.record(const TimeoutTaken(Side.us));
      expect(s.record(const TimeoutTaken(Side.us)), isA<NoTimeoutLeft>());
      expect(s.record(const TimeoutTaken(Side.them)), isNull);
    });

    test('annuler rejoue le match sans le dernier événement', () {
      final s = session()..record(StartSet(Side.them, start));
      s.win();
      s.undo();
      expect(s.state.lineup, equals(start));
      expect(s.state.score, const Score());
      expect(s.state.serving, Side.them);
    });

    test('le début du premier set ne s\'annule pas', () {
      final s = session()..record(StartSet(Side.us, start));
      s.undo();
      expect(s.state.phase, Phase.inPlay);
    });

    test('le set suivant reprend la composition et alterne le premier serveur', () {
      final s = session();
      expect(s.nextSetStart(), isNull);
      s.record(StartSet(Side.us, start, liberoId: 'jade'));
      expect(s.nextSetStart(), isNull); // set en cours
      s.win(25);
      final next = s.nextSetStart();
      expect(next, StartSet(Side.them, start, liberoId: 'jade'));
      expect(s.record(next!), isNull);
      expect(s.state.setIndex, 1);
    });

    test('fin de set : le libero rend sa place', () {
      final s = session()..record(StartSet(Side.them, start, liberoId: 'jade'));
      s.record(const LiberoIn('lucie'));
      s.lose(25);
      expect(s.state.phase, Phase.awaitingSet);
      expect(s.state.lineup.contains('jade'), isFalse);
      expect(s.state.lineup.contains('lucie'), isTrue);
    });

    test('le set décisif demande de choisir le premier serveur', () {
      final s = session();
      for (var i = 0; i < 4; i++) {
        s.record(i == 0 ? StartSet(Side.us, start) : s.nextSetStart()!);
        if (i.isEven) {
          s.win(25);
        } else {
          s.lose(25);
        }
      }
      expect(s.nextSetIsDeciding, isTrue);
      expect(s.nextSetStart(firstServer: Side.them)!.firstServer, Side.them);
      expect(s.nextSetStart(firstServer: Side.us)!.firstServer, Side.us);
    });

    test('une faute adverse donne le point sans le compter à une joueuse', () {
      final s = session()..record(StartSet(Side.us, start));
      s.record(const Rally(Side.us, playerId: 'lucie', action: RallyAction.fauteAdverse));
      expect(s.state.score, const Score(1, 0));
      expect(s.stats().pointsByPlayer, isEmpty);
    });

    test('stats : side-out, break, joueuses et rotations', () {
      final s = session()..record(StartSet(Side.them, start));
      s.record(const Rally(Side.us, playerId: 'lucie', action: RallyAction.attaque)); // side-out gagné en R1
      s.record(const Rally(Side.us, playerId: 'chloe', action: RallyAction.ace)); // break en R2
      s.record(const Rally(Side.them, playerId: 'chloe', action: RallyAction.serviceFaute));
      final st = s.stats();
      expect(st.sideOutRate, 1.0);
      expect(st.breakRate, 0.5);
      expect(st.pointsByPlayer, equals({'lucie': 1, 'chloe': 1}));
      expect(st.errorsByPlayer, equals({'chloe': 1}));
      expect(st.byRotation[2], const Score(1, 1));
      expect(st.weakestRotation, isNull); // aucune rotation déficitaire
      s.record(const Rally(Side.them)); // l'adversaire sert et marque, toujours en R2
      expect(s.stats().weakestRotation, 2);
    });
  });

  group('Formats et mixité', () {
    test('4x4 mixte : il faut deux femmes', () {
      final team = mixed(GameFormat.four);
      expect(team.minWomenOnCourt, 2);
      expect(validateLineup(team, ['a', 'b', 'c', 'd']), isEmpty);
      expect(validateLineup(team, ['a', 'c', 'd', 'e']).single, isA<NotEnoughWomenInLineup>());
    });

    test('un remplacement ne peut pas casser la mixité', () {
      final s = MatchSession(mixed(GameFormat.four))..record(StartSet(Side.us, ['a', 'b', 'c', 'd']));
      expect(s.record(const Substitution('b', 'e')), isA<NotEnoughWomen>());
      expect(s.record(const Substitution('c', 'e')), isNull);
    });

    test('2x2 : rotation entre les deux joueurs, sets à 21', () {
      final s = MatchSession(mixed(GameFormat.two, minWomen: 1))..record(StartSet(Side.them, ['a', 'c']));
      s.record(const Rally(Side.us));
      expect(s.state.lineup, equals(['c', 'a'])); // Cyril au service
      expect(s.state.rules.pointsPerSet, 21);
    });

    test('pas de libero hors du 6x6', () {
      final s = MatchSession(mixed(GameFormat.four));
      expect(s.record(StartSet(Side.us, ['a', 'b', 'c', 'd'], liberoId: 'e')), isA<LiberoNotAllowed>());
    });

    test('chaque catégorie a un format proposé', () {
      expect(AgeCategory.values.length, 10);
      expect(AgeCategory.m7.suggestedFormat, GameFormat.two);
    });

    test('la taille de la composition est vérifiée', () {
      final issues = validateLineup(mixed(GameFormat.six, minWomen: 0), ['a', 'b']);
      expect(issues.single, const WrongSize(6, 2));
    });
  });
}
