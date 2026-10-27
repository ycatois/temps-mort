import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'ui/match/match_screen.dart';
import 'ui/theme/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Pendant un match, l'écran ne doit jamais se mettre en veille (V1-TEC-06).
  WakelockPlus.enable();
  runApp(const TempsMortApp());
}

class TempsMortApp extends StatelessWidget {
  const TempsMortApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Temps Mort',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const MatchScreen(),
    );
  }
}
