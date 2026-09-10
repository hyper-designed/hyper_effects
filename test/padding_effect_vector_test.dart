import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

/// [PaddingEffect] is a [VectorEffect], which buys it two things the
/// normalized lerp path cannot give: overshoot that is actually rendered,
/// and velocity that survives a mid-flight retarget. Non-negativity — the
/// price of real overshoot, since [RenderPadding] asserts it — is enforced
/// in `apply`, at the moment the value becomes layout, and nowhere earlier.
void main() {
  const Key boxKey = Key('box');

  /// A single [Padding] in the whole tree, pinned to the top left so the
  /// child's origin IS the rendered inset. Measuring geometry rather than
  /// the effect object proves the value reached the render tree.
  Widget host(bool expanded) => Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: const SizedBox.square(dimension: 50, key: boxKey)
              .padAll(expanded ? 100 : 0)
              .animate(
                trigger: expanded,
                motion: const CupertinoMotion.bouncy(),
              ),
        ),
      );

  double insetOf(WidgetTester tester) =>
      tester.getTopLeft(find.byKey(boxKey)).dx;

  EdgeInsetsGeometry renderedPadding(WidgetTester tester) => tester
      .widget<Padding>(
        find.ancestor(of: find.byKey(boxKey), matching: find.byType(Padding)),
      )
      .padding;

  group('vector arithmetic', () {
    test('is field-wise over the four insets', () {
      final a = PaddingEffect(
        padding: const EdgeInsets.fromLTRB(1, 2, 3, 4),
      );
      final b = PaddingEffect(
        padding: const EdgeInsets.fromLTRB(10, 20, 30, 40),
      );

      expect((a + b).padding, const EdgeInsets.fromLTRB(11, 22, 33, 44));
      expect((a - b).padding, const EdgeInsets.fromLTRB(-9, -18, -27, -36));
      expect((a * 2).padding, const EdgeInsets.fromLTRB(2, 4, 6, 8));
      expect(a.magnitudeSquared, 1 + 4 + 9 + 16);
    });

    test('lerp is derivable from the algebra, and extrapolates', () {
      final a = PaddingEffect(padding: const EdgeInsets.all(0));
      final b = PaddingEffect(padding: const EdgeInsets.all(100));

      expect(a + (b - a) * 0.25, a.lerp(b, 0.25));
      // The parameter is not clamped: this is how a spring or an
      // overshooting curve expresses overshoot.
      expect(a.lerp(b, 1.2).padding, const EdgeInsets.all(120));
      expect(a.lerp(b, -0.2).padding, const EdgeInsets.all(-20));
    });
  });

  group('apply is the only clamp', () {
    testWidgets('floors only the components that went negative',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PaddingEffect(
            padding: const EdgeInsets.fromLTRB(-5, 10, -0.5, 2),
          ).apply(
            tester.binding.rootElement! as BuildContext,
            const SizedBox.shrink(),
          ),
        ),
      );

      expect(
        tester.widget<Padding>(find.byType(Padding)).padding,
        const EdgeInsets.fromLTRB(0, 10, 0, 2),
        reason: 'an inset that overshot upward must survive intact',
      );
    });

    testWidgets('an all-negative padding renders as zero and does not throw',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PaddingEffect(padding: const EdgeInsets.all(-8)).apply(
            tester.binding.rootElement! as BuildContext,
            const SizedBox.shrink(),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.widget<Padding>(find.byType(Padding)).padding,
        EdgeInsets.zero,
      );
    });
  });

  testWidgets('padding overshoots its target under a spring motion',
      (tester) async {
    await tester.pumpWidget(host(false));
    await tester.pump();

    await tester.pumpWidget(host(true));
    await tester.pump();

    var peak = 0.0;
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      peak = max(peak, insetOf(tester));
    }

    expect(
      peak,
      greaterThan(100),
      reason: 'a bouncy spring must sail past its target, not ease into it',
    );

    await tester.pumpAndSettle();
    expect(
      insetOf(tester),
      closeTo(100, 1e-6),
      reason: 'and must still come to rest exactly on the target',
    );
  });

  testWidgets('an undershooting spring never renders a negative inset',
      (tester) async {
    await tester.pumpWidget(host(true));
    await tester.pumpAndSettle();
    expect(insetOf(tester), closeTo(100, 1e-6));

    // 100 -> 0 with a bouncy spring wants to pass below zero on the way.
    await tester.pumpWidget(host(false));
    await tester.pump();

    var sawRest = false;
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull);
      expect(
        renderedPadding(tester).isNonNegative,
        isTrue,
        reason: 'RenderPadding asserts non-negative insets',
      );
      expect(insetOf(tester), greaterThanOrEqualTo(0));
      if (insetOf(tester) == 0) sawRest = true;
    }

    expect(
      sawRest,
      isTrue,
      reason: 'precondition: the animation must actually reach the floor, '
          'otherwise this test never exercises the clamp',
    );
  });

  testWidgets('velocity carries across a mid-flight padding retarget',
      (tester) async {
    await tester.pumpWidget(host(false));
    await tester.pump();

    // Launch toward 100 and let it build up speed.
    await tester.pumpWidget(host(true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 96));

    final p1 = insetOf(tester);
    await tester.pump(const Duration(milliseconds: 16));
    final p2 = insetOf(tester);
    final vBefore = (p2 - p1) / 0.016;
    expect(vBefore.abs(), greaterThan(100),
        reason: 'precondition: the padding must be growing fast mid-flight');

    // Retarget back to 0 mid-flight...
    await tester.pumpWidget(host(false));
    await tester.pump();

    // ...momentum must carry, not reset to rest.
    final p3 = insetOf(tester);
    await tester.pump(const Duration(milliseconds: 16));
    final p4 = insetOf(tester);
    final vAfter = (p4 - p3) / 0.016;

    expect(vAfter.sign, vBefore.sign,
        reason: 'momentum must initially continue in the same direction');
    expect(vAfter.abs(), greaterThan(vBefore.abs() * 0.5),
        reason: 'the handed-off speed must be of the same order, not ~zero');
  });

  testWidgets('a retargeted padding spring never teleports between frames',
      (tester) async {
    await tester.pumpWidget(host(false));
    await tester.pump();

    await tester.pumpWidget(host(true));
    await tester.pump();

    var previous = insetOf(tester);
    var maxJump = 0.0;
    for (var i = 0; i < 40; i++) {
      if (i == 8) await tester.pumpWidget(host(false));
      await tester.pump(const Duration(milliseconds: 16));
      final current = insetOf(tester);
      maxJump = max(maxJump, (current - previous).abs());
      previous = current;
    }

    expect(maxJump, lessThan(20));
  });

  test('PaddingEffect rejects NaN components', () {
    final cases = <String, EdgeInsets>{
      'left': const EdgeInsets.only(left: double.nan),
      'top': const EdgeInsets.only(top: double.nan),
      'right': const EdgeInsets.only(right: double.nan),
      'bottom': const EdgeInsets.only(bottom: double.nan),
    };

    for (final entry in cases.entries) {
      expect(
        () => PaddingEffect(padding: entry.value),
        throwsA(isA<AssertionError>().having(
          (error) => error.message,
          'message',
          contains(entry.key),
        )),
        reason: entry.key,
      );
    }
  });

  testWidgets('infinite padding remains a valid render endpoint',
      (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 100,
          height: 100,
          child: PaddingEffect(
            padding: const EdgeInsets.all(double.infinity),
          ).apply(
            tester.binding.rootElement! as BuildContext,
            const SizedBox.square(dimension: 10),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  test('infinite insets never manufacture NaN', () {
    final start = PaddingEffect(
      padding: const EdgeInsets.all(double.infinity),
    );
    final target = PaddingEffect(
      padding: const EdgeInsets.all(double.infinity),
    );

    for (final coefficient in <double>[1, 0.5, 0]) {
      final solved = target + (start - target) * coefficient;
      final insets = solved.padding;
      expect(insets.left.isNaN, isFalse, reason: 'coefficient $coefficient');
      expect(insets.top.isNaN, isFalse);
      expect(insets.right.isNaN, isFalse);
      expect(insets.bottom.isNaN, isFalse);
      expect(insets, const EdgeInsets.all(double.infinity));
    }
  });
}
