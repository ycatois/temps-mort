import '../domain/domain.dart';

/// Équipe des maquettes, en attendant les écrans Effectif (E02) et Composition (E04).
final demoTeam = Team(
  id: 'demo',
  name: 'M18 F',
  format: GameFormat.six,
  gender: TeamGender.feminine,
  category: AgeCategory.m18,
  players: const [
    Player(id: 'manon', firstName: 'Manon', number: 5, gender: PlayerGender.f),
    Player(id: 'lucie', firstName: 'Lucie', number: 7, gender: PlayerGender.f),
    Player(id: 'emma', firstName: 'Emma', number: 12, gender: PlayerGender.f, role: Role.central),
    Player(id: 'ines', firstName: 'Inès', number: 3, gender: PlayerGender.f),
    Player(id: 'chloe', firstName: 'Chloé', number: 9, gender: PlayerGender.f),
    Player(id: 'lea', firstName: 'Léa', number: 14, gender: PlayerGender.f, role: Role.passeur),
    Player(id: 'jade', firstName: 'Jade', number: 1, gender: PlayerGender.f, role: Role.libero),
    Player(id: 'zoe', firstName: 'Zoé', number: 10, gender: PlayerGender.f),
  ],
);

final demoStartSet = StartSet(Side.us, const ['manon', 'chloe', 'emma', 'ines', 'lucie', 'lea'], liberoId: 'jade');
