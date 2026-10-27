package fr.hasteria.tempsmort.domain

/**
 * Point d'entrée des écrans : garde la liste d'événements, expose l'état courant,
 * refuse les actions illégales et annule sans limite. Utilisé tel quel par Android et iOS.
 */
class MatchSession(team: Team, rules: MatchRules = MatchRules.defaultFor(team.format), events: List<MatchEvent> = emptyList()) {
    private val engine = MatchEngine(team, rules)
    private val log = events.toMutableList()

    var state: MatchState = engine.replay(log)
        private set

    val events: List<MatchEvent> get() = log.toList()
    val canUndo: Boolean get() = log.isNotEmpty()

    /** Enregistre l'événement et renvoie null, ou renvoie la raison du refus sans rien changer. */
    fun record(event: MatchEvent): Rejection? {
        engine.check(state, event)?.let { return it }
        state = engine.apply(state, event)
        log += event
        return null
    }

    fun undo() {
        if (log.isEmpty()) return
        log.removeAt(log.lastIndex)
        state = engine.replay(log)
    }

    fun stats(setIndex: Int? = null): MatchStats = computeStats(state.history, setIndex)
}
