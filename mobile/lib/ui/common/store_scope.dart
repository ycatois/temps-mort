import 'package:flutter/widgets.dart';

import '../../data/store.dart';

/// Donne accès au stockage local à tous les écrans (SQLite dans l'app, mémoire dans les tests).
class StoreScope extends InheritedWidget {
  const StoreScope({super.key, required this.store, required super.child});

  final AppStore store;

  static AppStore of(BuildContext context) => context.getInheritedWidgetOfExactType<StoreScope>()!.store;

  /// Null quand l'écran est ouvert sans stockage (certains tests).
  static AppStore? maybeOf(BuildContext context) => context.getInheritedWidgetOfExactType<StoreScope>()?.store;

  @override
  bool updateShouldNotify(StoreScope oldWidget) => store != oldWidget.store;
}
