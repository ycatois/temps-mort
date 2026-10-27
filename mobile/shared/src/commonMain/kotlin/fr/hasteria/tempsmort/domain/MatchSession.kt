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

    /** On n'annule pas le début du premier set : il vient de l'écran Composition, pas d'une saisie de match. */
    val canUndo: Boolean get() = log.size > 1

    /**
     * Début du set suivant proposé par défaut : même composition et même libero que le set précédent,
     * service à l'équipe qui a reçu en premier au set précédent. Null si aucun set n'est à démarrer.
     * Le coach peut modifier la composition avant de valider (écran E04).
     */
    fun nextSetStart(): MatchEvent.StartSet? {
        if (state.phase != Phase.AWAITING_SET) return null
        val previous = log.lastOrNull { it is MatchEvent.StartSet } as? MatchEvent.StartSet ?: return null
        return previous.copy(firstServer = previous.firstServer.other)
    }

    /** Enregistre l'événement et renvoie null, ou renvoie la raison du refus sans rien changer. */
    fun record(event: MatchEvent): Rejection? {
        engine.check(state, event)?.let { return it }
        state = engine.apply(state, event)
        log += event
        return null
    }

    fun undo() {
        if (!canUndo) return
        log.removeAt(log.lastIndex)
        state = engine.replay(log)
    }

    fun stats(setIndex: Int? = null): MatchStats = computeStats(state.history, setIndex)
}
