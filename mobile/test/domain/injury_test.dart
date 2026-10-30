import 'package:flutter_test/flutter_test.dart';
import 'package:temps_mort/data/codec.dart';
import 'package:temps_mort/demo/demo_team.dart';
import 'package:temps_mort/domain/domain.dart';

/// Un seul remplacement par set et sets de 3 points, pour atteindre vite les limites.
final rules = MatchRules.defaultFor(GameFormat.six).copyWith(substitutionsPerSet: 1, pointsPerSet: 3);

/// Emma sort pour Zoé : le seul remplacement du set est utilisé.
MatchSession quotaReached() {
  final s = MatchSession(demoTeam, rules: rules, events: [demoStartSet]);
  expect(s.record(const Substitution('emma', 'zoe')), isNull);
  return s;
}

void main() {
  group('remplacement exceptionnel sur blessure (FIVB 15.7)', () {
    test('remplacement normal possible : c\'est lui qui est choisi, il compte', () {
      final s = MatchSession(demoTeam, rules: rules, events: [demoStartSet]);
      expect(s.injuryReplacement('lucie', 'zoe'), isA<Substitution>());
    });

    test('quota atteint : remplacement exceptionnel, hors quota, la blessée ne revient plus', () {
      final s = quotaReached();
      expect(s.check(const Substitution('lucie', 'emma')), const NoSubstitutionLeft());
      final event = s.injuryReplacement('lucie', 'emma');
      expect(event, isA<InjurySubstitution>());
      expect(s.record(event), isNull);
      expect(s.state.lineup, contains('emma'));
      expect(s.state.lineup, isNot(contains('lucie')));
      expect(s.state.substitutionsUsed, 1, reason: 'hors quota');
      expect(s.state.excluded, {'lucie'});
    });

    test('règle du couple : une titulaire déjà sortie peut sortir blessée par un remplacement exceptionnel', () {
      final s = MatchSession(demoTeam, events: [demoStartSet]); // 6 remplacements, règle du couple
      s.record(const Substitution('emma', 'zoe'));
      s.record(const Substitution('zoe', 'emma'));
      expect(s.check(const Substitution('emma', 'zoe')), isA<StarterAlreadyLeft>());
      expect(s.injuryReplacement('emma', 'zoe'), isA<InjurySubstitution>());
      expect(s.record(s.injuryReplacement('emma', 'zoe')), isNull);
    });

    test('la blessée ne rejoue plus du match, même au set suivant', () {
      final s = quotaReached();
      s.record(s.injuryReplacement('lucie', 'emma'));
      expect(s.check(const InjurySubstitution('zoe', 'lucie')), const InjuredCannotReturn('lucie'));
      for (var i = 0; i < 3; i++) {
        s.record(const Rally(Side.us));
      }
      expect(s.state.phase, Phase.awaitingSet);
      // Le set précédent commençait avec Lucie : il faut recomposer.
      final same = s.nextSetStart()!;
      expect(s.check(same), const InjuredCannotReturn('lucie'));
      final lineup = [for (final id in same.lineup) id == 'lucie' ? 'zoe' : id];
      expect(s.check(StartSet(same.firstServer, lineup, liberoId: 'jade')), isNull);
      expect(s.check(StartSet(same.firstServer, lineup, liberoId: 'lucie')), const InjuredCannotReturn('lucie'));
    });

    test('ni les liberos ni la joueuse remplacée par le libero', () {
      final s = quotaReached();
      expect(s.check(const InjurySubstitution('lucie', 'jade')), const LiberoCannotBeSubstituted());
      s.record(const LiberoIn('lucie'));
      expect(s.check(const InjurySubstitution('jade', 'emma')), const LiberoCannotBeSubstituted());
      expect(s.check(const InjurySubstitution('manon', 'lucie')), const LiberoCannotBeSubstituted());
    });

    test('aller-retour JSON et joueuses concernées', () {
      const e = InjurySubstitution('lucie', 'emma');
      expect(eventToJson(eventFromJson(eventToJson(e))), eventToJson(e));
      expect(playersInvolved([demoStartSet, e]), containsAll(['lucie', 'emma']));
    });
  });

  test('retour à la place d\'origine activé par défaut en 6x6, donc chez les jeunes (M15, M18, M21)', () {
    for (final category in [AgeCategory.m15, AgeCategory.m18, AgeCategory.m21]) {
      expect(category.suggestedFormat, GameFormat.six);
      expect(MatchRules.defaultFor(category.suggestedFormat).pairedSubstitutions, isTrue, reason: category.label);
    }
  });
}
