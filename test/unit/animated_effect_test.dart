import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

import '../helpers/test_app.dart';

void main() {
  group('AnimatedEffect', () {
    testWidgets('builds without error with default params', (tester) async {
      await tester.pumpWidget(
        wrapInTestApp(
          const Text('hi').roll().animate(trigger: 0),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(EffectWidget), findsWidgets);
    });

    testWidgets('changing trigger advances animation', (tester) async {
      int trigger = 0;
      late StateSetter setTriggerFn;

      await tester.pumpWidget(
        wrapInTestApp(
          StatefulBuilder(
            builder: (context, setState) {
              setTriggerFn = setState;
              return const Text('abc').roll().animate(
                    trigger: trigger,
                    duration: const Duration(milliseconds: 200),
                  );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      setTriggerFn(() => trigger = 1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.hasScheduledFrame, isTrue);
      await tester.pumpAndSettle();
    });

    testWidgets('onEnd fires once on completion with playImmediately', (tester) async {
      // onEnd is the correct param name (confirmed in animated_effect.dart:77)
      //
      // NOTE: animate(trigger: ...) with the default startState=idle does NOT
      // auto-play on first build; onEnd never fires unless the trigger changes.
      // To auto-play on first build, startState: AnimationStartState.playImmediately
      // must be used — that is what this test exercises.
      int endCount = 0;

      await tester.pumpWidget(
        wrapInTestApp(
          const Text('abc').roll().animate(
                trigger: 1,
                duration: const Duration(milliseconds: 100),
                startState: AnimationStartState.playImmediately,
                onEnd: () => endCount += 1,
              ),
        ),
      );
      await tester.pumpAndSettle();
      expect(endCount, 1);
    });

    testWidgets('onEnd fires once when trigger changes from idle', (tester) async {
      int endCount = 0;
      int trigger = 0;
      late StateSetter setTrigger;

      await tester.pumpWidget(
        wrapInTestApp(
          StatefulBuilder(
            builder: (context, setState) {
              setTrigger = setState;
              return const Text('abc').roll().animate(
                    trigger: trigger,
                    duration: const Duration(milliseconds: 100),
                    onEnd: () => endCount += 1,
                  );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(endCount, 0, reason: 'idle state should not fire onEnd');

      setTrigger(() => trigger = 1);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(endCount, 1, reason: 'trigger change completes animation exactly once');
    });
  });
}
