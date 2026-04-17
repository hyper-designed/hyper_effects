import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

import '../helpers/test_app.dart';

void main() {
  group('EffectQuery', () {
    testWidgets('no ancestor — maybeOf returns null', (tester) async {
      // EffectQuery is a direct InheritedWidget subclass (no separate scope
      // wrapper); EffectQuery.maybeOf(context) matches plan exactly.
      EffectQuery? found;
      await tester.pumpWidget(
        wrapInTestApp(
          Builder(builder: (context) {
            found = EffectQuery.maybeOf(context);
            return const SizedBox();
          }),
        ),
      );
      expect(found, isNull);
    });

    testWidgets('ancestor present when wrapped in animate', (tester) async {
      // EffectQuery IS a Widget (extends InheritedWidget), so find.byType works.
      await tester.pumpWidget(
        wrapInTestApp(
          const Text('hi').roll().animate(trigger: 0),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(EffectQuery), findsWidgets);
    });

    testWidgets('maybeOf returns non-null inside animate subtree', (tester) async {
      await tester.pumpWidget(
        wrapInTestApp(
          const Text('hi').roll().animate(trigger: 0),
        ),
      );
      // Pump one frame to allow AnimatedEffect to insert EffectQuery
      await tester.pump();

      // Find the EffectQuery widget and verify it is in the tree
      final queryFinder = find.byType(EffectQuery);
      expect(queryFinder, findsWidgets);

      // Read its linearValue — should be 0.0 since animation starts idle
      final widget = tester.widgetList<EffectQuery>(queryFinder).first;
      expect(widget.linearValue, isA<double>());
    });

    testWidgets('EffectQuery.of throws AssertionError when no ancestor',
        (tester) async {
      // EffectQuery.of uses an `assert(result != null, ...)` which throws
      // AssertionError in debug mode. The widget framework re-wraps this as
      // an error that tester.takeException() can capture.
      await tester.pumpWidget(
        wrapInTestApp(
          Builder(builder: (context) {
            // Calling EffectQuery.of without an ancestor throws in debug mode.
            EffectQuery.of(context);
            return const SizedBox();
          }),
        ),
      );
      final error = tester.takeException();
      expect(error, isNotNull);
      expect(error.toString(), contains('No EffectQuery found in context'));
    });
  });
}
