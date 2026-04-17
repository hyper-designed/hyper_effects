import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

void main() {
  group('Effect.lerp — OpacityEffect', () {
    test('lerps opacity linearly', () {
      // OpacityEffect(opacity: double) — matches plan
      final a = OpacityEffect(opacity: 0.0);
      final b = OpacityEffect(opacity: 1.0);
      final mid = a.lerp(b, 0.5);
      expect(mid.opacity, closeTo(0.5, 1e-9));
    });

    test('returns start at value 0', () {
      final a = OpacityEffect(opacity: 0.2);
      final b = OpacityEffect(opacity: 0.8);
      expect(a.lerp(b, 0.0).opacity, closeTo(0.2, 1e-9));
    });

    test('returns end at value 1', () {
      final a = OpacityEffect(opacity: 0.2);
      final b = OpacityEffect(opacity: 0.8);
      expect(a.lerp(b, 1.0).opacity, closeTo(0.8, 1e-9));
    });
  });

  group('Effect.lerp — TranslateEffect', () {
    // TranslateEffect(offset: Offset) — matches plan
    test('lerps x and y independently', () {
      final a = TranslateEffect(offset: const Offset(0, 0));
      final b = TranslateEffect(offset: const Offset(100, 50));
      final mid = a.lerp(b, 0.5);
      expect(mid.offset.dx, closeTo(50, 1e-9));
      expect(mid.offset.dy, closeTo(25, 1e-9));
    });
  });

  group('Effect.lerp — ScaleEffect', () {
    // NOTE: Plan assumed ScaleEffect(scale: Size) but the actual constructor
    // uses ScaleEffect(scale: double?) for uniform scaling, or scaleX/scaleY
    // separately. There is NO Size parameter.
    test('lerps uniform scale', () {
      final a = ScaleEffect(scale: 1.0);
      final b = ScaleEffect(scale: 2.0);
      // ScaleEffect.lerp calls lerpDouble on scale; lerped value is applied
      // to both X and Y axes uniformly.
      final mid = a.lerp(b, 0.5);
      expect(mid.scale, closeTo(1.5, 1e-9));
    });

    test('lerps scaleX and scaleY independently', () {
      final a = ScaleEffect(scaleX: 1.0, scaleY: 1.0);
      final b = ScaleEffect(scaleX: 3.0, scaleY: 5.0);
      final mid = a.lerp(b, 0.5);
      expect(mid.scaleX, closeTo(2.0, 1e-9));
      expect(mid.scaleY, closeTo(3.0, 1e-9));
    });
  });

  group('Effect.lerp — BlurEffect', () {
    // BlurEffect(blur: double?) — matches plan param name; NOT const-constructible
    test('lerps blur sigmas', () {
      final a = BlurEffect(blur: 0);
      final b = BlurEffect(blur: 10);
      expect(a.lerp(b, 0.5).blur, closeTo(5, 1e-9));
    });

    test('returns start at value 0', () {
      final a = BlurEffect(blur: 2);
      final b = BlurEffect(blur: 8);
      expect(a.lerp(b, 0.0).blur, closeTo(2, 1e-9));
    });

    test('returns end at value 1', () {
      final a = BlurEffect(blur: 2);
      final b = BlurEffect(blur: 8);
      expect(a.lerp(b, 1.0).blur, closeTo(8, 1e-9));
    });
  });

  group('Effect.lerp — RotationEffect', () {
    // RotationEffect(angle: double) — matches plan
    test('lerps angle in radians', () {
      final a = const RotationEffect(angle: 0);
      final b = const RotationEffect(angle: 3.14);
      expect(a.lerp(b, 0.5).angle, closeTo(1.57, 0.01));
    });

    test('returns start at value 0', () {
      final a = const RotationEffect(angle: 0.0);
      final b = const RotationEffect(angle: 3.14);
      expect(a.lerp(b, 0.0).angle, closeTo(0.0, 1e-9));
    });

    test('returns end at value 1', () {
      final a = const RotationEffect(angle: 0.0);
      final b = const RotationEffect(angle: 3.14);
      expect(a.lerp(b, 1.0).angle, closeTo(3.14, 1e-9));
    });
  });

  group('Effect.lerp — RollingTextEffect', () {
    // RollingTextEffect.lerp (line 218-219 of rolling_text_effect.dart):
    //   @override
    //   RollingTextEffect lerp(covariant RollingTextEffect other, double value) => other;
    // i.e. lerp ALWAYS returns `other` regardless of value — snap behavior, no interpolation.
    test('returns `other` at value 0 (snap behavior)', () {
      final a = const RollingTextEffect(text: 'old');
      final b = const RollingTextEffect(text: 'new');
      expect(a.lerp(b, 0.0).text, 'new');
    });

    test('returns `other` at value 0.5 (snap behavior)', () {
      final a = const RollingTextEffect(text: 'old');
      final b = const RollingTextEffect(text: 'new');
      expect(a.lerp(b, 0.5).text, 'new');
    });

    test('returns `other` at value 1 (snap behavior)', () {
      final a = const RollingTextEffect(text: 'old');
      final b = const RollingTextEffect(text: 'new');
      expect(a.lerp(b, 1.0).text, 'new');
    });
  });
}
