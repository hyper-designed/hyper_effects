import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects_demo/stories/shake_and_spring_animation.dart';

/// Largest absolute rotation applied by any Transform wrapping [target].
double maxRotationOf(WidgetTester tester, Finder target) {
  final transforms = tester.widgetList<Transform>(
    find.ancestor(of: target, matching: find.byType(Transform)),
  );
  var maxRotation = 0.0;
  for (final t in transforms) {
    final m = t.transform;
    maxRotation = max(maxRotation, atan2(m.entry(1, 0), m.entry(0, 0)).abs());
  }
  return maxRotation;
}

void main() {
  testWidgets('the idle shake runs on mount, before any interaction',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SpringAnimation())),
    );

    // The shake starts after its 1s delay; sample frames past it and
    // record the strongest rotation seen.
    await tester.pump(const Duration(milliseconds: 1100));
    var strongest = 0.0;
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 30));
      strongest = max(
        strongest,
        maxRotationOf(tester, find.byType(Image)),
      );
    }
    expect(strongest, greaterThan(0.01),
        reason: 'the idle shake must be visibly running without any tap');

    // Drain the shake's per-cycle Future.delayed before the test ends.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
}
