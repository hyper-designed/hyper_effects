import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets(
    'roll translations preserve FractionalTranslation hit-test defaults',
    (tester) async {
      Widget host({required Key childKey, required int trigger}) => MaterialApp(
            home: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 100,
                height: 100,
                child: SizedBox.square(dimension: 100, key: childKey)
                    .roll(
                      slideInDirection: AxisDirection.right,
                      slideOutDirection: AxisDirection.left,
                    )
                    .animate(
                      trigger: trigger,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.linear,
                    ),
              ),
            ),
          );

      await tester.pumpWidget(host(childKey: const Key('old'), trigger: 0));
      await tester.pump();
      await tester.pumpWidget(host(childKey: const Key('new'), trigger: 1));
      await tester.pump(const Duration(milliseconds: 150));

      final translations = tester
          .widgetList<FractionalTranslation>(
            find.descendant(
              of: find.byType(RollingEffectWidget),
              matching: find.byType(FractionalTranslation),
            ),
          )
          .toList();
      expect(translations, hasLength(2));
      expect(
        translations.every((translation) => translation.transformHitTests),
        isTrue,
        reason: 'RollEffect must not override Flutter’s true default',
      );
    },
  );
}
