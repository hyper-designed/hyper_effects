import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

void main() {
  // The stamp: 350ms easeOutQuart to (1.5, 15deg), 150ms hold, then 300ms
  // easeOutBack to (1.0, 0deg). Total 800ms.
  late TimelineSpec spec;

  setUp(() {
    spec = TimelineSpec.compile(
      const SizedBox.square(dimension: 74)
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
          .rotate(0),
    );
  });

  double scaleAt(double t) =>
      (spec.evaluate(t).singleWhere((e) => e is ScaleEffect) as ScaleEffect)
          .scale!;

  double angleAt(double t) =>
      (spec.evaluate(t).singleWhere((e) => e is RotationEffect)
              as RotationEffect)
          .angle;

  test('t=0 renders the first keyframe', () {
    expect(scaleAt(0), 0);
    expect(angleAt(0), 0);
  });

  test('mid segment 1 lerps along the segment curve', () {
    // 175ms of 800ms total; segment-local progress 0.5.
    final curved = Curves.easeOutQuart.transform(0.5);
    expect(scaleAt(175 / 800), closeTo(1.5 * curved, 1e-9));
    expect(angleAt(175 / 800), closeTo(15 * pi / 180 * curved, 1e-9));
  });

  test('during a delay the previous keyframe holds', () {
    // 350ms..500ms is segment 2's delay window.
    expect(scaleAt(400 / 800), 1.5);
    expect(scaleAt(499 / 800), 1.5);
  });

  test('mid segment 2 lerps from held value along its own curve', () {
    // 650ms: segment-2-local progress (650-500)/300 = 0.5.
    final curved = Curves.easeOutBack.transform(0.5);
    expect(scaleAt(650 / 800), closeTo(1.5 + (1 - 1.5) * curved, 1e-9));
  });

  test('t=1 renders the final keyframe', () {
    expect(scaleAt(1), 1);
    expect(angleAt(1), 0);
  });

  test('out-of-range times clamp', () {
    expect(scaleAt(-0.5), 0);
    expect(scaleAt(1.5), 1);
  });

  test('zero-duration segment snaps to its end keyframe', () {
    final snap = TimelineSpec.compile(
      const SizedBox()
          .scale(0)
          .step(duration: Duration.zero)
          .scale(2)
          .step(duration: const Duration(milliseconds: 100))
          .scale(3),
    );
    final scale =
        (snap.evaluate(0).single as ScaleEffect).scale; // t=0: after snap seg?
    // At exactly t=0 the timeline is at its start: first keyframe.
    expect(scale, 0);
    // Any t past the zero-duration segment's position renders its end.
    final justAfter = (snap.evaluate(0.001).single as ScaleEffect).scale;
    expect(justAfter, greaterThanOrEqualTo(2));
  });
}
