package fr.hasteria.tempsmort.domain

data class MatchStats(
    /** Part (0 à 1) des échanges gagnés quand l'adversaire sert (null si aucun). */
    val sideOutRate: Double?,
    /** Part (0 à 1) des échanges gagnés sur notre service (null si aucun). */
    val breakRate: Double?,
    /** Points marqués par joueur (ace, attaque, contre). */
    val pointsByPlayer: Map<String, Int>,
    /** Fautes directes par joueur. */
    val errorsByPlayer: Map<String, Int>,
    /** Échanges gagnés / perdus par rotation (R1..Rn). */
    val byRotation: Map<Int, Score>,
) {
    /** Rotation au plus mauvais solde, pour le bloc « À retenir » du résumé ; null si aucune n'est déficitaire. */
    val weakestRotation: Int?
        get() = byRotation.filterValues { it.us < it.them }.minByOrNull { (_, s) -> s.us - s.them }?.key
}

fun computeStats(history: List<RallyRecord>, setIndex: Int? = null): MatchStats {
    val rallies = if (setIndex == null) history else history.filter { it.setIndex == setIndex }
    fun rate(list: List<RallyRecord>): Double? =
        if (list.isEmpty()) null else list.count { it.winner == Side.US }.toDouble() / list.size

    val points = mutableMapOf<String, Int>()
    val errors = mutableMapOf<String, Int>()
    val rotations = mutableMapOf<Int, Score>()
    for (r in rallies) {
        val pid = r.playerId
        if (pid != null && r.action != null) {
            if (r.winner == Side.US && r.action.scoring) points[pid] = (points[pid] ?: 0) + 1
            if (r.winner == Side.THEM && !r.action.scoring && r.action != RallyAction.FAUTE_ADVERSE) errors[pid] = (errors[pid] ?: 0) + 1
        }
        rotations[r.rotation] = (rotations[r.rotation] ?: Score()).plus(r.winner)
    }
    return MatchStats(
        sideOutRate = rate(rallies.filter { it.server == Side.THEM }),
        breakRate = rate(rallies.filter { it.server == Side.US }),
        pointsByPlayer = points,
        errorsByPlayer = errors,
        byRotation = rotations.entries.sortedBy { it.key }.associate { it.key to it.value },
    )
}
