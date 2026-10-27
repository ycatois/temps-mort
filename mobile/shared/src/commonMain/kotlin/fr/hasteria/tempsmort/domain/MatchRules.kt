package fr.hasteria.tempsmort.domain

/**
 * Règles d'un match. Les valeurs par défaut suivent les usages courants ; tout est modifiable
 * par le coach (championnats jeunes, tournois, loisir ont souvent leurs propres règlements).
 */
data class MatchRules(
    val setsToWin: Int,
    val pointsPerSet: Int,
    val pointsDecidingSet: Int,
    val minLead: Int = 2,
    /** null = remplacements illimités. */
    val substitutionsPerSet: Int?,
    val timeoutsPerSet: Int,
    val liberoAllowed: Boolean,
) {
    val maxSets: Int get() = setsToWin * 2 - 1

    fun targetFor(setIndex: Int): Int = if (setIndex == maxSets - 1) pointsDecidingSet else pointsPerSet

    companion object {
        fun defaultFor(format: GameFormat): MatchRules = when (format) {
            GameFormat.SIX -> MatchRules(setsToWin = 3, pointsPerSet = 25, pointsDecidingSet = 15, substitutionsPerSet = 6, timeoutsPerSet = 2, liberoAllowed = true)
            GameFormat.FOUR -> MatchRules(setsToWin = 2, pointsPerSet = 25, pointsDecidingSet = 15, substitutionsPerSet = null, timeoutsPerSet = 2, liberoAllowed = false)
            GameFormat.TWO -> MatchRules(setsToWin = 2, pointsPerSet = 21, pointsDecidingSet = 15, substitutionsPerSet = 0, timeoutsPerSet = 1, liberoAllowed = false)
        }
    }
}
