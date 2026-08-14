import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

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

const key = Key('icon');

Widget stamp(bool isCompleted) => MaterialApp(
      home: Center(
        child: const SizedBox.square(dimension: 74, key: key)
            .scale(0)
            .rotate(0)
            .step(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutQuart,
            )
            .scale(1.5)
            .rotate(15 * pi / 180)
            .step(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              delay: const Duration(milliseconds: 150),
            )
            .scale(1)
            .rotate(0)
            .timeline(trigger: isCompleted),
      ),
    );

void main() {
  testWidgets('at rest the timeline renders its first keyframe',
      (tester) async {
    await tester.pumpWidget(stamp(false));
    await tester.pump();
    expect(compositeScaleOf(tester, key), closeTo(0, 1e-9));
  });

  testWidgets('triggering plays the stamp with correct values throughout',
      (tester) async {
    await tester.pumpWidget(stamp(false));
    await tester.pump();

    await tester.pumpWidget(stamp(true));
    // 175ms: segment 1 local progress 0.5 under easeOutQuart.
    await tester.pump(const Duration(milliseconds: 175));
    expect(
      compositeScaleOf(tester, key),
      closeTo(1.5 * Curves.easeOutQuart.transform(0.5), 1e-6),
    );
    // 400ms: inside the 150ms delay window — holds the slam keyframe.
    await tester.pump(const Duration(milliseconds: 225));
    expect(compositeScaleOf(tester, key), closeTo(1.5, 1e-6));
    // 650ms: segment 2 local progress 0.5 under easeOutBack.
    await tester.pump(const Duration(milliseconds: 250));
    expect(
      compositeScaleOf(tester, key),
      closeTo(1.5 + (1 - 1.5) * Curves.easeOutBack.transform(0.5), 1e-6),
    );
    await tester.pumpAndSettle();
    expect(compositeScaleOf(tester, key), closeTo(1.0, 1e-9));
  });

  testWidgets(
      'any trigger change restarts forward — direction is never '
      'inferred from the trigger value', (tester) async {
    await tester.pumpWidget(stamp(false));
    await tester.pump();

    await tester.pumpWidget(stamp(true));
    await tester.pump(const Duration(milliseconds: 175));

    // Mid-flight the trigger changes to FALSE. A trigger is an identity
    // signal, not a direction: the timeline must restart from the beginning
    // and play forward to its final keyframe — not reverse toward 0.
    await tester.pumpWidget(stamp(false));
    await tester.pump();
    expect(compositeScaleOf(tester, key), closeTo(0, 1e-9),
        reason: 'restart must rewind to the first keyframe');
    await tester.pump(const Duration(milliseconds: 175));
    expect(
      compositeScaleOf(tester, key),
      closeTo(1.5 * Curves.easeOutQuart.transform(0.5), 1e-6),
      reason: 'the restarted run must play forward',
    );
    await tester.pumpAndSettle();
    expect(compositeScaleOf(tester, key), closeTo(1.0, 1e-9),
        reason: 'the restarted run must complete at the final keyframe');
  });

  testWidgets('onEnd fires exactly once per completed run', (tester) async {
    var calls = 0;
    Widget build(bool t) => MaterialApp(
          home: const SizedBox.square(dimension: 74, key: key)
              .scale(0)
              .step(duration: const Duration(milliseconds: 100))
              .scale(1)
              .timeline(trigger: t, onEnd: () => calls++),
        );
    await tester.pumpWidget(build(false));
    await tester.pumpWidget(build(true));
    await tester.pumpAndSettle();
    expect(calls, 1);
  });
}
