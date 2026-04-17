import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

import '../../helpers/test_app.dart';

void main() {
  Future<void> pumpRoll(WidgetTester tester, Widget text) async {
    await tester.pumpWidget(
      wrapInTestApp(
        AnimatedBuilder(
          animation: const AlwaysStoppedAnimation(0),
          builder: (_, __) => text,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('.roll() parameters', () {
    testWidgets('default params build successfully', (tester) async {
      await pumpRoll(tester, const Text('abc').roll(renderMode: kLegacyRenderMode).animate(trigger: 0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('padding parameter threads through', (tester) async {
      await pumpRoll(
        tester,
        const Text('abc')
            .roll(
              renderMode: kLegacyRenderMode,
              padding: const EdgeInsets.all(8),
            )
            .animate(trigger: 0),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('custom tapeStrategy', (tester) async {
      await pumpRoll(
        tester,
        const Text('abc')
            .roll(
              renderMode: kLegacyRenderMode,
              tapeStrategy: const AllSymbolsTapeStrategy(),
            )
            .animate(trigger: 0),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapeSlideDirection up/down/alternating/random', (tester) async {
      for (final dir in TextTapeSlideDirection.values) {
        await pumpRoll(
          tester,
          const Text('abc')
              .roll(
                renderMode: kLegacyRenderMode,
                tapeSlideDirection: dir,
              )
              .animate(trigger: 0),
        );
        expect(tester.takeException(), isNull,
            reason: 'failed for direction=$dir');
      }
    });

    testWidgets('staggerTapes: true and false', (tester) async {
      for (final v in [true, false]) {
        await pumpRoll(
          tester,
          const Text('abc').roll(renderMode: kLegacyRenderMode, staggerTapes: v).animate(trigger: 0),
        );
        expect(tester.takeException(), isNull, reason: 'failed for staggerTapes=$v');
      }
    });

    testWidgets('staggerSoftness covers default and larger values',
        (tester) async {
      for (final v in [1, 10, 50]) {
        await pumpRoll(
          tester,
          const Text('abc').roll(renderMode: kLegacyRenderMode, staggerSoftness: v).animate(trigger: 0),
        );
        expect(tester.takeException(), isNull, reason: 'failed for staggerSoftness=$v');
      }
    });

    testWidgets('clipBehavior none/hardEdge/antiAlias', (tester) async {
      for (final c in [Clip.none, Clip.hardEdge, Clip.antiAlias]) {
        await pumpRoll(
          tester,
          const Text('abc').roll(renderMode: kLegacyRenderMode, clipBehavior: c).animate(trigger: 0),
        );
        expect(tester.takeException(), isNull, reason: 'failed for clipBehavior=$c');
      }
    });

    testWidgets('symbolDistanceMultiplier >= 1 accepted', (tester) async {
      // KNOWN BUG (lib/src/effects/roll/text_extensions.dart:91-94):
      // the package asserts `symbolDistanceMultiplier > 0`, but line 129
      // computes `leading: symbolDistanceMultiplier - 1` which Flutter's
      // StrutStyle asserts is >= 0. Values in (0, 1) therefore crash
      // Flutter at build time rather than the package at construction
      // time — an under-restrictive input validation.
      //
      // TODO(phase-N): once the package assertion is tightened to
      // `symbolDistanceMultiplier >= 1`, keep this accepted-sweep as
      // [1.0, 1.5, 2.0] AND add an assertion-error test for 0.5
      // alongside the existing `symbolDistanceMultiplier = 0 fails
      // assertion` test.
      for (final v in [1.0, 1.5, 2.0]) {
        await pumpRoll(
          tester,
          const Text('abc')
              .roll(
                renderMode: kLegacyRenderMode,
                symbolDistanceMultiplier: v,
              )
              .animate(trigger: 0),
        );
        expect(tester.takeException(), isNull, reason: 'failed for symbolDistanceMultiplier=$v');
      }
    });

    testWidgets('fixedTapeWidth set', (tester) async {
      await pumpRoll(
        tester,
        const Text('abc')
            .roll(
              renderMode: kLegacyRenderMode,
              fixedTapeWidth: 40.0,
            )
            .animate(trigger: 0),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('widthDuration and widthCurve', (tester) async {
      await pumpRoll(
        tester,
        const Text('abc')
            .roll(
              renderMode: kLegacyRenderMode,
              widthDuration: const Duration(milliseconds: 500),
              widthCurve: Curves.easeInOut,
            )
            .animate(trigger: 0),
      );
      expect(tester.takeException(), isNull);
    });

    test('symbolDistanceMultiplier = 0 fails assertion', () {
      expect(
        () => const Text('abc').roll(renderMode: kLegacyRenderMode, symbolDistanceMultiplier: 0),
        throwsAssertionError,
      );
    });

    test('staggerSoftness = 0 fails assertion', () {
      expect(
        () => const Text('abc').roll(renderMode: kLegacyRenderMode, staggerSoftness: 0),
        throwsAssertionError,
      );
    });
  });
}
