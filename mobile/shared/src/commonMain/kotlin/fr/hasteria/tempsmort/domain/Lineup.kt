package fr.hasteria.tempsmort.domain

sealed interface LineupIssue {
    data class WrongSize(val expected: Int, val actual: Int) : LineupIssue
    data class Duplicate(val playerId: String) : LineupIssue
    data class UnknownPlayer(val playerId: String) : LineupIssue
    data class LiberoInLineup(val playerId: String) : LineupIssue
    data class NotEnoughWomen(val required: Int, val actual: Int) : LineupIssue
}

/**
 * Vérifie une composition de départ. [lineup] est ordonnée par position : index 0 = poste 1 (serveur).
 * Le libero n'apparaît jamais dans la composition : il remplace ensuite un joueur arrière.
 */
fun validateLineup(team: Team, lineup: List<String>, liberoId: String? = null): List<LineupIssue> {
    val issues = mutableListOf<LineupIssue>()
    val expected = team.format.playersOnCourt
    if (lineup.size != expected) issues += LineupIssue.WrongSize(expected, lineup.size)
    lineup.groupingBy { it }.eachCount().filterValues { it > 1 }.keys.forEach { issues += LineupIssue.Duplicate(it) }
    lineup.filter { team.player(it) == null }.forEach { issues += LineupIssue.UnknownPlayer(it) }
    if (liberoId != null && liberoId in lineup) issues += LineupIssue.LiberoInLineup(liberoId)
    if (team.gender == TeamGender.MIXTE) {
        val women = lineup.distinct().count { team.player(it)?.gender == PlayerGender.F }
        if (women < team.minWomenOnCourt) issues += LineupIssue.NotEnoughWomen(team.minWomenOnCourt, women)
    }
    return issues
}

/** Rotation dans le sens des aiguilles d'une montre : le joueur du poste 2 passe au service (poste 1). */
fun rotate(lineup: List<String>): List<String> =
    if (lineup.isEmpty()) lineup else List(lineup.size) { i -> lineup[(i + 1) % lineup.size] }

/** Postes arrière (index 0-based) où le libero peut entrer : 1, 6 et 5 en 6x6. */
internal val BACK_ROW_6X6 = setOf(0, 4, 5)
