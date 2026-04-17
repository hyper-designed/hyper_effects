import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';
import 'package:hyper_effects/src/text/shaped_text.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_font_loader.dart';

void main() {
  setUp(() async {
    await loadTestFonts();
    ShapedText.debugClearCache();
  });

  group('Text.blurReveal() extension', () {
    testWidgets('builds without error using all defaults', (tester) async {
      await tester.pumpWidget(
        wrapInTestApp(
          const Text('Hello').blurReveal().animate(trigger: 0),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(EffectWidget), findsWidgets);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('accepts every parameter without crashing', (tester) async {
      await tester.pumpWidget(
        wrapInTestApp(
          const Text('Hello')
              .blurReveal(
                delay: const Duration(milliseconds: 100),
                speedReveal: 2.0,
                speedSegment: 0.75,
                blurSigma: 6.0,
                riseFrom: const Offset(0, 20),
                curve: Curves.easeInOut,
                maxWidth: 200,
              )
              .animate(trigger: 0),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty text renders without crashing', (tester) async {
      await tester.pumpWidget(
        wrapInTestApp(
          const Text('').blurReveal().animate(trigger: 0),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('arabic text renders without crashing', (tester) async {
      await tester.pumpWidget(
        wrapInTestApp(
          const Text('مرحبا').blurReveal().animate(trigger: 0),
          defaultStyle: const TextStyle(
            fontFamily: 'TestArabic',
            fontSize: 32,
          ),
          textDirection: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('intrinsic sizing returns the shaped-text size',
        (tester) async {
      await tester.pumpWidget(
        wrapInTestApp(
          IntrinsicWidth(
            child: IntrinsicHeight(
              child: const Text('Hello').blurReveal().animate(trigger: 0),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final size = tester.getSize(find.byType(EffectWidget).first);
      expect(size.width, greaterThan(0));
      expect(size.height, greaterThan(0));
    });

    testWidgets('trigger change advances animation', (tester) async {
      int trigger = 0;
      late StateSetter setTriggerFn;

      await tester.pumpWidget(
        wrapInTestApp(
          StatefulBuilder(
            builder: (context, setState) {
              setTriggerFn = setState;
              return const Text('Hello').blurReveal().animate(
                    trigger: trigger,
                    duration: const Duration(milliseconds: 200),
                    startState: AnimationStartState.playImmediately,
                  );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      setTriggerFn(() => trigger = 1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
