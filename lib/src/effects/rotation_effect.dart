import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../effect_builder.dart';
import 'effect.dart';

extension RotationEffectExt on Widget {
  Widget rotate(
    double angle, {
    Offset origin = Offset.zero,
    AlignmentGeometry alignment = Alignment.center,
  }) {
    return AnimatableEffect(
      effect: RotationEffect(
        angle: angle,
        origin: origin,
        alignment: alignment,
      ),
      child: this,
    );
  }
}

class RotationEffect extends Effect {
  final double angle;
  final Offset origin;
  final AlignmentGeometry alignment;

  const RotationEffect({
    this.angle = 0,
    this.origin = Offset.zero,
    this.alignment = Alignment.center,
  });

  @override
  Widget apply(BuildContext context, Widget child) {
    return Transform.rotate(
      angle: angle,
      alignment: alignment,
      origin: origin,
      child: child,
    );
  }

  @override
  RotationEffect lerp(covariant RotationEffect other, double value) {
    return RotationEffect(
      angle: lerpDouble(angle, other.angle, value) ?? 0,
      origin: Offset.lerp(origin, other.origin, value) ?? Offset.zero,
      alignment: AlignmentGeometry.lerp(alignment, other.alignment, value) ??
          Alignment.center,
    );
  }
}
