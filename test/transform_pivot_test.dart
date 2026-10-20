import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

/// A rotation or scale pivots about `alignment + origin`. Both ends of the
/// tween must agree on that pivot, or it drifts across the run.
void main() {
  const origin = Offset(4, 2);
  const alignment = Alignment.topLeft;

  group('from: keeps the pivot', () {
    test('rotate', () {
      final widget = const SizedBox().rotate(
        1,
        from: 0,
        origin: origin,
        alignment: alignment,
      ) as EffectWidget;
      final start = widget.start! as RotationEffect;
      expect(start.origin, origin);
      expect(start.alignment, alignment);
    });

    test('scale', () {
      final widget = const SizedBox().scale(
        1,
        from: 1.25,
        origin: origin,
        alignment: alignment,
      ) as EffectWidget;
      final start = widget.start! as ScaleEffect;
      expect(start.origin, origin);
      expect(start.alignment, alignment);
    });

    test('scaleX, scaleY and scaleXY', () {
      for (final widget in [
        const SizedBox()
            .scaleX(1, from: 0, origin: origin, alignment: alignment),
        const SizedBox()
            .scaleY(1, from: 0, origin: origin, alignment: alignment),
        const SizedBox().scaleXY(
          1,
          1,
          from: Offset.zero,
          origin: origin,
          alignment: alignment,
        ),
      ]) {
        final start = (widget as EffectWidget).start! as ScaleEffect;
        expect(start.origin, origin);
        expect(start.alignment, alignment);
      }
    });

    test('rotateIn and rotateOut', () {
      final rotateIn = const SizedBox().rotateIn(
        origin: origin,
        alignment: alignment,
      ) as EffectWidget;
      final rotateOut = const SizedBox().rotateOut(
        origin: origin,
        alignment: alignment,
      ) as EffectWidget;
      expect((rotateIn.start! as RotationEffect).origin, origin);
      expect((rotateIn.start! as RotationEffect).alignment, alignment);
      expect((rotateOut.end as RotationEffect).origin, origin);
      expect((rotateOut.end as RotationEffect).alignment, alignment);
    });
  });

  group('idle keeps the pivot', () {
    test('rotation', () {
      const effect = RotationEffect(
        angle: 1,
        origin: origin,
        alignment: alignment,
      );
      expect(effect.idle().origin, origin);
      expect(effect.idle().alignment, alignment);
      expect(effect.idle().angle, 0);
    });

    test('scale', () {
      final effect = ScaleEffect(
        scale: 2,
        origin: origin,
        alignment: alignment,
        transformHitTests: false,
      );
      expect(effect.idle().origin, origin);
      expect(effect.idle().alignment, alignment);
      expect(effect.idle().transformHitTests, isFalse);
      expect(effect.idle().scale, 1);
    });
  });
}
