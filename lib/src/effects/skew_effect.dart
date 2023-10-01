import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../effect_builder.dart';
import 'effect.dart';

extension SkewEffectExt on Widget {
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

class SkewEffect extends Effect {
  final double? skew;
  final double? skewX;
  final double? skewY;
  final AlignmentGeometry alignment;
  final Offset origin;

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
}
