import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

import '../helpers/test_app.dart';

void main() {
  group('EffectWidget', () {
    testWidgets('renders without error with any Effect', (tester) async {
      // OpacityEffect has no const constructor, so const is omitted here.
      await tester.pumpWidget(
        wrapInTestApp(
          EffectWidget(
            start: OpacityEffect(opacity: 0),
            end: OpacityEffect(opacity: 1),
            child: const Text('content'),
          ),
        ),
      );
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('participates in the effect chain', (tester) async {
      // .blurred() does not exist; the actual method is .blur(double).
      // .scale() takes a double (not Size), so we pass 2.0.
      await tester.pumpWidget(
        wrapInTestApp(
          const Text('chain')
              .blur(10)
              .scale(2.0)
              .animate(trigger: 0),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(EffectWidget), findsWidgets);
    });
  });
}
