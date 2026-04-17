import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('smoke: diverse rolling scenarios pump without exceptions',
      (tester) async {
    int counter = 0;
    String greeting = 'Hello';
    late StateSetter setterFn;

    await tester.pumpWidget(
      wrapInTestApp(
        StatefulBuilder(
          builder: (context, setState) {
            setterFn = setState;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(greeting)
                    .roll(
                      renderMode: kLegacyRenderMode,
                      tapeStrategy: const ConsistentSymbolTapeStrategy(2),
                      tapeSlideDirection: TextTapeSlideDirection.up,
                    )
                    .animate(
                      trigger: greeting,
                      duration: const Duration(milliseconds: 300),
                    ),
                Text('$counter')
                    .roll(
                      renderMode: kLegacyRenderMode,
                      tapeStrategy: const AllSymbolsTapeStrategy(
                          repeatCharacters: false),
                      symbolDistanceMultiplier: 2,
                    )
                    .animate(
                      trigger: counter,
                      duration: const Duration(milliseconds: 500),
                    ),
                const Text('Stable')
                    .roll(renderMode: kLegacyRenderMode, staggerTapes: false)
                    .animate(trigger: 0),
              ],
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Flip trigger a few times to exercise transitions.
    for (final g in ['World', 'Hola', 'Hello']) {
      setterFn(() => greeting = g);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
    }
    for (final c in [1, 9, 99, 100, 999]) {
      setterFn(() => counter = c);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
    }

    expect(tester.takeException(), isNull);
  });
}
