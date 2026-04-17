import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

import '../../helpers/test_app.dart';

void main() {
  group('RollingText tree structure (independentCharacters path)', () {
    testWidgets('renders at least one RepaintBoundary per character for 5-char text',
        (tester) async {
      await tester.pumpWidget(
        wrapInTestApp(
          const Text('hello').roll(renderMode: kLegacyRenderMode).animate(trigger: 0),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RepaintBoundary), findsAtLeastNWidgets(5));
    });

    testWidgets('applies ClipRect as outer clip', (tester) async {
      await tester.pumpWidget(
        wrapInTestApp(
          const Text('abc').roll(renderMode: kLegacyRenderMode).animate(trigger: 0),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ClipRect), findsWidgets);
    });

    testWidgets('applies Padding when padding != EdgeInsets.zero',
        (tester) async {
      await tester.pumpWidget(
        wrapInTestApp(
          const Text('abc')
              .roll(
                renderMode: kLegacyRenderMode,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              )
              .animate(trigger: 0),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('contains a Row with at least N children for N-char text',
        (tester) async {
      await tester.pumpWidget(
        wrapInTestApp(
          const Text('abcd').roll(renderMode: kLegacyRenderMode).animate(trigger: 0),
        ),
      );
      await tester.pumpAndSettle();
      final row = tester.widget<Row>(find.byType(Row).first);
      expect(row.children.length, greaterThanOrEqualTo(4));
    });
  });
}
