// Run with: `flutter test test/benchmarks/rolling_frame_budget_bench.dart`
// Outputs timing info; not asserted in CI. Compare numbers before/after
// later migration phases to gauge the shaped-path cost.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('[bench] 10-char rolling transition frame budget',
      (tester) async {
    const text = '0000000000';

    await tester.pumpWidget(
      wrapInTestApp(
        StatefulBuilder(
          builder: (context, setState) => const Text(text).roll().animate(
                trigger: text,
                duration: const Duration(milliseconds: 500),
              ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final stopwatch = Stopwatch()..start();
    const frameInterval = Duration(milliseconds: 16);
    const totalFrames = 60;
    for (var i = 0; i < totalFrames; i++) {
      await tester.pump(frameInterval);
    }
    stopwatch.stop();

    // ignore: avoid_print
    print(
      '[BENCH] 60 frames over ${stopwatch.elapsedMilliseconds} ms '
      '(${(stopwatch.elapsedMicroseconds / totalFrames).toStringAsFixed(1)} '
      'μs per pump on average)',
    );
  });
}
