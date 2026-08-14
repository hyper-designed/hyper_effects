import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';
import 'package:material_ui/material_ui.dart';

double translationXOf(WidgetTester tester, Key key) {
  final transforms = tester.widgetList<Transform>(
    find.ancestor(of: find.byKey(key), matching: find.byType(Transform)),
  );
  var dx = 0.0;
  for (final t in transforms) {
    dx += t.transform.entry(0, 3);
  }
  return dx;
}

const key = Key('box');

Widget host(bool right) => MaterialApp(
      home: Center(
        child: const SizedBox.square(dimension: 50, key: key)
            .translateX(right ? 120 : -120)
            .animate(
              trigger: right,
              motion: const CupertinoMotion.bouncy(),
            ),
      ),
    );

void main() {
  testWidgets('velocity carries across a mid-flight retarget', (tester) async {
    await tester.pumpWidget(host(false));
    await tester.pump();

    // Launch toward +120 and let it build up speed.
    await tester.pumpWidget(host(true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 96));

    // Measure velocity right before the retarget...
    final p1 = translationXOf(tester, key);
    await tester.pump(const Duration(milliseconds: 16));
    final p2 = translationXOf(tester, key);
    final vBefore = (p2 - p1) / 0.016;
    expect(vBefore.abs(), greaterThan(100),
        reason: 'precondition: the box must be moving fast mid-flight');

    // ...retarget mid-flight...
    await tester.pumpWidget(host(false));
    await tester.pump();

    // ...and right after: momentum must carry, not reset to rest.
    final p3 = translationXOf(tester, key);
    await tester.pump(const Duration(milliseconds: 16));
    final p4 = translationXOf(tester, key);
    final vAfter = (p4 - p3) / 0.016;

    expect(vAfter.sign, vBefore.sign,
        reason: 'momentum must initially continue in the same direction');
    expect(vAfter.abs(), greaterThan(vBefore.abs() * 0.5),
        reason: 'the handed-off speed must be of the same order, not ~zero');
  });

  testWidgets('spamming retargets still settles exactly at the final anchor',
      (tester) async {
    await tester.pumpWidget(host(false));
    await tester.pump();

    var right = false;
    for (var i = 0; i < 6; i++) {
      right = !right;
      await tester.pumpWidget(host(right));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
    }
    await tester.pumpAndSettle();
    expect(
      translationXOf(tester, key),
      closeTo(right ? 120 : -120, 1e-6),
      reason: 'physics must still converge exactly on the last target',
    );
  });

  testWidgets('a retargeted spring never teleports between frames',
      (tester) async {
    await tester.pumpWidget(host(false));
    await tester.pump();

    await tester.pumpWidget(host(true));
    await tester.pump();
    var previous = translationXOf(tester, key);
    var maxJump = 0.0;
    for (var i = 0; i < 40; i++) {
      if (i == 8) {
        await tester.pumpWidget(host(false));
      }
      await tester.pump(const Duration(milliseconds: 16));
      final current = translationXOf(tester, key);
      maxJump = max(maxJump, (current - previous).abs());
      previous = current;
    }
    // 240px of travel with a bouncy spring peaks well under 40px/frame;
    // a position snap would jump 100+.
    expect(maxJump, lessThan(40));
  });
}
