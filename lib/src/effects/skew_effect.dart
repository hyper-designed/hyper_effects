import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../effect_builder.dart';
import 'effect.dart';

/// Provides a extension method to apply a [SkewEffect] to a [Widget].
extension SkewEffectExt on Widget {
  /// Applies a [SkewEffect] to a [Widget] with the given [skew] on both axes.
  ///
  /// [alignment] is the alignment of the origin, relative to the size of
  /// the [Widget].
  ///
  /// [origin] is the origin of the skew. This allows to translate the origin
  /// of the skew to a different point.
  Widget skew(
    double? skew, {
    AlignmentGeometry alignment = Alignment.center,
    Offset origin = Offset.zero,
  }) {
    return AnimatableEffect(
      effect: SkewEffect(
        skew: skew,
        alignment: alignment,
        origin: origin,
      ),
      child: this,
    );
  }

  /// Applies a [SkewEffect] to a [Widget] only on the x-axis.
  ///
  /// [alignment] is the alignment of the origin, relative to the size of
  /// the [Widget].
  ///
  /// [origin] is the origin of the skew. This allows to translate the origin
  /// of the skew to a different point.
  Widget skewX(
    double? skewX, {
    AlignmentGeometry alignment = Alignment.center,
    Offset origin = Offset.zero,
  }) {
    return AnimatableEffect(
      effect: SkewEffect(
        skewX: skewX,
        alignment: alignment,
        origin: origin,
      ),
      child: this,
    );
  }

  /// Applies a [SkewEffect] to a [Widget] only on the y-axis.
  ///
  /// [alignment] is the alignment of the origin, relative to the size of
  /// the [Widget].
  ///
  /// [origin] is the origin of the skew. This allows to translate the origin
  /// of the skew to a different point.
  Widget skewY(
    double? skewY, {
    AlignmentGeometry alignment = Alignment.center,
    Offset origin = Offset.zero,
  }) {
    return AnimatableEffect(
      effect: SkewEffect(
        skewY: skewY,
        alignment: alignment,
        origin: origin,
      ),
      child: this,
    );
  }

  /// Applies a [SkewEffect] to a [Widget] with the given [skewX] and [skewY].
  ///
  /// [alignment] is the alignment of the origin, relative to the size of
  /// the [Widget].
  ///
  /// [origin] is the origin of the skew. This allows to translate the origin
  /// of the skew to a different point.
  Widget skewXY(
    double? skewX,
    double? skewY, {
    AlignmentGeometry alignment = Alignment.center,
    Offset origin = Offset.zero,
  }) {
    return AnimatableEffect(
      effect: SkewEffect(
        skewX: skewX,
        skewY: skewY,
        alignment: alignment,
        origin: origin,
      ),
      child: this,
    );
  }
}

/// An [Effect] that applies a skew to a [Widget].
class SkewEffect extends Effect {
  /// The amount to skew the [Widget] in both the x and y directions. This
  /// must be null if [skewX] and [skewY] are provided.
  final double? skew;

  /// The amount to skew the [Widget] in the x direction. This must be null if
  /// [skew] is provided.
  final double? skewX;

  /// The amount to skew the [Widget] in the y direction. This must be null if
  /// [skew] is provided.
  final double? skewY;

  /// The alignment of the skew, relative to the size of the [Widget].
  /// Directly mapped to the [Transform] widget.
  final AlignmentGeometry alignment;

  /// The origin of the skew. This allows to translate the origin of the skew
  /// to a different point. Directly mapped to the [Transform] widget.
  final Offset origin;

  /// Creates a [SkewEffect].
  SkewEffect({
    this.skew,
    this.skewX,
    this.skewY,
    this.alignment = Alignment.center,
    this.origin = Offset.zero,
  }) : assert(skew != null || skewX != null || skewY != null,
            'At least one of skew, skewX, or skewY must be non-null');

  @override
  SkewEffect lerp(covariant SkewEffect other, double value) => SkewEffect(
        skew:
            skew != null ? (lerpDouble(skew, other.skew, value) ?? 0.0) : null,
        skewX: skew == null
            ? (lerpDouble(skewX, other.skewX, value) ?? 0.0)
            : null,
        skewY: skew == null
            ? (lerpDouble(skewY, other.skewY, value) ?? 0.0)
            : null,
        alignment: AlignmentGeometry.lerp(alignment, other.alignment, value) ??
            Alignment.center,
        origin: Offset.lerp(origin, other.origin, value) ?? Offset.zero,
      );

  @override
  Widget apply(BuildContext context, Widget child) {
    return Transform(
      transform: Matrix4.skew(
        skewX ?? skew ?? 0,
        skewY ?? skew ?? 0,
      ),
      alignment: alignment,
      origin: origin,
      child: child,
    );
  }

  @override
  List<Object?> get props => [skew, skewX, skewY, alignment, origin];
}
