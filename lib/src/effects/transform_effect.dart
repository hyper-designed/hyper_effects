import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../hyper_effects.dart';

extension TransformEffectExt on Widget {
  Widget transform({
    double translateX = 0,
    double translateY = 0,
    double translateZ = 0,
    double rotateX = 0,
    double rotateY = 0,
    double rotateZ = 0,
    double scaleX = 1,
    double scaleY = 1,
    double scaleZ = 1,
    double depth = 0,
    AlignmentGeometry alignment = Alignment.center,
    Offset origin = Offset.zero,
  }) {
    return AnimatableEffect(
      effect: TransformEffect(
        translateX: translateX,
        translateY: translateY,
        translateZ: translateZ,
        rotateX: rotateX,
        rotateY: rotateY,
        rotateZ: rotateZ,
        scaleX: scaleX,
        scaleY: scaleY,
        scaleZ: scaleZ,
        depth: depth,
        alignment: alignment,
        origin: origin,
      ),
      child: this,
    );
  }
}

class TransformEffect extends Effect {
  final double translateX;
  final double translateY;
  final double translateZ;
  final double rotateX;
  final double rotateY;
  final double rotateZ;
  final double scaleX;
  final double scaleY;
  final double scaleZ;

  // 0.001 are good numbers for depth perception.
  final double depth;
  final AlignmentGeometry alignment;
  final Offset origin;

  TransformEffect({
    this.translateX = 0,
    this.translateY = 0,
    this.translateZ = 0,
    this.rotateX = 0,
    this.rotateY = 0,
    this.rotateZ = 0,
    this.scaleX = 1,
    this.scaleY = 1,
    this.scaleZ = 1,
    this.depth = 0,
    this.alignment = Alignment.center,
    this.origin = Offset.zero,
  });

  @override
  TransformEffect lerp(covariant TransformEffect other, double value) {
    return TransformEffect(
      translateX: lerpDouble(translateX, other.translateX, value) ?? 0.0,
      translateY: lerpDouble(translateY, other.translateY, value) ?? 0.0,
      translateZ: lerpDouble(translateZ, other.translateZ, value) ?? 0.0,
      rotateX: lerpDouble(rotateX, other.rotateX, value) ?? 0.0,
      rotateY: lerpDouble(rotateY, other.rotateY, value) ?? 0.0,
      rotateZ: lerpDouble(rotateZ, other.rotateZ, value) ?? 0.0,
      scaleX: lerpDouble(scaleX, other.scaleX, value) ?? 1.0,
      scaleY: lerpDouble(scaleY, other.scaleY, value) ?? 1.0,
      scaleZ: lerpDouble(scaleZ, other.scaleZ, value) ?? 1.0,
      depth: lerpDouble(depth, other.depth, value) ?? 0.0,
      alignment: AlignmentGeometry.lerp(alignment, other.alignment, value) ??
          Alignment.center,
      origin: Offset.lerp(origin, other.origin, value) ?? Offset.zero,
    );
  }

  @override
  Widget apply(BuildContext context, Widget child) {
    final matrix = Matrix4.identity();
    if (depth > 0) {
      matrix.setEntry(3, 2, depth);
    }
    matrix.rotateX(rotateX);
    matrix.rotateY(rotateY);
    matrix.rotateZ(rotateZ);
    matrix.translate(translateX, translateY, translateZ);
    matrix.scale(scaleX, scaleY, scaleZ);

    return Transform(
      transform: matrix,
      alignment: alignment,
      origin: origin,
      child: child,
    );
  }
}
