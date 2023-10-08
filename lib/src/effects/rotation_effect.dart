import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../effect_builder.dart';
import 'effect.dart';

/// Provides a extension method to apply a [RotationEffect] to a [Widget].
extension RotationEffectExt on Widget {
  /// Applies a [RotationEffect] to a [Widget].
  ///
  /// [alignment] is the alignment of the origin, relative to the size of
  /// the [Widget].
  ///
  /// [origin] is the origin of the rotation. This allows to translate the
  /// origin of the rotation to a different point.
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

/// An [Effect] that applies a rotation to a [Widget].
class RotationEffect extends Effect {
  /// The angle to rotate the [Widget] in radians. This directly maps to
  /// angle property in [Transform.rotate] constructor.
  final double angle;

  /// The origin of the rotation. This allows to translate the
  /// origin of the rotation to a different point.
  final Offset origin;

  /// The alignment of the rotation, relative to the size of the [Widget].
  final AlignmentGeometry alignment;

  /// Creates a [RotationEffect].
  const RotationEffect({
    this.angle = 0,
    this.origin = Offset.zero,
    this.alignment = Alignment.center,
  });

  @override
  RotationEffect lerp(covariant RotationEffect other, double value) {
    return RotationEffect(
      angle: lerpDouble(angle, other.angle, value) ?? 0,
      origin: Offset.lerp(origin, other.origin, value) ?? Offset.zero,
      alignment: AlignmentGeometry.lerp(alignment, other.alignment, value) ??
          Alignment.center,
    );
  }

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
  List<Object?> get props => [angle, origin, alignment];
}
