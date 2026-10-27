package fr.hasteria.tempsmort.android

import android.os.Bundle
import android.view.WindowManager
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import fr.hasteria.tempsmort.android.ui.match.MatchScreen
import fr.hasteria.tempsmort.android.ui.theme.TempsMortTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        // Pendant un match, l'écran ne doit jamais se mettre en veille.
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        setContent { TempsMortTheme { MatchScreen() } }
    }
}
