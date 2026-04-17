// Loads Noto fonts from test/fonts/.cache/ into the Flutter test environment.
// Call `await loadTestFonts()` once in test setUp.
// Fails with a clear message if the cache is missing.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _kTestFontsDir = 'test/fonts/.cache';

const _kFontFamilies = <String, List<String>>{
  'TestLatin': ['NotoSans-Regular.ttf'],
  'TestArabic': ['NotoNaskhArabic-Regular.ttf'],
  'TestJapanese': ['NotoSansJP-Regular.ttf'],
  'TestDevanagari': ['NotoSansDevanagari-Regular.ttf'],
  'TestEmoji': ['NotoColorEmoji.ttf'],
  // Sacramento is the cursive script the example app's Translation
  // widget uses. We carry it here so probes can capture the EXACT
  // visual the user is seeing — Sacramento's flourishes are what
  // exposed the latest pad-clipping issue.
  'TestSacramento': ['Sacramento-Regular.ttf'],
  // Real fonts the example app loads via GoogleFonts. Carrying
  // them in the test cache lets probes match the user's running
  // visuals byte-for-byte rather than approximating with Noto /
  // Sacramento substitutes.
  'TestGloriaHallelujah': ['GloriaHallelujah-Regular.ttf'],
  'TestRobotoMono': ['RobotoMono-Regular.ttf'],
};

bool _loaded = false;

Future<void> loadTestFonts() async {
  if (_loaded) return;
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final entry in _kFontFamilies.entries) {
    final loader = FontLoader(entry.key);
    for (final fileName in entry.value) {
      final file = File('$_kTestFontsDir/$fileName');
      if (!file.existsSync()) {
        throw StateError(
          'Missing test font: ${file.path}\n'
          'Run `dart run tool/download_test_fonts.dart` before running tests.',
        );
      }
      loader.addFont(Future.value(file.readAsBytesSync().buffer.asByteData()));
    }
    await loader.load();
  }
  _loaded = true;
}
