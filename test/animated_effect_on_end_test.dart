import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

void main() {
  testWidgets('onEnd fires once after a repeated reverse animation finishes',
      (tester) async {
    var onEndCalls = 0;
    var trigger = 0;

    Widget buildSubject() => Directionality(
          textDirection: TextDirection.ltr,
          child: const SizedBox.shrink().scale(0.5).animate(
                trigger: trigger,
                duration: const Duration(milliseconds: 10),
                repeat: 1,
                reverse: true,
                onEnd: () => onEndCalls++,
              ),
        );

    await tester.pumpWidget(buildSubject());

    trigger = 1;
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(onEndCalls, 1);
  });
}
