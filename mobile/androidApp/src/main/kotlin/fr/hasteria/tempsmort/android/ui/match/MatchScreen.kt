package fr.hasteria.tempsmort.android.ui.match

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import fr.hasteria.tempsmort.android.ui.theme.BarlowCondensed
import fr.hasteria.tempsmort.android.ui.theme.TmColor
import fr.hasteria.tempsmort.android.ui.theme.TmRadius
import fr.hasteria.tempsmort.android.ui.theme.TmTouch
import fr.hasteria.tempsmort.domain.Phase
import fr.hasteria.tempsmort.domain.RallyAction
import fr.hasteria.tempsmort.domain.Side

/** E05 — Match en direct. Tablette (≥ 840 dp) : terrain + panneau côte à côte ; smartphone : empilés. */
@Composable
fun MatchScreen(vm: MatchViewModel = viewModel()) {
    val s = vm.state
    Column(Modifier.fillMaxSize().background(TmColor.GroundApp).safeDrawingPadding()) {
        ScoreBar(vm)
        BoxWithConstraints(Modifier.fillMaxSize().padding(16.dp)) {
            val wide = maxWidth >= 840.dp
            if (wide) {
                Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                    Court(vm, Modifier.weight(1.1f))
                    ActionPanel(vm, Modifier.weight(1f))
                }
            } else {
                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Court(vm, Modifier.fillMaxWidth())
                    ActionPanel(vm, Modifier.fillMaxWidth())
                }
            }
        }
        if (s.phase == Phase.FINISHED) Text("Match terminé", Modifier.padding(16.dp))
    }
}

@Composable
private fun ScoreBar(vm: MatchViewModel) {
    val s = vm.state
    Row(
        Modifier.fillMaxWidth().background(TmColor.Navy).padding(horizontal = 20.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Column(Modifier.weight(1f)) {
            Text("SET ${s.setIndex + 1} · ${vm.team.format.label} ${vm.team.gender.label.lowercase()}", color = TmColor.OnNavyMuted, style = MaterialTheme.typography.labelMedium)
            Text("Sets ${s.setsWon.us}–${s.setsWon.them}", color = TmColor.OnNavy, style = MaterialTheme.typography.bodyMedium)
        }
        Text(
            "${s.score.us} – ${s.score.them}",
            color = Color.White, fontFamily = BarlowCondensed, fontWeight = FontWeight.Bold, fontSize = 56.sp,
            modifier = Modifier.semantics { contentDescription = "Score ${s.score.us} à ${s.score.them}" },
        )
        Row(Modifier.weight(1f), horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.End)) {
            Button(
                onClick = vm::timeout,
                enabled = s.timeoutsLeft(Side.US) > 0,
                colors = ButtonDefaults.buttonColors(containerColor = TmColor.Yellow, contentColor = TmColor.Navy),
                modifier = Modifier.heightIn(min = TmTouch.MinTarget),
            ) { Text("Temps mort ${s.timeoutsUsed.us}/${s.rules.timeoutsPerSet}") }
        }
    }
}

@Composable
private fun Court(vm: MatchViewModel, modifier: Modifier) {
    val s = vm.state
    // Disposition à l'écran : avant (4 3 2) en haut, arrière (5 6 1) en bas ; index 0 = poste 1.
    val rows = when (s.lineup.size) {
        6 -> listOf(listOf(3, 2, 1), listOf(4, 5, 0))
        4 -> listOf(listOf(2, 1), listOf(3, 0))
        else -> listOf(s.lineup.indices.toList())
    }
    Column(
        modifier.clip(RoundedCornerShape(16.dp)).background(TmColor.CourtOut).padding(14.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text("R${s.rotation} · ${if (s.serving == Side.US) "au service" else "en réception"}", color = Color.White, style = MaterialTheme.typography.labelLarge)
        Column(
            Modifier.fillMaxWidth().aspectRatio(1.1f).background(TmColor.Court).border(2.dp, Color.White).padding(12.dp),
            verticalArrangement = Arrangement.SpaceEvenly,
        ) {
            rows.forEach { row ->
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
                    row.filter { it < s.lineup.size }.forEach { idx ->
                        val id = s.lineup[idx]
                        PlayerToken(
                            number = vm.playerLabel(id).first,
                            name = vm.playerLabel(id).second,
                            serving = idx == 0 && s.serving == Side.US,
                            libero = id == s.liberoId,
                            selected = id == vm.selectedPlayerId,
                            onClick = { vm.select(id) },
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun PlayerToken(number: Int, name: String, serving: Boolean, libero: Boolean, selected: Boolean, onClick: () -> Unit) {
    val bg = if (libero) Color.White else TmColor.Navy
    val fg = if (libero) TmColor.Navy else Color.White
    val ring = when {
        selected -> BorderStroke(4.dp, TmColor.Accent)
        serving -> BorderStroke(3.dp, TmColor.Yellow)
        else -> BorderStroke(2.dp, if (libero) TmColor.Navy else Color.White)
    }
    Box(
        Modifier.size(76.dp).border(ring, CircleShape).background(bg, CircleShape).clickable(onClick = onClick)
            .semantics { this.selected = selected; contentDescription = "$name, numéro $number" + if (serving) ", au service" else "" },
        contentAlignment = Alignment.Center,
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text("$number", color = fg, fontFamily = BarlowCondensed, fontWeight = FontWeight.Bold, fontSize = 24.sp)
            Text(if (libero) "$name · L" else name, color = fg, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
        }
    }
}

@Composable
private fun ActionPanel(vm: MatchViewModel, modifier: Modifier) {
    val selected = vm.selectedPlayerId?.let { vm.playerLabel(it) }
    Column(modifier, verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Text(
            selected?.let { "#${it.first} ${it.second} : choisir l'action" } ?: "Touchez une joueuse, puis l'action",
            style = MaterialTheme.typography.titleMedium,
        )
        val gains = listOf(RallyAction.ATTAQUE, RallyAction.ACE, RallyAction.CONTRE)
        val fautes = listOf(RallyAction.ATTAQUE_FAUTE, RallyAction.SERVICE_FAUTE, RallyAction.RECEPTION_FAUTE)
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            gains.forEach { a -> BigButton(a.label, TmColor.Accent, Color.White, Modifier.weight(1f)) { vm.action(a) } }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            fautes.forEach { a -> OutlineAction(a.label, Modifier.weight(1f)) { vm.action(a) } }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            BigButton("+1 faute adverse", TmColor.Navy, Color.White, Modifier.weight(1f), vm::opponentError)
            BigButton("+1 adversaire", TmColor.SurfaceAlt, TmColor.Navy, Modifier.weight(1f), vm::opponentPoint)
        }
        OutlinedButton(
            onClick = vm::undo, enabled = vm.canUndo,
            modifier = Modifier.fillMaxWidth().heightIn(min = TmTouch.MinTarget),
            shape = RoundedCornerShape(TmRadius.Md),
        ) { Text("Annuler la dernière saisie") }
        vm.lastRejection?.let { Text("Action refusée : $it", color = TmColor.Error, style = MaterialTheme.typography.bodyMedium) }
    }
}

@Composable
private fun BigButton(label: String, bg: Color, fg: Color, modifier: Modifier, onClick: () -> Unit) {
    Button(
        onClick = onClick,
        modifier = modifier.heightIn(min = TmTouch.PrimaryTarget),
        shape = RoundedCornerShape(TmRadius.Md),
        colors = ButtonDefaults.buttonColors(containerColor = bg, contentColor = fg),
    ) { Text(label, style = MaterialTheme.typography.labelLarge) }
}

@Composable
private fun OutlineAction(label: String, modifier: Modifier, onClick: () -> Unit) {
    OutlinedButton(
        onClick = onClick,
        modifier = modifier.heightIn(min = TmTouch.PrimaryTarget),
        shape = RoundedCornerShape(TmRadius.Md),
        border = BorderStroke(2.dp, TmColor.Error),
    ) { Text(label, color = TmColor.Navy, style = MaterialTheme.typography.labelLarge) }
}
