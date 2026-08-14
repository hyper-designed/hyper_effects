import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

void main() {
  testWidgets(
    'a non-interruptable animation plays after resetAll cancels it mid-flight',
    (tester) async {
      final resetKey = GlobalKey<ResetAllAnimationsEffectState>();
      late StateSetter rebuild;
      var trigger = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return ResetAllAnimationsEffect(
                key: resetKey,
                child: const Text('effect').fadeIn().animate(
                      trigger: trigger,
                      duration: const Duration(seconds: 1),
                      interruptable: false,
                    ),
              );
            },
          ),
        ),
      );

      rebuild(() => trigger = 1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      resetKey.currentState!.reset();
      await tester.pump();

      rebuild(() => trigger = 2);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final state = tester.state<AnimatedEffectState>(
        find.byType(AnimatedEffect),
      );
      expect(state.controller.value, greaterThan(0));
    },
  );
}
