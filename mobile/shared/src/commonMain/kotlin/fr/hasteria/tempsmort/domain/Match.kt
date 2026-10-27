package fr.hasteria.tempsmort.domain

import kotlin.math.abs

enum class Side {
    US, THEM;

    val other: Side get() = if (this == US) THEM else US
}

/** Action ayant conclu l'échange (mode simple : facultative). */
enum class RallyAction(val label: String, val scoring: Boolean) {
    ACE("Ace", true),
    ATTAQUE("Attaque", true),
    CONTRE("Contre", true),
    FAUTE_ADVERSE("Faute adverse", false),
    SERVICE_FAUTE("Faute de service", false),
    ATTAQUE_FAUTE("Attaque out / bloquée", false),
    RECEPTION_FAUTE("Réception ratée", false),
    AUTRE_FAUTE("Autre faute", false),
}

/**
 * Le match est une suite d'événements ; l'état se recalcule en les rejouant.
 * Annuler = retirer le dernier événement. Synchroniser = envoyer la liste.
 */
sealed interface MatchEvent {
    /** Début de set : qui sert en premier et la composition (index 0 = poste 1). */
    data class StartSet(val firstServer: Side, val lineup: List<String>, val liberoId: String? = null) : MatchEvent
    data class Rally(val winner: Side, val playerId: String? = null, val action: RallyAction? = null) : MatchEvent
    data class Substitution(val outId: String, val inId: String) : MatchEvent
    data class LiberoIn(val replacedId: String) : MatchEvent
    data object LiberoOut : MatchEvent
    data class Timeout(val side: Side) : MatchEvent
}

data class Score(val us: Int = 0, val them: Int = 0) {
    operator fun get(side: Side): Int = if (side == Side.US) us else them
    fun plus(side: Side): Score = if (side == Side.US) copy(us = us + 1) else copy(them = them + 1)
    override fun toString(): String = "$us–$them"
}

enum class Phase { AWAITING_SET, IN_PLAY, FINISHED }

/** Trace d'un échange, base de toutes les statistiques. [rotation] = R1..Rn depuis le début du set. */
data class RallyRecord(
    val setIndex: Int,
    val server: Side,
    val rotation: Int,
    val winner: Side,
    val playerId: String?,
    val action: RallyAction?,
)

data class MatchState(
    val rules: MatchRules,
    val phase: Phase = Phase.AWAITING_SET,
    val setsDone: List<Score> = emptyList(),
    val score: Score = Score(),
    val serving: Side = Side.US,
    /** Joueurs sur le terrain, index 0 = poste 1 (serveur quand on a le service). */
    val lineup: List<String> = emptyList(),
    val rotation: Int = 1,
    val liberoId: String? = null,
    /** Joueur remplacé par le libero (sur le banc tant que le libero est en jeu). */
    val liberoReplacing: String? = null,
    val substitutionsUsed: Int = 0,
    val timeoutsUsed: Score = Score(),
    val history: List<RallyRecord> = emptyList(),
) {
    val setIndex: Int get() = setsDone.size
    val setsWon: Score
        get() = setsDone.fold(Score()) { acc, s -> acc.plus(if (s.us > s.them) Side.US else Side.THEM) }
    val winner: Side? get() = if (phase != Phase.FINISHED) null else if (setsWon.us > setsWon.them) Side.US else Side.THEM
    val substitutionsLeft: Int? get() = rules.substitutionsPerSet?.let { it - substitutionsUsed }
    fun timeoutsLeft(side: Side): Int = rules.timeoutsPerSet - timeoutsUsed[side]
}

sealed interface Rejection {
    data object SetNotStarted : Rejection
    data object SetInProgress : Rejection
    data object MatchFinished : Rejection
    data class InvalidLineup(val issues: List<LineupIssue>) : Rejection
    data object NoSubstitutionLeft : Rejection
    data class NotOnCourt(val playerId: String) : Rejection
    data class AlreadyOnCourt(val playerId: String) : Rejection
    data class UnknownPlayer(val playerId: String) : Rejection
    data object LiberoNotAllowed : Rejection
    data object LiberoAlreadyIn : Rejection
    data object LiberoNotIn : Rejection
    data object LiberoFrontRow : Rejection
    data object LiberoCannotServe : Rejection
    data object LiberoCannotBeSubstituted : Rejection
    data class NotEnoughWomen(val required: Int, val actual: Int) : Rejection
    data object NoTimeoutLeft : Rejection
}

class IllegalMatchEventException(val rejection: Rejection) : IllegalStateException(rejection.toString())

class MatchEngine(
    private val team: Team,
    val rules: MatchRules = MatchRules.defaultFor(team.format),
) {
    private val n = team.format.playersOnCourt

    fun initial(): MatchState = MatchState(rules)

    fun replay(events: List<MatchEvent>): MatchState = events.fold(initial()) { state, e -> apply(state, e) }

    /** Raison du refus, ou null si l'événement est applicable. */
    fun check(state: MatchState, event: MatchEvent): Rejection? {
        if (state.phase == Phase.FINISHED) return Rejection.MatchFinished
        if (event is MatchEvent.StartSet) {
            if (state.phase == Phase.IN_PLAY) return Rejection.SetInProgress
            if (event.liberoId != null && !rules.liberoAllowed) return Rejection.LiberoNotAllowed
            if (event.liberoId != null && team.player(event.liberoId) == null) return Rejection.UnknownPlayer(event.liberoId)
            val issues = validateLineup(team, event.lineup, event.liberoId)
            return if (issues.isEmpty()) null else Rejection.InvalidLineup(issues)
        }
        if (state.phase != Phase.IN_PLAY) return Rejection.SetNotStarted

        return when (event) {
            is MatchEvent.Rally -> null
            is MatchEvent.Timeout -> if (state.timeoutsLeft(event.side) <= 0) Rejection.NoTimeoutLeft else null
            is MatchEvent.Substitution -> checkSubstitution(state, event)
            is MatchEvent.LiberoIn -> checkLiberoIn(state, event)
            MatchEvent.LiberoOut -> if (state.liberoReplacing == null) Rejection.LiberoNotIn else null
            is MatchEvent.StartSet -> error("traité plus haut")
        }
    }

    fun apply(state: MatchState, event: MatchEvent): MatchState {
        check(state, event)?.let { throw IllegalMatchEventException(it) }
        return when (event) {
            is MatchEvent.StartSet -> state.copy(
                phase = Phase.IN_PLAY,
                serving = event.firstServer,
                lineup = event.lineup,
                rotation = 1,
                liberoId = event.liberoId,
                liberoReplacing = null,
                substitutionsUsed = 0,
                timeoutsUsed = Score(),
            )
            is MatchEvent.Rally -> applyRally(state, event)
            is MatchEvent.Timeout -> state.copy(timeoutsUsed = state.timeoutsUsed.plus(event.side))
            is MatchEvent.Substitution -> state.copy(
                lineup = state.lineup.map { if (it == event.outId) event.inId else it },
                substitutionsUsed = state.substitutionsUsed + 1,
            )
            is MatchEvent.LiberoIn -> state.copy(
                lineup = state.lineup.map { if (it == event.replacedId) state.liberoId!! else it },
                liberoReplacing = event.replacedId,
            )
            MatchEvent.LiberoOut -> liberoOut(state)
        }
    }

    private fun applyRally(state: MatchState, e: MatchEvent.Rally): MatchState {
        val record = RallyRecord(state.setIndex, state.serving, state.rotation, e.winner, e.playerId, e.action)
        var next = state.copy(score = state.score.plus(e.winner), history = state.history + record)

        if (e.winner != state.serving) {
            // Changement de service. Si nous le récupérons, nous tournons.
            next = next.copy(serving = e.winner)
            if (e.winner == Side.US) {
                next = next.copy(lineup = rotate(next.lineup), rotation = next.rotation % n + 1)
                // Le libero ne peut pas monter à l'avant : il sort automatiquement.
                val liberoIndex = next.liberoId?.let { next.lineup.indexOf(it) } ?: -1
                if (next.liberoReplacing != null && liberoIndex >= 0 && liberoIndex !in BACK_ROW_6X6) next = liberoOut(next)
            }
        }
        return closeSetIfOver(next)
    }

    private fun closeSetIfOver(state: MatchState): MatchState {
        val target = rules.targetFor(state.setIndex)
        val s = state.score
        if (maxOf(s.us, s.them) < target || abs(s.us - s.them) < rules.minLead) return state
        val sets = state.setsDone + s
        val done = state.copy(setsDone = sets, score = Score(), liberoReplacing = null)
        val won = done.setsWon
        val finished = won.us == rules.setsToWin || won.them == rules.setsToWin
        return done.copy(phase = if (finished) Phase.FINISHED else Phase.AWAITING_SET)
    }

    private fun checkSubstitution(state: MatchState, e: MatchEvent.Substitution): Rejection? {
        state.substitutionsLeft?.let { if (it <= 0) return Rejection.NoSubstitutionLeft }
        if (e.outId !in state.lineup) return Rejection.NotOnCourt(e.outId)
        if (team.player(e.inId) == null) return Rejection.UnknownPlayer(e.inId)
        if (e.inId in state.lineup) return Rejection.AlreadyOnCourt(e.inId)
        if (e.outId == state.liberoId || e.inId == state.liberoId || e.inId == state.liberoReplacing) return Rejection.LiberoCannotBeSubstituted
        return womenCheck(state.lineup.map { if (it == e.outId) e.inId else it })
    }

    private fun checkLiberoIn(state: MatchState, e: MatchEvent.LiberoIn): Rejection? {
        val libero = state.liberoId ?: return Rejection.LiberoNotAllowed
        if (state.liberoReplacing != null) return Rejection.LiberoAlreadyIn
        val idx = state.lineup.indexOf(e.replacedId)
        if (idx < 0) return Rejection.NotOnCourt(e.replacedId)
        if (idx !in BACK_ROW_6X6) return Rejection.LiberoFrontRow
        if (idx == 0 && state.serving == Side.US) return Rejection.LiberoCannotServe
        return womenCheck(state.lineup.map { if (it == e.replacedId) libero else it })
    }

    private fun liberoOut(state: MatchState): MatchState {
        val back = state.liberoReplacing ?: return state
        return state.copy(lineup = state.lineup.map { if (it == state.liberoId) back else it }, liberoReplacing = null)
    }

    private fun womenCheck(lineup: List<String>): Rejection? {
        if (team.gender != TeamGender.MIXTE) return null
        val women = lineup.count { team.player(it)?.gender == PlayerGender.F }
        return if (women < team.minWomenOnCourt) Rejection.NotEnoughWomen(team.minWomenOnCourt, women) else null
    }
}
