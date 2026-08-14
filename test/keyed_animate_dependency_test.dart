import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

/// Regression pin for the retainer's worst defect: a KEYED, never-played
/// `.animate(trigger:)` must not be slammed to its end values when an
/// unrelated inherited dependency changes.
double compositeScaleOf(WidgetTester tester, Key key) {
  final transforms = tester.widgetList<Transform>(
    find.ancestor(of: find.byKey(key), matching: find.byType(Transform)),
  );
  var scale = 1.0;
  for (final t in transforms) {
    final m = t.transform;
    scale *= Offset(m.entry(0, 0), m.entry(1, 0)).distance;
  }
  return scale;
}

const boxKey = Key('box');

Widget host(AnimationBehavior behavior) => MaterialApp(
      home: HyperEffectsAnimationConfig(
        animationBehavior: behavior,
        child: Center(
          child: const SizedBox.square(dimension: 50, key: boxKey)
              .scale(2, from: 1)
              .animate(
                key: const Key('effect'),
                trigger: 0,
                duration: const Duration(milliseconds: 300),
              ),
        ),
      ),
    );

void main() {
  testWidgets(
      'a keyed, untriggered animate() stays at start values when an '
      'inherited dependency changes', (tester) async {
    await tester.pumpWidget(host(AnimationBehavior.normal));
    await tester.pump();
    expect(compositeScaleOf(tester, boxKey), closeTo(1.0, 1e-9));

    // An unrelated config change must not fabricate an end state.
    await tester.pumpWidget(host(AnimationBehavior.preserve));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(compositeScaleOf(tester, boxKey), closeTo(1.0, 1e-9),
        reason: 'never-played animations must remain at their start values');
  });
}
