import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

void main() {
  testWidgets('a mid-flight trigger starts and completes a fresh pulse',
      (tester) async {
    Widget pulse(int trigger) => Directionality(
          textDirection: TextDirection.ltr,
          child: const SizedBox().scale(1.3, from: 1).animate(
                trigger: trigger,
                duration: const Duration(milliseconds: 200),
                repeat: 1,
                reverse: true,
              ),
        );

    await tester.pumpWidget(pulse(0));
    await tester.pumpWidget(pulse(1));
    await tester.pump(const Duration(milliseconds: 100));

    final state = tester.state<AnimatedEffectState>(
      find.byType(AnimatedEffect),
    );
    expect(state.controller.value, closeTo(0.5, 0.01));

    await tester.pumpWidget(pulse(2));
    expect(state.controller.value, 0);

    await tester.pump(const Duration(milliseconds: 100));
    expect(state.controller.value, closeTo(0.5, 0.01));

    await tester.pumpAndSettle();
    expect(state.controller.value, 0);
  });
}
