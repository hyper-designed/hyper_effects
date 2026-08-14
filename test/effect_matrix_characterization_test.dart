import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

/// Pins the exact transformation matrices produced by [ShakeEffect] and
/// [TransformEffect] so that the deprecated Matrix4 call sites can be
/// migrated to their replacements without any behavioral change.
void main() {
  void expectMatrix(Matrix4 actual, Matrix4 expected) {
    for (var i = 0; i < 16; i++) {
      expect(actual.storage[i], closeTo(expected.storage[i], 1e-9),
          reason: 'matrix storage[$i]');
    }
  }

  testWidgets('ShakeEffect composes rotation then translation', (tester) async {
    // curvedValue 1/16 with duration 500ms and frequency 8 makes
    // sin(value * count * 2pi) == sin(pi / 2) == 1.0, so the matrix is
    // exactly rotateZ(rotation) * translate(offset).
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: EffectQuery(
          linearValue: 1 / 16,
          curvedValue: 1 / 16,
          isTransition: false,
          duration: const Duration(milliseconds: 500),
          child: const SizedBox.square(dimension: 10)
              .shake(frequency: 8, offset: const Offset(10, 0), rotation: 0.2),
        ),
      ),
    );

    final transform = tester.widget<Transform>(find.byType(Transform));
    final expected =
        Matrix4.rotationZ(0.2).multiplied(Matrix4.translationValues(10, 0, 0));
    expectMatrix(transform.transform, expected);
  });

  testWidgets('TransformEffect composes rotations, translation, then scale',
      (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: const SizedBox.square(dimension: 10).transform(
          rotateX: 0.1,
          rotateY: 0.2,
          rotateZ: 0.3,
          translateX: 10,
          translateY: 20,
          translateZ: 5,
          scaleX: 2,
          scaleY: 3,
          scaleZ: 4,
        ),
      ),
    );

    final transform = tester.widget<Transform>(find.byType(Transform));
    final expected = Matrix4.identity()
      ..rotateX(0.1)
      ..rotateY(0.2)
      ..rotateZ(0.3);
    expected.multiply(Matrix4.translationValues(10, 20, 5));
    expected.multiply(Matrix4.diagonal3Values(2, 3, 4));
    expectMatrix(transform.transform, expected);
  });
}
