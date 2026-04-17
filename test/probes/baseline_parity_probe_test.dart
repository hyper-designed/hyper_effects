// Probe: print the rolled row's intrinsic height + reported baseline
// next to a plain Text widget at the same style. If they diverge,
// every example that anchors the rolled widget by box bounds gets
// shifted relative to a sibling Text — explains "baselines broken
// in other examples".

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';
import 'package:hyper_effects/src/text/shaped_text.dart';

import '../helpers/test_font_loader.dart';

void main() {
  setUp(() async {
    await loadTestFonts();
    ShapedText.debugClearCache();
  });

  for (final cfg in const [
    (name: 'Roboto 16pt no strut', font: 'TestLatin', size: 16.0, mult: 1.0),
    (name: 'Roboto 16pt mult=2', font: 'TestLatin', size: 16.0, mult: 2.0),
    (name: 'Roboto 56pt no strut', font: 'TestLatin', size: 56.0, mult: 1.0),
    (name: 'Roboto 56pt mult=2', font: 'TestLatin', size: 56.0, mult: 2.0),
    (name: 'Sacramento 56pt no strut',
        font: 'TestSacramento', size: 56.0, mult: 1.0),
    (name: 'Sacramento 56pt mult=2',
        font: 'TestSacramento', size: 56.0, mult: 2.0),
    // Real fonts the example app uses. GloriaHallelujah is a hand-
    // drawn cursive with peculiar metrics; if rolled vs plain
    // diverge here, the strut-injection in .roll() is the issue.
    (name: 'GloriaHallelujah 56pt no strut',
        font: 'TestGloriaHallelujah', size: 56.0, mult: 1.0),
    (name: 'GloriaHallelujah 56pt mult=2',
        font: 'TestGloriaHallelujah', size: 56.0, mult: 2.0),
    (name: 'RobotoMono 48pt no strut',
        font: 'TestRobotoMono', size: 48.0, mult: 1.0),
    (name: 'RobotoMono 48pt mult=2',
        font: 'TestRobotoMono', size: 48.0, mult: 2.0),
  ]) {
    testWidgets('parity: ${cfg.name}', (tester) async {
      final plainKey = GlobalKey();
      final rolledKey = GlobalKey();
      final style =
          TextStyle(fontFamily: cfg.font, fontSize: cfg.size);
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.noScaling),
              child: Scaffold(
                body: Column(
                  children: [
                    Text('Hello', key: plainKey, style: style),
                    Text('Hello', style: style)
                        .roll(symbolDistanceMultiplier: cfg.mult)
                        .build(buildContextWith: rolledKey),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final plainRb = plainKey.currentContext!.findRenderObject() as RenderBox;
      final rolledRb =
          rolledKey.currentContext!.findRenderObject() as RenderBox;

      // ignore: avoid_print
      print('=== ${cfg.name} ===');
      // ignore: avoid_print
      print('  plain  size=${plainRb.size}  '
          'baseline=${plainRb.getDryBaseline(plainRb.constraints, TextBaseline.alphabetic)}');
      // ignore: avoid_print
      print('  rolled size=${rolledRb.size}  '
          'baseline=${rolledRb.getDryBaseline(rolledRb.constraints, TextBaseline.alphabetic)}');
    });
  }
}

/// Tiny helper to capture a rolled widget's RenderBox via a key.
extension on Widget {
  Widget build({required GlobalKey buildContextWith}) =>
      KeyedSubtree(key: buildContextWith, child: this);
}
