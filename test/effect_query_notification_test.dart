import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

class _LinearValueText extends StatelessWidget {
  const _LinearValueText();

  @override
  Widget build(BuildContext context) => Text(
        EffectQuery.of(context).linearValue.toStringAsFixed(1),
      );
}

void main() {
  testWidgets('linear progress notifies when curved progress is equal',
      (tester) async {
    var linearValue = 0.2;

    Widget host() => Directionality(
          textDirection: TextDirection.ltr,
          child: EffectQuery(
            linearValue: linearValue,
            curvedValue: 0.5,
            isTransition: false,
            child: const _LinearValueText(),
          ),
        );

    await tester.pumpWidget(host());
    expect(find.text('0.2'), findsOneWidget);

    linearValue = 0.4;
    await tester.pumpWidget(host());

    expect(find.text('0.4'), findsOneWidget);
  });
}
