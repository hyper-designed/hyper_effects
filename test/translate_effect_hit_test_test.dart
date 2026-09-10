import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets(
    'translate() moves hit testing with paint by default, matching Flutter',
    (tester) async {
      var taps = 0;
      const key = Key('button');

      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
              key: key,
              behavior: HitTestBehavior.opaque,
              onTap: () => taps++,
              child: const SizedBox.square(dimension: 48),
            ).translateX(160),
          ),
        ),
      );

      final paintedCentre = tester.getCenter(find.byKey(key));
      expect(paintedCentre.dx, closeTo(184, 0.01));

      await tester.tapAt(paintedCentre);
      await tester.pump();

      expect(
        taps,
        1,
        reason: 'Transform.translate defaults transformHitTests to true; '
            'the effect wrapper must preserve that contract',
      );
    },
  );

  testWidgets('translate() still allows paint-only movement explicitly', (
    tester,
  ) async {
    var taps = 0;
    const key = Key('paint-only-button');

    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: GestureDetector(
            key: key,
            behavior: HitTestBehavior.opaque,
            onTap: () => taps++,
            child: const SizedBox.square(dimension: 48),
          ).translateX(160, transformHitTests: false),
        ),
      ),
    );

    await tester.tapAt(tester.getCenter(find.byKey(key)));
    await tester.pump();
    expect(taps, 0);

    await tester.tapAt(const Offset(24, 24));
    await tester.pump();
    expect(taps, 1);
  });
}
