import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

/// [AlignEffect] is a [VectorEffect]. The alignment vectorizes cleanly;
/// the nullable size factors do not, and this file pins the exact rule
/// that lets them ride along anyway without changing what anyone sees:
/// nullability comes from the LEFT operand, which — because the spring
/// solver always puts the TARGET on the left — reproduces the
/// snap-to-target behaviour `lerp` has always had.
void main() {
  const Key boxKey = Key('box');

  group('vector arithmetic on alignment', () {
    test('adds, subtracts and scales field-wise', () {
      final a = AlignEffect(alignment: const Alignment(0.5, -0.25));
      final b = AlignEffect(alignment: const Alignment(0.25, 0.5));

      expect((a + b).alignment, const Alignment(0.75, 0.25));
      expect((a - b).alignment, const Alignment(0.25, -0.75));
      expect((a * 2).alignment, const Alignment(1, -0.5));
      expect(a.magnitudeSquared, closeTo(0.25 + 0.0625, 1e-12));
    });

    test('spans the absolute / directional divide', () {
      final absolute = AlignEffect(alignment: const Alignment(1, 0));
      final directional =
          AlignEffect(alignment: const AlignmentDirectional(1, 0));

      // AlignmentGeometry.add mixes the two forms; equality is on the
      // resolved components, so the sum reads back as a plain sum.
      final sum = absolute + directional;
      expect(sum.alignment.resolve(TextDirection.ltr), const Alignment(2, 0));
      expect(sum.alignment.resolve(TextDirection.rtl), Alignment.center);
      expect((absolute - absolute).alignment, Alignment.center);
    });

    test('lerp is derivable from the algebra when factors agree', () {
      final a = AlignEffect(alignment: Alignment.topLeft, widthFactor: 1);
      final b = AlignEffect(alignment: Alignment.bottomRight, widthFactor: 3);

      final derived = a + (b - a) * 0.25;
      final lerped = a.lerp(b, 0.25);
      expect(derived.alignment, lerped.alignment);
      expect(derived.widthFactor, lerped.widthFactor);
    });
  });

  group('factor nullability rides from the left operand', () {
    test('both present: the numbers combine', () {
      final sum = AlignEffect(widthFactor: 2, heightFactor: 5) +
          AlignEffect(widthFactor: 3, heightFactor: 1);
      expect(sum.widthFactor, 5);
      expect(sum.heightFactor, 6);

      final difference =
          AlignEffect(widthFactor: 2) - AlignEffect(widthFactor: 3);
      expect(difference.widthFactor, -1,
          reason: 'the displacement term is routinely negative');
    });

    test('neither present: the result carries none', () {
      expect((AlignEffect() + AlignEffect()).widthFactor, isNull);
      expect((AlignEffect() - AlignEffect()).heightFactor, isNull);
      expect((AlignEffect() * 3).widthFactor, isNull);
    });

    test('only the left present: its value passes through unchanged', () {
      expect((AlignEffect(widthFactor: 2) + AlignEffect()).widthFactor, 2);
      expect((AlignEffect(widthFactor: 2) - AlignEffect()).widthFactor, 2);
    });

    test('only the right present: the result carries none', () {
      expect((AlignEffect() + AlignEffect(widthFactor: 2)).widthFactor, isNull);
      expect((AlignEffect() - AlignEffect(widthFactor: 2)).widthFactor, isNull);
    });

    /// The load-bearing consequence. This is the shape the spring solver
    /// evaluates every frame; if it is ever reformulated so the target is
    /// no longer the left operand, mixed factor pairs would silently stop
    /// snapping and this test is the alarm.
    test('the solver form reproduces lerp\'s snap-to-target rule', () {
      const coefficients = <double>[1, 0.7, 0.0, -0.3, 1.4];

      AlignEffect solve(AlignEffect start, AlignEffect end, double a) =>
          end + (start - end) * a;

      final nullToValue = [
        AlignEffect(alignment: Alignment.topLeft),
        AlignEffect(alignment: Alignment.bottomRight, widthFactor: 2),
      ];
      for (final a in coefficients) {
        expect(solve(nullToValue[0], nullToValue[1], a).widthFactor, 2,
            reason: 'null -> 2 must read 2 from the very first frame, '
                'exactly as lerp(_, _, any) does');
      }
      expect(nullToValue[0].lerp(nullToValue[1], 0.5).widthFactor, 2);

      final valueToNull = [
        AlignEffect(widthFactor: 2),
        AlignEffect(),
      ];
      for (final a in coefficients) {
        expect(solve(valueToNull[0], valueToNull[1], a).widthFactor, isNull,
            reason: '2 -> null must read null from the very first frame');
      }
      expect(valueToNull[0].lerp(valueToNull[1], 0.5).widthFactor, isNull);
    });
  });

  group('apply floors factors, never alignment', () {
    testWidgets('a negative factor is floored at zero and null is preserved',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: AlignEffect(
            alignment: const Alignment(1.4, -1.9),
            widthFactor: -3,
          ).apply(
            tester.binding.rootElement! as BuildContext,
            const SizedBox.square(dimension: 10),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final Align align = tester.widget(find.byType(Align));
      expect(align.widthFactor, 0);
      expect(align.heightFactor, isNull,
          reason: 'null is a layout mode, not a number to floor');
      expect(align.alignment, const Alignment(1.4, -1.9),
          reason: 'alignment overshoot is meaningful and must be untouched');
    });
  });

  group('spring behaviour', () {
    Widget alignHost(bool on) => Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: const SizedBox.square(dimension: 50, key: boxKey)
                  .alignX(on ? 1 : -1)
                  .animate(
                    trigger: on,
                    motion: const CupertinoMotion.bouncy(),
                  ),
            ),
          ),
        );

    double xOf(WidgetTester tester) =>
        tester.getTopLeft(find.byKey(boxKey)).dx -
        tester.getTopLeft(find.byType(Align)).dx;

    testWidgets('alignment overshoots its target', (tester) async {
      await tester.pumpWidget(alignHost(false));
      await tester.pump();
      await tester.pumpWidget(alignHost(true));
      await tester.pump();

      var peak = 0.0;
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        peak = max(peak, xOf(tester));
      }

      // 200 wide box, 50 wide child: alignment x == 1 lands at dx == 150.
      expect(peak, greaterThan(150));
      await tester.pumpAndSettle();
      expect(xOf(tester), closeTo(150, 1e-6));
    });

    testWidgets('velocity carries across a mid-flight alignment retarget',
        (tester) async {
      await tester.pumpWidget(alignHost(false));
      await tester.pump();
      await tester.pumpWidget(alignHost(true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 96));

      final p1 = xOf(tester);
      await tester.pump(const Duration(milliseconds: 16));
      final vBefore = (xOf(tester) - p1) / 0.016;
      expect(vBefore.abs(), greaterThan(100),
          reason: 'precondition: must be moving fast mid-flight');

      await tester.pumpWidget(alignHost(false));
      await tester.pump();

      final p3 = xOf(tester);
      await tester.pump(const Duration(milliseconds: 16));
      final vAfter = (xOf(tester) - p3) / 0.016;

      expect(vAfter.sign, vBefore.sign,
          reason: 'momentum must initially continue in the same direction');
      expect(vAfter.abs(), greaterThan(vBefore.abs() * 0.5));
    });

    Widget factorHost(bool on) => Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: const SizedBox.square(dimension: 50, key: boxKey)
                .align(
                  on ? Alignment.bottomRight : Alignment.topLeft,
                  widthFactor: on ? 2 : null,
                )
                .animate(
                  trigger: on,
                  motion: const CupertinoMotion.bouncy(),
                ),
          ),
        );

    testWidgets('a mixed null / non-null factor still snaps to the target',
        (tester) async {
      await tester.pumpWidget(factorHost(false));
      await tester.pumpAndSettle();
      expect(tester.widget<Align>(find.byType(Align)).widthFactor, isNull);

      // null -> 2 under a spring: the factor must read 2 immediately, the
      // way it does on the lerp path, and stay there for the whole flight.
      await tester.pumpWidget(factorHost(true));
      await tester.pump();
      for (var i = 0; i < 40; i++) {
        expect(tester.widget<Align>(find.byType(Align)).widthFactor, 2,
            reason: 'frame $i must already be at the target factor');
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pumpAndSettle();
      expect(tester.widget<Align>(find.byType(Align)).widthFactor, 2);

      // 2 -> null must snap the other way, just as promptly.
      await tester.pumpWidget(factorHost(false));
      await tester.pump();
      for (var i = 0; i < 40; i++) {
        expect(tester.widget<Align>(find.byType(Align)).widthFactor, isNull,
            reason: 'frame $i must already be back to "fill constraints"');
        await tester.pump(const Duration(milliseconds: 16));
      }
    });

    Widget shrinkHost(bool on) => Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: const SizedBox.square(dimension: 50, key: boxKey)
                .align(
                  Alignment.center,
                  widthFactor: on ? 0 : 2,
                  heightFactor: 1,
                )
                .animate(
                  trigger: on,
                  motion: const CupertinoMotion.bouncy(),
                ),
          ),
        );

    testWidgets('a factor that undershoots below zero never reaches layout',
        (tester) async {
      await tester.pumpWidget(shrinkHost(false));
      await tester.pumpAndSettle();
      expect(tester.widget<Align>(find.byType(Align)).widthFactor, 2);

      // 2 -> 0 with a bouncy spring wants to pass below zero.
      await tester.pumpWidget(shrinkHost(true));
      await tester.pump();

      var sawFloor = false;
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.takeException(), isNull);
        final factor = tester.widget<Align>(find.byType(Align)).widthFactor!;
        expect(factor, greaterThanOrEqualTo(0),
            reason: 'RenderPositionedBox asserts a non-negative factor');
        if (factor == 0) sawFloor = true;
      }

      expect(sawFloor, isTrue,
          reason: 'precondition: the animation must actually hit the floor');
    });
  });

  test('AlignEffect rejects NaN widthFactor', () {
    expect(
      () => AlignEffect(widthFactor: double.nan),
      throwsA(isA<AssertionError>().having(
        (error) => error.message,
        'message',
        contains('widthFactor'),
      )),
    );
  });

  test('AlignEffect rejects NaN heightFactor', () {
    expect(
      () => AlignEffect(heightFactor: double.nan),
      throwsA(isA<AssertionError>().having(
        (error) => error.message,
        'message',
        contains('heightFactor'),
      )),
    );
  });

  test('infinite factors never manufacture NaN', () {
    final start = AlignEffect(widthFactor: double.infinity);
    final target = AlignEffect(widthFactor: double.infinity);

    for (final coefficient in <double>[1, 0.5, 0]) {
      final solved = target + (start - target) * coefficient;
      expect(solved.widthFactor?.isNaN, isFalse,
          reason: 'coefficient $coefficient');
      expect(solved.widthFactor, double.infinity);
    }
  });
}
