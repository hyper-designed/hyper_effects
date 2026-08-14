import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';
import 'package:material_ui/material_ui.dart';

/// Contract for [VectorEffect]: typed vector arithmetic on the effect
/// itself — the structure spring physics needs, with components never
/// exposed as raw numbers.
void main() {
  group('TranslateEffect', () {
    final a = TranslateEffect(offset: const Offset(10, 20));
    final b = TranslateEffect(offset: const Offset(1, 2));

    test('arithmetic is field-wise', () {
      expect((a + b).offset, const Offset(11, 22));
      expect((a - b).offset, const Offset(9, 18));
      expect((a * 2).offset, const Offset(20, 40));
      expect(a.magnitudeSquared, 10 * 10 + 20 * 20);
    });

    test('non-vector fields ride along from the left operand', () {
      final fractional = TranslateEffect(
        offset: const Offset(1, 0),
        fractional: true,
      );
      expect((fractional + b).fractional, isTrue);
      expect((fractional * 2).fractional, isTrue);
    });

    test('lerp is derivable from the algebra', () {
      final derived = a + (b - a) * 0.25;
      expect(derived, a.lerp(b, 0.25));
    });
  });

  group('ScaleEffect', () {
    test('arithmetic works across uniform and split forms', () {
      final uniform = ScaleEffect(scale: 2);
      final split = ScaleEffect(scaleX: 1, scaleY: 3);
      final sum = uniform + split;
      // Effective per-axis values combine; the result renders identically
      // regardless of declared form.
      expect(sum.scaleX ?? sum.scale, 3);
      expect(sum.scaleY ?? sum.scale, 5);
    });

    test('scaling and magnitude', () {
      final s = ScaleEffect(scaleX: 3, scaleY: 4);
      final doubled = s * 2;
      expect(doubled.scaleX, 6);
      expect(doubled.scaleY, 8);
      expect(s.magnitudeSquared, 25);
    });
  });

  group('RotationEffect', () {
    const a = RotationEffect(angle: 1.0, alignment: Alignment.topCenter);
    const b = RotationEffect(angle: 0.25);

    test('arithmetic on angle; alignment rides along', () {
      expect((a + b).angle, 1.25);
      expect((a - b).angle, 0.75);
      expect((a * 2).angle, 2.0);
      expect((a + b).alignment, Alignment.topCenter);
      expect(a.magnitudeSquared, 1.0);
    });
  });

  group('OpacityEffect', () {
    final a = OpacityEffect(opacity: 0.5);
    final b = OpacityEffect(opacity: 0.25);

    test('arithmetic on opacity, unclamped for physics', () {
      expect((a + b).opacity, 0.75);
      expect((a - b).opacity, 0.25);
      expect((a * 3).opacity, 1.5, reason: 'velocity math needs >1 values');
      expect(b.magnitudeSquared, 0.0625);
    });

    testWidgets('apply clamps overshoot so the Opacity widget never throws',
        (tester) async {
      await tester.pumpWidget(
        OpacityEffect(opacity: 1.2).apply(context_(tester), const SizedBox()),
      );
      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1.0);
      await tester.pumpWidget(
        OpacityEffect(opacity: -0.2).apply(context_(tester), const SizedBox()),
      );
      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0.0);
    });
  });
}

BuildContext context_(WidgetTester tester) =>
    tester.binding.rootElement! as BuildContext;
