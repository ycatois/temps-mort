package fr.hasteria.tempsmort.domain

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertTrue

class MatchEngineTest {
    // Équipe des maquettes : M18 féminine en 6x6
    private val six = Team(
        id = "t1", name = "M18 F", format = GameFormat.SIX, gender = TeamGender.FEMININE, category = Category.M18,
        players = listOf(
            Player("manon", "Manon", 5, PlayerGender.F), Player("lucie", "Lucie", 7, PlayerGender.F),
            Player("emma", "Emma", 12, PlayerGender.F), Player("ines", "Inès", 3, PlayerGender.F),
            Player("chloe", "Chloé", 9, PlayerGender.F), Player("lea", "Léa", 14, PlayerGender.F),
            Player("jade", "Jade", 1, PlayerGender.F, Role.LIBERO), Player("zoe", "Zoé", 10, PlayerGender.F),
        ),
    )
    private val start = listOf("manon", "chloe", "emma", "ines", "lucie", "lea") // postes 1..6

    private fun session(rules: MatchRules = MatchRules.defaultFor(GameFormat.SIX)) = MatchSession(six, rules)
    private fun MatchSession.win(times: Int = 1) = repeat(times) { record(MatchEvent.Rally(Side.US)) }
    private fun MatchSession.lose(times: Int = 1) = repeat(times) { record(MatchEvent.Rally(Side.THEM)) }

    @Test fun rallyRequiresStartedSet() {
        assertEquals(Rejection.SetNotStarted, session().record(MatchEvent.Rally(Side.US)))
    }

    @Test fun sideOutRotatesClockwise() {
        val s = session()
        s.record(MatchEvent.StartSet(Side.THEM, start))
        s.win()
        assertEquals(Side.US, s.state.serving)
        assertEquals(listOf("chloe", "emma", "ines", "lucie", "lea", "manon"), s.state.lineup)
        assertEquals(2, s.state.rotation)
    }

    @Test fun pointOnOwnServeDoesNotRotate() {
        val s = session()
        s.record(MatchEvent.StartSet(Side.US, start))
        s.win(3)
        assertEquals(start, s.state.lineup)
        assertEquals(Score(3, 0), s.state.score)
    }

    @Test fun losingServeGivesServiceWithoutRotation() {
        val s = session()
        s.record(MatchEvent.StartSet(Side.US, start))
        s.lose()
        assertEquals(Side.THEM, s.state.serving)
        assertEquals(start, s.state.lineup)
    }

    @Test fun rotationCyclesBackToR1() {
        val s = session()
        s.record(MatchEvent.StartSet(Side.THEM, start))
        repeat(6) { s.win(); s.lose() }
        assertEquals(start, s.state.lineup)
        assertEquals(1, s.state.rotation)
    }

    @Test fun setNeedsTwoPointLead() {
        val s = session()
        s.record(MatchEvent.StartSet(Side.US, start))
        s.win(24); s.lose(24)
        s.win()
        assertEquals(Phase.IN_PLAY, s.state.phase)
        s.win()
        assertEquals(Phase.AWAITING_SET, s.state.phase)
        assertEquals(listOf(Score(26, 24)), s.state.setsDone)
    }

    @Test fun decidingSetIsPlayedTo15AndEndsMatch() {
        val rules = MatchRules.defaultFor(GameFormat.SIX)
        val s = session(rules)
        repeat(4) { i ->
            s.record(MatchEvent.StartSet(Side.US, start))
            if (i % 2 == 0) s.win(25) else s.lose(25)
        }
        assertEquals(Score(2, 2), s.state.setsWon)
        s.record(MatchEvent.StartSet(Side.US, start))
        s.win(15)
        assertEquals(Phase.FINISHED, s.state.phase)
        assertEquals(Side.US, s.state.winner)
        assertEquals(Rejection.MatchFinished, s.record(MatchEvent.Rally(Side.US)))
    }

    @Test fun substitutionLimitPerSet() {
        val rules = MatchRules.defaultFor(GameFormat.SIX).copy(substitutionsPerSet = 1)
        val s = session(rules)
        s.record(MatchEvent.StartSet(Side.US, start))
        assertNull(s.record(MatchEvent.Substitution("lea", "zoe")))
        assertEquals(Rejection.NoSubstitutionLeft, s.record(MatchEvent.Substitution("zoe", "lea")))
    }

    @Test fun liberoEntersBackRowAndLeavesBeforeFrontRow() {
        val s = session()
        s.record(MatchEvent.StartSet(Side.THEM, start, liberoId = "jade"))
        assertEquals(Rejection.LiberoFrontRow, s.record(MatchEvent.LiberoIn("emma"))) // poste 3
        assertNull(s.record(MatchEvent.LiberoIn("lucie"))) // poste 5
        assertEquals("jade", s.state.lineup[4])
        s.win() // rotation : le libero passe du poste 5 au poste 4 → sort automatiquement
        assertNull(s.state.liberoReplacing)
        assertEquals("lucie", s.state.lineup[3])
        assertTrue("jade" !in s.state.lineup)
    }

    @Test fun liberoCannotServe() {
        val s = session()
        s.record(MatchEvent.StartSet(Side.US, start, liberoId = "jade"))
        assertEquals(Rejection.LiberoCannotServe, s.record(MatchEvent.LiberoIn("manon")))
    }

    @Test fun timeoutsAreLimited() {
        val s = session()
        s.record(MatchEvent.StartSet(Side.US, start))
        s.record(MatchEvent.Timeout(Side.US)); s.record(MatchEvent.Timeout(Side.US))
        assertEquals(Rejection.NoTimeoutLeft, s.record(MatchEvent.Timeout(Side.US)))
        assertNull(s.record(MatchEvent.Timeout(Side.THEM)))
    }

    @Test fun undoReplaysWithoutLastEvent() {
        val s = session()
        s.record(MatchEvent.StartSet(Side.THEM, start))
        s.win()
        s.undo()
        assertEquals(start, s.state.lineup)
        assertEquals(Score(), s.state.score)
        assertEquals(Side.THEM, s.state.serving)
    }

    @Test fun statsSideOutBreakAndRotation() {
        val s = session()
        s.record(MatchEvent.StartSet(Side.THEM, start))
        s.record(MatchEvent.Rally(Side.US, "lucie", RallyAction.ATTAQUE)) // side-out gagné en R1
        s.record(MatchEvent.Rally(Side.US, "chloe", RallyAction.ACE))     // break en R2
        s.record(MatchEvent.Rally(Side.THEM, "chloe", RallyAction.SERVICE_FAUTE))
        val st = s.stats()
        assertEquals(1.0, st.sideOutRate)
        assertEquals(0.5, st.breakRate)
        assertEquals(mapOf("lucie" to 1, "chloe" to 1), st.pointsByPlayer)
        assertEquals(mapOf("chloe" to 1), st.errorsByPlayer)
        assertEquals(Score(1, 1), st.byRotation[2])
        assertEquals(2, st.weakestRotation)
    }
}

class FormatsTest {
    private fun mixed(format: GameFormat) = Team(
        id = "mx", name = "Loisir mixte", format = format, gender = TeamGender.MIXTE, category = Category.LOISIR,
        players = listOf(
            Player("a", "Anna", 1, PlayerGender.F), Player("b", "Bea", 2, PlayerGender.F),
            Player("c", "Cyril", 3, PlayerGender.M), Player("d", "David", 4, PlayerGender.M),
            Player("e", "Eric", 5, PlayerGender.M),
        ),
    )

    @Test fun fourByFourMixedNeedsTwoWomen() {
        val team = mixed(GameFormat.FOUR)
        assertEquals(2, team.minWomenOnCourt)
        assertTrue(validateLineup(team, listOf("a", "b", "c", "d")).isEmpty())
        assertIs<LineupIssue.NotEnoughWomen>(validateLineup(team, listOf("a", "c", "d", "e")).single())
    }

    @Test fun substitutionCannotBreakMixity() {
        val s = MatchSession(mixed(GameFormat.FOUR))
        s.record(MatchEvent.StartSet(Side.US, listOf("a", "b", "c", "d")))
        assertIs<Rejection.NotEnoughWomen>(s.record(MatchEvent.Substitution("b", "e")))
        assertNull(s.record(MatchEvent.Substitution("c", "e")))
    }

    @Test fun twoByTwoRotatesBetweenTwoPlayers() {
        val team = mixed(GameFormat.TWO).copy(minWomenOnCourt = 1)
        val s = MatchSession(team)
        s.record(MatchEvent.StartSet(Side.THEM, listOf("a", "c")))
        s.record(MatchEvent.Rally(Side.US))
        assertEquals(listOf("c", "a"), s.state.lineup) // Cyril au service
        assertEquals(21, s.state.rules.pointsPerSet)
    }

    @Test fun noLiberoOutside6x6() {
        val team = mixed(GameFormat.FOUR)
        val s = MatchSession(team)
        assertEquals(Rejection.LiberoNotAllowed, s.record(MatchEvent.StartSet(Side.US, listOf("a", "b", "c", "d"), liberoId = "e")))
    }

    @Test fun everyCategoryHasADefaultFormat() {
        assertEquals(10, Category.entries.size)
        assertEquals(GameFormat.TWO, Category.M7.suggestedFormat)
    }

    @Test fun lineupSizeChecked() {
        val issues = validateLineup(mixed(GameFormat.SIX).copy(minWomenOnCourt = 0), listOf("a", "b"))
        assertEquals(LineupIssue.WrongSize(6, 2), issues.single())
    }
}
