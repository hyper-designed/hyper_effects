import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

void main() {
  group('AlignEffect layout semantics', () {
    testWidgets(
        'align() expands to fill loose constraints like a plain Align',
        (tester) async {
      const childKey = Key('child');
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
              child: const SizedBox(key: childKey, width: 50, height: 50)
                  .align(Alignment.bottomRight),
            ),
          ),
        ),
      );

      // A plain Align with null factors fills the loose 200x200 constraints.
      expect(tester.getSize(find.byType(Align)), const Size(200, 200));

      // The 200x200 box is centered in the 800x600 test surface at (300, 200);
      // a bottom-right aligned 50x50 child sits at (450, 350).
      expect(tester.getTopLeft(find.byKey(childKey)), const Offset(450, 350));
    });

    testWidgets('alignX() expands to fill loose constraints', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
              child: const SizedBox(width: 50, height: 50).alignX(1),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(Align)), const Size(200, 200));
    });

    testWidgets('align() passes explicit factors through to Align',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: const SizedBox(width: 50, height: 50).align(
              Alignment.center,
              widthFactor: 2,
              heightFactor: 3,
            ),
          ),
        ),
      );

      final Align align = tester.widget(find.byType(Align));
      expect(align.widthFactor, 2);
      expect(align.heightFactor, 3);
      expect(tester.getSize(find.byType(Align)), const Size(100, 150));
    });
  });

  group('AlignEffect factor lerp', () {
    test('both factors null stays null', () {
      final result = AlignEffect(alignment: Alignment.topLeft)
          .lerp(AlignEffect(alignment: Alignment.bottomRight), 0.5);
      expect(result.widthFactor, isNull);
      expect(result.heightFactor, isNull);
    });

    test('both factors non-null interpolate', () {
      final result = AlignEffect(widthFactor: 1, heightFactor: 1)
          .lerp(AlignEffect(widthFactor: 3, heightFactor: 5), 0.5);
      expect(result.widthFactor, 2);
      expect(result.heightFactor, 3);
    });

    test('mixed null and non-null snaps to the target value', () {
      final nullToValue =
          AlignEffect().lerp(AlignEffect(widthFactor: 2), 0.5);
      expect(nullToValue.widthFactor, 2);

      final valueToNull =
          AlignEffect(widthFactor: 2).lerp(AlignEffect(), 0.5);
      expect(valueToNull.widthFactor, isNull);
    });

    test('interpolated factors are clamped at zero', () {
      final result = AlignEffect(widthFactor: 0)
          .lerp(AlignEffect(widthFactor: -4), 0.5);
      expect(result.widthFactor, 0);
    });

    test('idle() has null factors', () {
      final idle = AlignEffect(widthFactor: 2, heightFactor: 2).idle();
      expect(idle.widthFactor, isNull);
      expect(idle.heightFactor, isNull);
    });
  });
}
