import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_effects/hyper_effects.dart';

/// Contract for the hand-written ==/hashCode/toString overrides that
/// replaced Equatable: value equality over every declared field, hashCode
/// consistency, and a toString that names the type.
void expectValueSemantics<T extends Object>(T a, T sameAsA, T different) {
  expect(a, equals(sameAsA), reason: '$T: equal fields must compare equal');
  expect(a.hashCode, sameAsA.hashCode,
      reason: '$T: equal instances must share a hashCode');
  expect(a, isNot(equals(different)),
      reason: '$T: a differing field must break equality');
  expect(a.toString(), contains('$T'),
      reason: '$T: toString should name the type');
}

void main() {
  test('ScaleEffect', () {
    expectValueSemantics(
      ScaleEffect(scale: 1.5, alignment: Alignment.topLeft),
      ScaleEffect(scale: 1.5, alignment: Alignment.topLeft),
      ScaleEffect(scale: 2.0, alignment: Alignment.topLeft),
    );
    // Axis-split vs uniform scale must not compare equal.
    expect(ScaleEffect(scaleX: 1, scaleY: 1), isNot(ScaleEffect(scale: 1)));
  });

  test('RotationEffect', () {
    expectValueSemantics(
      const RotationEffect(angle: 0.5),
      const RotationEffect(angle: 0.5),
      const RotationEffect(angle: 0.6),
    );
  });

  test('OpacityEffect', () {
    expectValueSemantics(
      OpacityEffect(opacity: 0.5),
      OpacityEffect(opacity: 0.5),
      OpacityEffect(opacity: 1),
    );
  });

  test('TranslateEffect', () {
    expectValueSemantics(
      TranslateEffect(offset: const Offset(1, 2)),
      TranslateEffect(offset: const Offset(1, 2)),
      TranslateEffect(offset: const Offset(1, 2), fractional: true),
    );
  });

  test('AlignEffect', () {
    expectValueSemantics(
      AlignEffect(alignment: Alignment.center, widthFactor: 1),
      AlignEffect(alignment: Alignment.center, widthFactor: 1),
      AlignEffect(alignment: Alignment.topRight, widthFactor: 1),
    );
  });

  test('BlurEffect', () {
    expectValueSemantics(
      BlurEffect(blur: 4),
      BlurEffect(blur: 4),
      BlurEffect(blur: 8),
    );
  });

  test('ClipEffect', () {
    expectValueSemantics(
      ClipEffect(clip: Clip.antiAlias, borderRadius: BorderRadius.circular(4)),
      ClipEffect(clip: Clip.antiAlias, borderRadius: BorderRadius.circular(4)),
      ClipEffect(clip: Clip.antiAlias, borderRadius: BorderRadius.circular(8)),
    );
  });

  test('PaddingEffect', () {
    expectValueSemantics(
      PaddingEffect(padding: const EdgeInsets.all(8)),
      PaddingEffect(padding: const EdgeInsets.all(8)),
      PaddingEffect(padding: const EdgeInsets.all(16)),
    );
  });

  test('SkewEffect', () {
    expectValueSemantics(
      const SkewEffect(skew: 0.2),
      const SkewEffect(skew: 0.2),
      const SkewEffect(skew: 0.4),
    );
  });

  test('ShakeEffect', () {
    expectValueSemantics(
      const ShakeEffect(frequency: 4),
      const ShakeEffect(frequency: 4),
      const ShakeEffect(frequency: 8),
    );
  });

  test('TransformEffect', () {
    expectValueSemantics(
      TransformEffect(translateX: 10, rotateZ: 0.3, scaleX: 2),
      TransformEffect(translateX: 10, rotateZ: 0.3, scaleX: 2),
      TransformEffect(translateX: 10, rotateZ: 0.3, scaleX: 3),
    );
  });

  test('ColorFilterEffect list field compares by contents', () {
    expectValueSemantics(
      ColorFilterEffect(matrix: const [1, 0, 0, 0, 0], mode: BlendMode.color),
      // A DIFFERENT list instance with the same contents must be equal.
      ColorFilterEffect(matrix: const [1.0, 0, 0, 0, 0], mode: BlendMode.color),
      ColorFilterEffect(matrix: const [0, 1, 0, 0, 0], mode: BlendMode.color),
    );
  });

  test('TimelineSegment', () {
    expectValueSemantics(
      const TimelineSegment(
        motion: CurvedMotion(Duration(milliseconds: 300), Curves.easeOut),
        delay: Duration.zero,
      ),
      const TimelineSegment(
        motion: CurvedMotion(Duration(milliseconds: 300), Curves.easeOut),
        delay: Duration.zero,
      ),
      const TimelineSegment(
        motion: CurvedMotion(Duration(milliseconds: 400), Curves.easeOut),
        delay: Duration.zero,
      ),
    );
  });
}
