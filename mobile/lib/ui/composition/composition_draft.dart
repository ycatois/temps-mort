/// Composition en cours de saisie sur l'écran E04 : qui est sur quelle zone.
/// Aucune règle du volley ici (elles sont dans lib/domain) : seulement les gestes de placement.
class CompositionDraft {
  CompositionDraft(int size, {List<String>? lineup})
      : slots = List<String?>.generate(size, (i) => lineup != null && i < lineup.length ? lineup[i] : null);

  /// Index 0 = poste 1 (zone 1 en 6x6), comme dans StartSet.
  final List<String?> slots;

  bool get complete => !slots.contains(null);
  List<String> get lineup => [for (final id in slots) id!];
  List<int> get emptySlots => [for (var i = 0; i < slots.length; i++) if (slots[i] == null) i];

  bool onCourt(String id) => slots.contains(id);

  /// Place [id] à l'index [slot]. Venue d'une autre zone, elle échange sa place avec l'occupante ;
  /// venue du banc, l'occupante retourne sur le banc.
  void place(String id, int slot) {
    final from = slots.indexOf(id);
    final occupant = slots[slot];
    if (from >= 0) slots[from] = occupant;
    slots[slot] = id;
  }

  /// Renvoie sur le banc.
  void remove(String id) {
    final i = slots.indexOf(id);
    if (i >= 0) slots[i] = null;
  }

  /// Remplace toute la composition (chargement d'une composition type). Les inconnues sont ignorées.
  void load(List<String> lineup, bool Function(String id) available) {
    for (var i = 0; i < slots.length; i++) {
      slots[i] = i < lineup.length && available(lineup[i]) ? lineup[i] : null;
    }
  }
}
