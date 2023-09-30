import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../effect_builder.dart';
import 'effect.dart';

extension ScaleEffectExt on Widget {
  Widget scale(
    double? scale, {
    AlignmentGeometry alignment = Alignment.center,
    Offset origin = Offset.zero,
  }) {
    return AnimatableEffect(
      effect: ScaleEffect(
        scale: scale,
        alignment: alignment,
        origin: origin,
      ),
      child: this,
    );
  }

  Widget scaleX(
    double? scaleX, {
    AlignmentGeometry alignment = Alignment.center,
    Offset origin = Offset.zero,
  }) {
    return AnimatableEffect(
      effect: ScaleEffect(
        scaleX: scaleX,
        alignment: alignment,
        origin: origin,
      ),
      child: this,
    );
  }

  Widget scaleY(
    double? scaleY, {
    AlignmentGeometry alignment = Alignment.center,
    Offset origin = Offset.zero,
  }) {
    return AnimatableEffect(
      effect: ScaleEffect(
        scaleY: scaleY,
        alignment: alignment,
        origin: origin,
      ),
      child: this,
    );
  }

  Widget scaleXY(
    double? scaleX,
    double? scaleY, {
    AlignmentGeometry alignment = Alignment.center,
    Offset origin = Offset.zero,
  }) {
    return AnimatableEffect(
      effect: ScaleEffect(
        scaleX: scaleX,
        scaleY: scaleY,
        alignment: alignment,
        origin: origin,
      ),
      child: this,
    );
  }
}

class ScaleEffect extends Effect {
  final double? scale;
  final double? scaleX;
  final double? scaleY;
  final AlignmentGeometry alignment;
  final Offset origin;

  ScaleEffect({
    this.scale,
    this.scaleX,
    this.scaleY,
    this.alignment = Alignment.center,
    this.origin = Offset.zero,
  }) : assert(scale != null || scaleX != null || scaleY != null,
            'At least one of scale, scaleX, or scaleY must be non-null');

  @override
  ScaleEffect lerp(covariant ScaleEffect other, double value) {
    final effect = ScaleEffect(
      scale:
          scale != null ? (lerpDouble(scale, other.scale, value) ?? 1) : null,
      scaleX:
          scale == null ? (lerpDouble(scaleX, other.scaleX, value) ?? 1) : null,
      scaleY:
          scale == null ? (lerpDouble(scaleY, other.scaleY, value) ?? 1) : null,
      alignment: AlignmentGeometry.lerp(alignment, other.alignment, value) ??
          Alignment.center,
      origin: Offset.lerp(origin, other.origin, value) ?? Offset.zero,
    );
    return effect;
  }

  @override
  Widget apply(BuildContext context, Widget child) {
    return Transform.scale(
      scale: scale,
      scaleX: scaleX,
      scaleY: scaleY,
      alignment: alignment,
      origin: origin,
      child: child,
    );
  }
}
