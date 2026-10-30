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

    test('une équipe 6x6 mixte jouée en 4x4 reprend le minimum de femmes du 4x4', () {
      final team = mixed(GameFormat.six, minWomen: 3);
      expect(team.withFormat(GameFormat.six), same(team));
      final four = team.withFormat(GameFormat.four);
      expect(four.format, GameFormat.four);
      expect(four.minWomenOnCourt, 2);
      expect(four.players, team.players);
    });
  });

  group('Effectif', () {
    test('une joueuse archivée sort des joueuses disponibles mais reste connue', () {
      final team = Team(
        id: 't',
        name: 'M15',
        format: GameFormat.six,
        gender: TeamGender.feminine,
        category: AgeCategory.m15,
        players: const [
          Player(id: 'a', firstName: 'Anna', number: 1, gender: PlayerGender.f),
          Player(id: 'b', firstName: 'Bea', number: 2, gender: PlayerGender.f, archived: true),
        ],
      );
      expect(team.activePlayers.map((p) => p.id), ['a']);
      expect(team.player('b')?.firstName, 'Bea');
    });
  });

  group('Alertes de composition (6x6)', () {
    // Deux passeuses (Léa 14, Camille 11) et une libero de poste (Jade) dans l'effectif.
    final team = Team(
      id: 't',
      name: 'M18 F',
      format: GameFormat.six,
      gender: TeamGender.feminine,
      category: AgeCategory.m18,
      players: const [
        Player(id: 'lea', firstName: 'Léa', number: 14, gender: PlayerGender.f, role: Role.passeur),
        Player(id: 'camille', firstName: 'Camille', number: 11, gender: PlayerGender.f, role: Role.passeur),
        Player(id: 'jade', firstName: 'Jade', number: 1, gender: PlayerGender.f, role: Role.libero),
        Player(id: 'a', firstName: 'Anna', number: 2, gender: PlayerGender.f),
        Player(id: 'b', firstName: 'Bea', number: 3, gender: PlayerGender.f),
        Player(id: 'c', firstName: 'Cleo', number: 4, gender: PlayerGender.f),
        Player(id: 'd', firstName: 'Dina', number: 5, gender: PlayerGender.f),
      ],
    );

    test('5-1 avec une passeuse : rien à signaler', () {
      expect(lineupWarnings(team, ['lea', 'a', 'b', 'c', 'd', 'jade'], GameSystem.s51), isEmpty);
    });

    test('5-1 avec deux passeuses : alerte', () {
      expect(lineupWarnings(team, ['lea', 'camille', 'a', 'b', 'c', 'd'], GameSystem.s51),
          [const SetterCount(GameSystem.s51, 2)]);
    });

    test('4-2 : les passeuses doivent être opposées, pas côte à côte', () {
      expect(lineupWarnings(team, ['lea', 'a', 'b', 'camille', 'c', 'd'], GameSystem.s42), isEmpty);
      expect(lineupWarnings(team, ['lea', 'camille', 'a', 'b', 'c', 'd'], GameSystem.s62),
          [const SettersNotOpposite('lea', 'camille')]);
      expect(lineupWarnings(team, ['lea', 'a', 'b', 'c', 'd', 'jade'], GameSystem.s42),
          [const SetterCount(GameSystem.s42, 1)]);
    });

    test('une libero de poste placée en zone avant est signalée', () {
      expect(lineupWarnings(team, ['lea', 'a', 'jade', 'b', 'c', 'd'], null), [const LiberoRoleInFrontRow('jade')]);
    });

    test('rien à contrôler hors 6x6', () {
      expect(lineupWarnings(team.withFormat(GameFormat.four), ['lea', 'camille', 'a', 'b'], GameSystem.s51), isEmpty);
    });

    test('capitaine et système accompagnent le début de set sans changer le jeu', () {
      final s = MatchSession(team);
      final start = StartSet(Side.us, const ['lea', 'a', 'b', 'c', 'd', 'jade'], captainId: 'a', system: GameSystem.s51);
      expect(s.record(start), isNull);
      expect(start.withFirstServer(Side.them).captainId, 'a');
      expect(start.withFirstServer(Side.them).system, GameSystem.s51);
    });
  });

  group('Retour à la place d\'origine (règle du couple)', () {
    // Titulaires : manon, chloe, emma, ines, lucie, lea. Banc : zoe ; jade est libero.
    MatchSession started() => session()..record(StartSet(Side.us, start, liberoId: 'jade'));

    test('activée par défaut en 6x6 seulement', () {
      expect(MatchRules.defaultFor(GameFormat.six).pairedSubstitutions, isTrue);
      expect(MatchRules.defaultFor(GameFormat.four).pairedSubstitutions, isFalse);
    });

    test('la titulaire revient à sa place, à la place de sa remplaçante', () {
      final s = started();
      expect(s.record(const Substitution('emma', 'zoe')), isNull);
      expect(s.state.lineup[2], 'zoe');
      expect(s.state.partnerOf('zoe'), 'emma');
      expect(s.record(const Substitution('zoe', 'emma')), isNull);
      expect(s.state.lineup[2], 'emma', reason: 'même poste qu\'au départ');
    });

    test('une remplaçante ne peut être remplacée que par sa titulaire', () {
      final s = started()..record(const Substitution('emma', 'zoe'));
      expect(s.record(const Substitution('zoe', 'manon')), isA<AlreadyOnCourt>());
      // Emma ne revient pas à la place de Lucie : sa place est celle de Zoé.
      expect(s.record(const Substitution('lucie', 'emma')), const TypeMatcher<ReturnToOwnPlace>().having((r) => r.substituteId, 'remplaçante', 'zoe'));
    });

    test('une remplaçante ne laisse sa place à personne d\'autre que sa titulaire', () {
      final team = six.copyWith(players: [
        ...six.players,
        const Player(id: 'nina', firstName: 'Nina', number: 4, gender: PlayerGender.f),
      ]);
      final s = MatchSession(team)
        ..record(StartSet(Side.us, start, liberoId: 'jade'))
        ..record(const Substitution('emma', 'zoe'));
      expect(
        s.record(const Substitution('zoe', 'nina')),
        const TypeMatcher<OnlyPartnerReturns>().having((r) => r.starterId, 'titulaire', 'emma'),
      );
      expect(s.record(const Substitution('ines', 'nina')), isNull, reason: 'une autre titulaire peut sortir');
    });

    test('une titulaire ne sort qu\'une fois, une remplaçante n\'entre qu\'une fois', () {
      final s = started()
        ..record(const Substitution('emma', 'zoe'))
        ..record(const Substitution('zoe', 'emma'));
      expect(s.record(const Substitution('emma', 'zoe')), isA<StarterAlreadyLeft>());
      expect(s.record(const Substitution('ines', 'zoe')), isA<SubstituteAlreadyPlayed>());
    });

    test('tout redevient possible au set suivant', () {
      final s = started()
        ..record(const Substitution('emma', 'zoe'))
        ..record(const Substitution('zoe', 'emma'))
        ..win(25);
      s.record(s.nextSetStart()!);
      expect(s.state.substitutions, isEmpty);
      expect(s.record(const Substitution('emma', 'zoe')), isNull);
    });

    test('désactivée : remplacements libres dans la limite du compteur', () {
      final s = session(MatchRules.defaultFor(GameFormat.six).copyWith(pairedSubstitutions: false))
        ..record(StartSet(Side.us, start, liberoId: 'jade'))
        ..record(const Substitution('emma', 'zoe'))
        ..record(const Substitution('zoe', 'emma'));
      expect(s.record(const Substitution('emma', 'zoe')), isNull);
    });

    test('un match enregistré sans le paramètre se rejoue sans la règle', () {
      final s = MatchSession(six, rules: MatchRules.defaultFor(GameFormat.six).copyWith(pairedSubstitutions: false), events: [
        StartSet(Side.us, start, liberoId: 'jade'),
        const Substitution('emma', 'zoe'),
        const Substitution('zoe', 'emma'),
        const Substitution('emma', 'zoe'),
      ]);
      expect(s.state.lineup[2], 'zoe');
    });
  });
}
