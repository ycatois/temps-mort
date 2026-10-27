import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Le moteur de règles reste en Dart pur : réutilisable côté serveur et pour d'autres sports.
void main() {
  test('lib/domain n\'importe ni Flutter ni l\'interface', () {
    final files = Directory('lib/domain').listSync().whereType<File>().where((f) => f.path.endsWith('.dart'));
    expect(files, isNotEmpty);
    for (final f in files) {
      final source = f.readAsStringSync();
      expect(source.contains('package:flutter'), isFalse, reason: '${f.path} importe Flutter');
      expect(source.contains('/ui/'), isFalse, reason: '${f.path} importe l\'interface');
    }
  });
}
