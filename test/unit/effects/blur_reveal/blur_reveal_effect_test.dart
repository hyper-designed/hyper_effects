import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

void main() {
  const style = TextStyle(fontFamily: 'TestLatin', fontSize: 32);

  group('BlurRevealEffect', () {
    test('has sensible defaults from the design spec', () {
      const effect = BlurRevealEffect(text: 'hello', style: style);
      expect(effect.text, 'hello');
      expect(effect.style, style);
      expect(effect.delay, Duration.zero);
      expect(effect.speedReveal, 1.0);
      expect(effect.speedSegment, 0.5);
      expect(effect.blurSigma, 10.0);
      expect(effect.riseFrom, const Offset(0, 12));
      expect(effect.curve, Curves.easeOutCubic);
      expect(effect.textDirection, isNull);
      expect(effect.textAlign, isNull);
      expect(effect.textScaler, isNull);
      expect(effect.strutStyle, isNull);
      expect(effect.textHeightBehavior, isNull);
      expect(effect.locale, isNull);
      expect(effect.maxWidth, isNull);
    });

    test('equality is structural via EquatableMixin', () {
      const a = BlurRevealEffect(text: 'hi', style: style, speedReveal: 2.0);
      const b = BlurRevealEffect(text: 'hi', style: style, speedReveal: 2.0);
      const c = BlurRevealEffect(text: 'hi', style: style, speedReveal: 3.0);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('lerp snaps to `other` at any value (decorator runs in paint)', () {
      const a = BlurRevealEffect(text: 'old', style: style);
      const b = BlurRevealEffect(text: 'new', style: style);
      for (final v in const [0.0, 0.25, 0.5, 0.75, 1.0]) {
        final result = a.lerp(b, v);
        expect(result, isA<BlurRevealEffect>());
        expect(result.text, 'new',
            reason: 'at v=$v, lerp should snap to other');
      }
    });

    test('riseFrom can be set to Offset.zero to disable rise', () {
      const effect = BlurRevealEffect(
        text: 'hi',
        style: style,
        riseFrom: Offset.zero,
      );
      expect(effect.riseFrom, Offset.zero);
    });
  });
}
