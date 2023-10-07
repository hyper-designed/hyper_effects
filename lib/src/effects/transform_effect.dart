import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../hyper_effects.dart';

/// Provides a extension method to apply a [TransformEffect] to a [Widget].
extension TransformEffectExt on Widget {

  /// Applies a [TransformEffect] to a [Widget].
  ///
  /// The [translateX], [translateY], [translateZ], [rotateX], [rotateY],
  /// [rotateZ], [scaleX], [scaleY], [scaleZ], [depth], [alignment], and
  /// [origin] arguments are directly mapped to the [Transform] widget.
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

/// An [Effect] that applies a transform to a [Widget].
class TransformEffect extends Effect {

  /// The amount to translate the [Widget] in the x direction. Directly mapped
  /// to the [Transform] widget.
  final double translateX;

  /// The amount to translate the [Widget] in the y direction. Directly mapped
  /// to the [Transform] widget.
  final double translateY;

  /// The amount to translate the [Widget] in the z direction. Directly mapped
  /// to the [Transform] widget.
  final double translateZ;

  /// The amount to rotate the [Widget] around the x axis. Directly mapped
  /// to the [Transform] widget.
  final double rotateX;

  /// The amount to rotate the [Widget] around the y axis. Directly mapped
  /// to the [Transform] widget.
  final double rotateY;

  /// The amount to rotate the [Widget] around the z axis. Directly mapped
  /// to the [Transform] widget.
  final double rotateZ;

  /// The amount to scale the [Widget] in the x direction. Directly mapped
  /// to the [Transform] widget.
  final double scaleX;

  /// The amount to scale the [Widget] in the y direction. Directly mapped
  /// to the [Transform] widget.
  final double scaleY;

  /// The amount to scale the [Widget] in the z direction. Directly mapped
  /// to the [Transform] widget.
  final double scaleZ;

  /// Defines the depth of the [Widget] in z direction. This is used to create
  /// a 3D effect. This is used on the transform matrix to set the entry at
  /// given depth.
  /// Tip: 0.001 are good numbers for depth perception.
  final double depth;

  /// The alignment of the [Widget] within its parent. Directly mapped
  /// to the [Transform] widget.
  final AlignmentGeometry alignment;

  /// The origin of the [Widget] relative to its size. Directly mapped
  /// to the [Transform] widget.
  final Offset origin;

  /// Creates a [TransformEffect].
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
