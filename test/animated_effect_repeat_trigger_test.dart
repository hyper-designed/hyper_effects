import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

void main() {
  testWidgets('reverses every repeated trigger animation back to its start',
      (tester) async {
    final key = GlobalKey<_TriggerHarnessState>();

    await tester.pumpWidget(_TriggerHarness(key: key));

    key.currentState!.trigger();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(_scaleOf(tester), 1);

    key.currentState!.trigger();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(_scaleOf(tester), 1);
  });
}

double _scaleOf(WidgetTester tester) {
  final transform = tester.widget<Transform>(find.byType(Transform));
  return transform.transform.storage[0];
}

class _TriggerHarness extends StatefulWidget {
  const _TriggerHarness({super.key});

  @override
  State<_TriggerHarness> createState() => _TriggerHarnessState();
}

class _TriggerHarnessState extends State<_TriggerHarness> {
  int triggerValue = 0;

  void trigger() {
    setState(() => triggerValue++);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: const SizedBox().scale(1.3, from: 1).animate(
            trigger: triggerValue,
            duration: const Duration(milliseconds: 200),
            curve: Curves.linear,
            repeat: 1,
            reverse: true,
          ),
    );
  }
}
