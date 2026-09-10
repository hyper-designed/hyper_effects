import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

/// [SizeEffect] is a [VectorEffect] that constrains layout, not paint. This
/// file checks that the constraint actually reaches [RenderBox.size] (not
/// just the widget's own parameters), that it overshoots and hands off
/// velocity like every other [VectorEffect], that overshoot below zero
/// never reaches [SizedBox] as a negative dimension, and pins the
/// null-axis / non-finite rules documented on the class.
void main() {
  const Key boxKey = Key('box');

  group('SizeEffect layout semantics', () {
    testWidgets('widthTo() actually changes the rendered layout size',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: const SizedBox(key: boxKey, height: 40).widthTo(120),
          ),
        ),
      );

      // Reading the rendered size, not the widget's constructor argument,
      // is the point: layout is what SizeEffect promises to change.
      expect(tester.getSize(find.byKey(boxKey)), const Size(120, 40));
    });

    testWidgets('heightTo() actually changes the rendered layout size',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: const SizedBox(key: boxKey, width: 40).heightTo(90),
          ),
        ),
      );

      expect(tester.getSize(find.byKey(boxKey)), const Size(40, 90));
    });

    testWidgets('sizeTo() constrains both axes', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: const SizedBox(key: boxKey).sizeTo(const Size(80, 60)),
          ),
        ),
      );

      expect(tester.getSize(find.byKey(boxKey)), const Size(80, 60));
    });

    testWidgets('sizeOf() constrains one axis, leaving the other to flow',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: const SizedBox(key: boxKey, height: 30).sizeOf(width: 70),
          ),
        ),
      );

      expect(tester.getSize(find.byKey(boxKey)), const Size(70, 30));
    });

    testWidgets(
        'widthTo() reflows a sibling, unlike scale() which paints on top',
        (tester) async {
      const Key siblingKey = Key('sibling');
      Widget host(double w) => Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(key: boxKey, height: 20).widthTo(w),
                const SizedBox(key: siblingKey, width: 10, height: 20),
              ],
            ),
          );

      await tester.pumpWidget(host(20));
      final double x1 = tester.getTopLeft(find.byKey(siblingKey)).dx;
      await tester.pumpWidget(host(80));
      final double x2 = tester.getTopLeft(find.byKey(siblingKey)).dx;

      expect(x2 - x1, closeTo(60, 1e-6),
          reason: 'the sibling must actually move when widthTo() grows, '
              'because SizeEffect changes layout rather than just paint');
    });
  });

  group('vector arithmetic on width/height', () {
    test('adds, subtracts and scales field-wise', () {
      final a = SizeEffect(width: 10, height: 20);
      final b = SizeEffect(width: 4, height: 5);

      expect((a + b).width, 14);
      expect((a + b).height, 25);
      expect((a - b).width, 6);
      expect((a - b).height, 15);
      expect((a * 2).width, 20);
      expect((a * 2).height, 40);
      expect(a.magnitudeSquared, closeTo(100 + 400, 1e-9));
    });

    test('lerp is derivable from the algebra when both axes agree', () {
      final a = SizeEffect(width: 10, height: 40);
      final b = SizeEffect(width: 50, height: 0);

      final derived = a + (b - a) * 0.25;
      final lerped = a.lerp(b, 0.25);
      expect(derived.width, lerped.width);
      expect(derived.height, lerped.height);
    });
  });

  group('null-axis rule', () {
    test('both null: the result stays unconstrained', () {
      expect((SizeEffect() + SizeEffect()).width, isNull);
      expect((SizeEffect() - SizeEffect()).height, isNull);
      expect((SizeEffect() * 3).width, isNull);
      expect(SizeEffect().lerp(SizeEffect(), 0.5).width, isNull);
    });

    test('only the left present: its value passes through unchanged', () {
      expect((SizeEffect(width: 10) + SizeEffect()).width, 10);
      expect((SizeEffect(width: 10) - SizeEffect()).width, 10);
    });

    test('only the right present: the result carries none', () {
      expect((SizeEffect() + SizeEffect(width: 10)).width, isNull);
      expect((SizeEffect() - SizeEffect(width: 10)).width, isNull);
    });

    test('lerp snaps to the target on a mixed null / non-null pair', () {
      final nullToValue = SizeEffect().lerp(SizeEffect(width: 200), 0.5);
      expect(nullToValue.width, 200);

      final valueToNull = SizeEffect(width: 200).lerp(SizeEffect(), 0.5);
      expect(valueToNull.width, isNull);
    });

    /// The load-bearing consequence: this is the exact shape the spring
    /// solver evaluates every frame (target on the left of `+`), so a
    /// mixed pair must resolve to the target's mode from the very first
    /// frame, matching what lerp has always done.
    test('the solver form reproduces lerp\'s snap-to-target rule', () {
      const coefficients = <double>[1, 0.7, 0.0, -0.3, 1.4];
      SizeEffect solve(SizeEffect start, SizeEffect end, double a) =>
          end + (start - end) * a;

      final start = SizeEffect(width: 200);
      final end = SizeEffect();
      for (final a in coefficients) {
        expect(solve(start, end, a).width, isNull,
            reason: '200 -> null must read null from the very first frame');
      }
      expect(start.lerp(end, 0.5).width, isNull);
    });

    test('idle() resets both axes to unconstrained, not a value copy', () {
      // idle() is the implicit starting point for a widget that animates in
      // without an explicit `from` — it must read as "no SizeEffect was ever
      // applied," matching AlignEffect.idle()'s null factors, not preserve
      // whatever width/height this particular instance happens to hold.
      final idle = SizeEffect(width: 40, height: 50).idle();
      expect(idle.width, isNull);
      expect(idle.height, isNull);
    });
  });

  group('non-finite hazard', () {
    test('operator - poisons an infinite axis to null instead of NaN', () {
      final difference = SizeEffect(width: double.infinity) -
          SizeEffect(width: double.infinity);
      expect(difference.width, isNull,
          reason: 'infinity - infinity is NaN; this must never surface');
    });

    test('operator - poisons when only one side is infinite', () {
      final difference =
          SizeEffect(width: double.infinity) - SizeEffect(width: 10);
      expect(difference.width, isNull);
    });

    test('operator + still resolves a genuinely infinite target', () {
      // By construction the engine only ever pairs an infinite endpoint
      // with a displacement that operator - has already nulled on that
      // axis, so + only ever needs its ordinary null-check shape.
      final result =
          SizeEffect(width: double.infinity) + SizeEffect(width: null);
      expect(result.width, double.infinity);
    });

    test('lerp snaps to the target on a non-finite endpoint', () {
      final growing =
          SizeEffect(width: 10).lerp(SizeEffect(width: double.infinity), 0.5);
      expect(growing.width, double.infinity);

      final shrinking =
          SizeEffect(width: double.infinity).lerp(SizeEffect(width: 10), 0.5);
      expect(shrinking.width, 10);
    });

    test('magnitudeSquared never turns into NaN or infinity', () {
      final effect = SizeEffect(width: double.infinity, height: 5);
      expect(effect.magnitudeSquared.isFinite, isTrue);
    });
  });

  group('apply floors overshoot at zero', () {
    testWidgets('a negative width never reaches SizedBox', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizeEffect(width: -10, height: 20).apply(
            tester.binding.rootElement! as BuildContext,
            null,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final SizedBox sizedBox = tester.widget(find.byType(SizedBox));
      expect(sizedBox.width, 0);
      expect(sizedBox.height, 20);
    });

    testWidgets('a null axis is preserved through apply, not floored',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizeEffect(width: -10).apply(
            tester.binding.rootElement! as BuildContext,
            null,
          ),
        ),
      );

      final SizedBox sizedBox = tester.widget(find.byType(SizedBox));
      expect(sizedBox.height, isNull,
          reason: 'null is a layout mode, not a number to floor');
    });
  });

  group('spring behaviour', () {
    Widget widthHost(bool grown) => Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: const SizedBox(key: boxKey, height: 20)
                .widthTo(grown ? 200 : 20)
                .animate(
                  trigger: grown,
                  motion: const CupertinoMotion.bouncy(),
                ),
          ),
        );

    testWidgets('width overshoots its target', (tester) async {
      await tester.pumpWidget(widthHost(false));
      await tester.pump();
      await tester.pumpWidget(widthHost(true));
      await tester.pump();

      var peak = 0.0;
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        peak = max(peak, tester.getSize(find.byKey(boxKey)).width);
      }

      expect(peak, greaterThan(200),
          reason: 'a bouncy spring must overshoot the 200 target width');
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(boxKey)).width, closeTo(200, 1e-6));
    });

    testWidgets('velocity carries across a mid-flight width retarget',
        (tester) async {
      await tester.pumpWidget(widthHost(false));
      await tester.pump();
      await tester.pumpWidget(widthHost(true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 96));

      final double p1 = tester.getSize(find.byKey(boxKey)).width;
      await tester.pump(const Duration(milliseconds: 16));
      final double p2 = tester.getSize(find.byKey(boxKey)).width;
      final double vBefore = (p2 - p1) / 0.016;
      expect(vBefore.abs(), greaterThan(50),
          reason: 'precondition: width must be changing fast mid-flight');

      await tester.pumpWidget(widthHost(false));
      await tester.pump();

      final double p3 = tester.getSize(find.byKey(boxKey)).width;
      await tester.pump(const Duration(milliseconds: 16));
      final double p4 = tester.getSize(find.byKey(boxKey)).width;
      final double vAfter = (p4 - p3) / 0.016;

      expect(vAfter.sign, vBefore.sign,
          reason: 'momentum must initially continue in the same direction');
      expect(vAfter.abs(), greaterThan(vBefore.abs() * 0.3),
          reason: 'the handed-off speed must be of the same order, not ~zero');
    });

    Widget shrinkHost(bool on) => Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: const SizedBox(key: boxKey, height: 20)
                .widthTo(on ? 0 : 40)
                .animate(
                  trigger: on,
                  motion: const CupertinoMotion.bouncy(),
                ),
          ),
        );

    testWidgets('an undershooting width never renders negative or throws',
        (tester) async {
      await tester.pumpWidget(shrinkHost(false));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(boxKey)).width, 40);

      // 40 -> 0 with a bouncy spring wants to swing below zero.
      await tester.pumpWidget(shrinkHost(true));
      await tester.pump();

      var sawFloor = false;
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.takeException(), isNull);
        final double width = tester.getSize(find.byKey(boxKey)).width;
        expect(width, greaterThanOrEqualTo(0),
            reason: 'SizedBox asserts a non-negative width');
        if (width == 0) sawFloor = true;
      }

      expect(sawFloor, isTrue,
          reason: 'precondition: the animation must actually hit the floor');
    });
  });

  test('SizeEffect rejects NaN width', () {
    expect(
      () => SizeEffect(width: double.nan),
      throwsA(
        isA<AssertionError>().having(
          (error) => error.message,
          'message',
          contains('width'),
        ),
      ),
    );
  });

  test('SizeEffect rejects NaN height', () {
    expect(
      () => SizeEffect(height: double.nan),
      throwsA(
        isA<AssertionError>().having(
          (error) => error.message,
          'message',
          contains('height'),
        ),
      ),
    );
  });
}
