import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'data/sqlite_store.dart';
import 'data/store.dart';
import 'ui/common/store_scope.dart';
import 'ui/home/home_screen.dart';
import 'ui/theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Pendant un match, l'écran ne doit jamais se mettre en veille (V1-TEC-06).
  WakelockPlus.enable();
  // Équipes, matchs et événements restent sur l'appareil : l'app fonctionne sans réseau.
  final store = await SqliteStore.open();
  runApp(TempsMortApp(store: store));
}

class TempsMortApp extends StatelessWidget {
  const TempsMortApp({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: store,
      child: MaterialApp(
        title: 'Temps Mort',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        locale: const Locale('fr', 'FR'),
        supportedLocales: const [Locale('fr', 'FR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const HomeScreen(),
      ),
    );
  }
}
