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

const key = Key('box');

void main() {
  test('duration+curve sugar and an explicit CurvedMotion compile identically',
      () {
    final sugar = TimelineSpec.compile(
      const SizedBox()
          .scale(0)
          .step(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
          )
          .scale(1),
    );
    final explicit = TimelineSpec.compile(
      const SizedBox()
          .scale(0)
          .step(
            motion: const CurvedMotion(
              Duration(milliseconds: 350),
              Curves.easeOut,
            ),
          )
          .scale(1),
    );
    expect(sugar.segments, explicit.segments);
    expect(sugar.totalDuration, explicit.totalDuration);
  });

  test('a spring segment contributes its settling bound to totalDuration', () {
    const bouncy = CupertinoMotion.bouncy();
    final spec = TimelineSpec.compile(
      const SizedBox().scale(0).step(motion: bouncy).scale(1),
    );
    expect(spec.totalDuration, bouncy.effectiveDuration);
  });

  test('evaluate overshoots through a spring segment and ends exactly', () {
    final spec = TimelineSpec.compile(
      const SizedBox()
          .scale(0)
          .step(motion: const CupertinoMotion.bouncy())
          .scale(1),
    );
    var peak = 0.0;
    for (var i = 1; i < 200; i++) {
      final scale =
          (spec.evaluate(i / 200).single as ScaleEffect).scale!;
      peak = max(peak, scale);
    }
    expect(peak, greaterThan(1.001), reason: 'the spring must overshoot');
    expect((spec.evaluate(1).single as ScaleEffect).scale, 1,
        reason: 'the segment must end exactly at its keyframe');
  });

  test('declaring both motion and duration/curve throws', () {
    expect(
      () => const SizedBox().step(
        duration: const Duration(milliseconds: 100),
        motion: const CupertinoMotion.bouncy(),
      ),
      throwsFlutterError,
    );
  });

  testWidgets('a spring step renders overshoot and rests exactly',
      (tester) async {
    Widget host(int trigger) => MaterialApp(
          home: Center(
            child: const SizedBox.square(dimension: 50, key: key)
                .scale(0)
                .step(motion: const CupertinoMotion.bouncy())
                .scale(1)
                .timeline(trigger: trigger),
          ),
        );
    await tester.pumpWidget(host(0));
    await tester.pump();

    await tester.pumpWidget(host(1));
    var peak = 0.0;
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      peak = max(peak, compositeScaleOf(tester, key));
    }
    expect(peak, greaterThan(1.001),
        reason: 'the rendered spring must visibly overshoot');
    await tester.pumpAndSettle();
    expect(compositeScaleOf(tester, key), closeTo(1.0, 1e-9),
        reason: 'the spring must rest exactly at the keyframe');
  });

  testWidgets('.animate(motion:) springs and rests exactly', (tester) async {
    Widget host(int trigger) => MaterialApp(
          home: Center(
            child: const SizedBox.square(dimension: 50, key: key)
                .scale(2, from: 1)
                .animate(
                  trigger: trigger,
                  motion: const CupertinoMotion.bouncy(),
                ),
          ),
        );
    await tester.pumpWidget(host(0));
    await tester.pump();

    await tester.pumpWidget(host(1));
    var peak = 0.0;
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      peak = max(peak, compositeScaleOf(tester, key));
    }
    expect(peak, greaterThan(2.001),
        reason: 'the spring must overshoot past the target scale');
    await tester.pumpAndSettle();
    expect(compositeScaleOf(tester, key), closeTo(2.0, 1e-9));
  });
}
