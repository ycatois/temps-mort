package fr.hasteria.tempsmort.android.ui.match

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import fr.hasteria.tempsmort.domain.Category
import fr.hasteria.tempsmort.domain.GameFormat
import fr.hasteria.tempsmort.domain.MatchEvent
import fr.hasteria.tempsmort.domain.MatchSession
import fr.hasteria.tempsmort.domain.MatchState
import fr.hasteria.tempsmort.domain.Player
import fr.hasteria.tempsmort.domain.PlayerGender
import fr.hasteria.tempsmort.domain.RallyAction
import fr.hasteria.tempsmort.domain.Rejection
import fr.hasteria.tempsmort.domain.Role
import fr.hasteria.tempsmort.domain.Side
import fr.hasteria.tempsmort.domain.Team
import fr.hasteria.tempsmort.domain.TeamGender

/**
 * État de l'écran Match en direct (E05). La logique vit dans le module shared ;
 * ici on ne fait que relayer les gestes et exposer l'état à Compose.
 * TODO V1 : persistance locale des événements (Room/SQLDelight) et choix de l'équipe.
 */
class MatchViewModel : ViewModel() {
    val team = demoTeam()
    private val session = MatchSession(team)

    var state: MatchState by mutableStateOf(session.state)
        private set
    var selectedPlayerId: String? by mutableStateOf(null)
        private set
    var lastRejection: Rejection? by mutableStateOf(null)
        private set

    init {
        record(MatchEvent.StartSet(Side.US, listOf("manon", "chloe", "emma", "ines", "lucie", "lea"), liberoId = "jade"))
    }

    val canUndo: Boolean get() = session.canUndo

    fun select(playerId: String) {
        selectedPlayerId = if (selectedPlayerId == playerId) null else playerId
    }

    /** Deux touches : la joueuse (facultatif), puis l'action. */
    fun action(action: RallyAction) {
        val winner = if (action.scoring) Side.US else Side.THEM
        record(MatchEvent.Rally(winner, selectedPlayerId, action))
        selectedPlayerId = null
    }

    fun opponentError() = record(MatchEvent.Rally(Side.US, null, RallyAction.FAUTE_ADVERSE))
    fun opponentPoint() = record(MatchEvent.Rally(Side.THEM))
    fun timeout() = record(MatchEvent.Timeout(Side.US))

    fun undo() {
        session.undo()
        state = session.state
        lastRejection = null
    }

    fun playerLabel(id: String): Pair<Int, String> = team.player(id)?.let { it.number to it.firstName } ?: (0 to "?")

    private fun record(event: MatchEvent) {
        lastRejection = session.record(event)
        state = session.state
    }

    private fun demoTeam() = Team(
        id = "demo", name = "M18 F", format = GameFormat.SIX, gender = TeamGender.FEMININE, category = Category.M18,
        players = listOf(
            Player("manon", "Manon", 5, PlayerGender.F), Player("lucie", "Lucie", 7, PlayerGender.F),
            Player("emma", "Emma", 12, PlayerGender.F, Role.CENTRAL), Player("ines", "Inès", 3, PlayerGender.F),
            Player("chloe", "Chloé", 9, PlayerGender.F), Player("lea", "Léa", 14, PlayerGender.F, Role.PASSEUR),
            Player("jade", "Jade", 1, PlayerGender.F, Role.LIBERO), Player("zoe", "Zoé", 10, PlayerGender.F),
        ),
    )
}
