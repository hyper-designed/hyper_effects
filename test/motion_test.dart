import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

void main() {
  group('CurvedMotion', () {
    test('effectiveDuration is the declared duration', () {
      const motion = CurvedMotion(Duration(milliseconds: 350), Curves.easeOut);
      expect(motion.effectiveDuration, const Duration(milliseconds: 350));
    });

    test('transform is the curve', () {
      const motion = CurvedMotion(Duration(milliseconds: 350), Curves.easeOut);
      for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        expect(motion.transform(t), Curves.easeOut.transform(t));
      }
    });
  });

  group('SpringMotion', () {
    const bouncy = CupertinoMotion.bouncy();
    const smooth = CupertinoMotion.smooth();

    test('endpoints are exact', () {
      expect(bouncy.transform(0), 0);
      expect(bouncy.transform(1), 1);
      expect(smooth.transform(0), 0);
      expect(smooth.transform(1), 1);
    });

    test('effectiveDuration is a finite, positive settling bound', () {
      expect(bouncy.effectiveDuration.inMicroseconds, greaterThan(0));
      expect(bouncy.effectiveDuration.inSeconds, lessThan(30),
          reason: 'a bouncy preset must settle in sane time');
      // A bouncier spring takes at least as long to settle as a smooth one
      // of the same perceptual duration.
      expect(
        bouncy.effectiveDuration >= smooth.effectiveDuration,
        isTrue,
      );
    });

    test('the spring has actually settled at its bound', () {
      // Just before t=1, the raw simulation value must be within an order
      // of magnitude of tolerance from the target.
      final value = bouncy.transform(0.999);
      expect((value - 1).abs(), lessThan(0.01));
    });

    test('an underdamped spring overshoots past 1.0 mid-flight', () {
      var peak = 0.0;
      for (var i = 1; i < 200; i++) {
        peak = max(peak, bouncy.transform(i / 200));
      }
      expect(peak, greaterThan(1.001),
          reason: 'bouncy springs must visibly overshoot');
    });

    test('an undamped spring throws loudly instead of never settling', () {
      const undamped = SpringMotion(
        SpringDescription(mass: 1, stiffness: 100, damping: 0),
      );
      expect(() => undamped.effectiveDuration, throwsStateError);
    });
  });

  group('NoMotion', () {
    test('holds at 0 and reports its duration', () {
      const none = NoMotion(Duration(seconds: 1));
      expect(none.effectiveDuration, const Duration(seconds: 1));
      expect(none.transform(0.5), 0);
    });
  });

  group('TrimmedMotion', () {
    test('spans 0..1 over the trimmed window', () {
      const trimmed = TrimmedMotion(
        parent: CurvedMotion(Duration(milliseconds: 400)),
        fromStart: 0.25,
        fromEnd: 0.25,
      );
      expect(trimmed.transform(0), 0);
      expect(trimmed.transform(1), 1);
      // Linear parent trimmed symmetrically stays linear.
      expect(trimmed.transform(0.5), closeTo(0.5, 1e-9));
      expect(trimmed.effectiveDuration, const Duration(milliseconds: 200));
    });
  });

  group('CurveSimulation', () {
    test('dx approximates the true derivative', () {
      // Linear 0..1 over 1 second: velocity is exactly 1.0 mid-flight.
      final simulation = const CurvedMotion(
        Duration(seconds: 1),
        Curves.linear,
      ).createSimulation();
      expect(simulation.dx(0.5), closeTo(1.0, 0.05));
    });
  });
}
