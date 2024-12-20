import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../effect_widget.dart';
import 'effect.dart';

/// Provides a extension method to apply a [ScaleEffect] to a [Widget].
extension ScaleEffectExt on Widget {
  /// Applies a [ScaleEffect] to a [Widget] with the given [scale] on both axes.
  ///
  /// [alignment] is the alignment of the origin, relative to the size of
  /// the box.
  ///
  /// [origin] is the origin of the scale. This allows to translate the origin
  /// of the scale to a different point.
  Widget scale(
    double scale, {
    AlignmentGeometry alignment = Alignment.center,
    Offset origin = Offset.zero,
    double? from,
    bool transformHitTests = true,
  }) {
    return EffectWidget(
      start: from == null
          ? null
          : ScaleEffect(
              scale: from,
              transformHitTests: transformHitTests,
            ),
      end: ScaleEffect(
        scale: scale,
        alignment: alignment,
        origin: origin,
        transformHitTests: transformHitTests,
      ),
      child: this,
    );
  }

  /// Applies a [ScaleEffect] to a [Widget] only on the x-axis.
  ///
  /// [alignment] is the alignment of the origin, relative to the size of
  /// the box.
  ///
  /// [origin] is the origin of the scale. This allows to translate the origin
  /// of the scale to a different point.
  Widget scaleX(
    double scaleX, {
    AlignmentGeometry alignment = Alignment.center,
    Offset origin = Offset.zero,
    double? from,
    bool transformHitTests = true,
  }) {
    return EffectWidget(
      start: from == null
          ? null
          : ScaleEffect(
              scaleX: from,
              transformHitTests: transformHitTests,
            ),
      end: ScaleEffect(
        scaleX: scaleX,
        alignment: alignment,
        origin: origin,
        transformHitTests: transformHitTests,
      ),
      child: this,
    );
  }

  /// Applies a [ScaleEffect] to a [Widget] only on the y-axis.
  ///
  /// [alignment] is the alignment of the origin, relative to the size of
  /// the box.
  ///
  /// [origin] is the origin of the scale. This allows to translate the origin
  /// of the scale to a different point.
  Widget scaleY(
    double scaleY, {
    AlignmentGeometry alignment = Alignment.center,
    Offset origin = Offset.zero,
    double? from,
    bool transformHitTests = true,
  }) {
    return EffectWidget(
      start: from == null
          ? null
          : ScaleEffect(
              scaleY: from,
              transformHitTests: transformHitTests,
            ),
      end: ScaleEffect(
        scaleY: scaleY,
        alignment: alignment,
        origin: origin,
        transformHitTests: transformHitTests,
      ),
      child: this,
    );
  }

  /// Applies a [ScaleEffect] to a [Widget] with the given [scaleX]
  /// and [scaleY].
  ///
  /// [alignment] is the alignment of the origin, relative to the size of
  /// the box.
  ///
  /// [origin] is the origin of the scale. This allows to translate the origin
  /// of the scale to a different point.
  Widget scaleXY(
    double scaleX,
    double scaleY, {
    AlignmentGeometry alignment = Alignment.center,
    Offset origin = Offset.zero,
    Offset? from,
    bool transformHitTests = true,
  }) {
    return EffectWidget(
      start: from == null
          ? null
          : ScaleEffect(
              scaleX: from.dx,
              scaleY: from.dy,
              transformHitTests: transformHitTests,
            ),
      end: ScaleEffect(
        scaleX: scaleX,
        scaleY: scaleY,
        alignment: alignment,
        origin: origin,
        transformHitTests: transformHitTests,
      ),
      child: this,
    );
  }

  /// Applies an [ScaleEffect] to a [Widget] with a default scale in
  /// animation.
  Widget scaleIn({
    double? start,
    double? end,
    AlignmentGeometry alignment = Alignment.center,
    Offset origin = Offset.zero,
    bool transformHitTests = true,
  }) {
    return EffectWidget(
      start: ScaleEffect(
        scale: start ?? 0,
        alignment: alignment,
        origin: origin,
        transformHitTests: transformHitTests,
      ),
      end: ScaleEffect(
        scale: end ?? 1,
        alignment: alignment,
        origin: origin,
        transformHitTests: transformHitTests,
      ),
      child: this,
    );
  }

  /// Applies an [ScaleEffect] to a [Widget] with a default scale out
  /// animation.
  Widget scaleOut({
    double? start,
    double? end,
    AlignmentGeometry alignment = Alignment.center,
    Offset origin = Offset.zero,
    bool transformHitTests = true,
  }) {
    return EffectWidget(
      start: ScaleEffect(
        scale: start ?? 1,
        alignment: alignment,
        origin: origin,
        transformHitTests: transformHitTests,
      ),
      end: ScaleEffect(
        scale: end ?? 0,
        alignment: alignment,
        origin: origin,
        transformHitTests: transformHitTests,
      ),
      child: this,
    );
  }
}

/// An [Effect] that applies a scale to a [Widget].
class ScaleEffect extends Effect {
  /// The scale to apply to the [Widget] on both axes. This must be null if
  /// [scaleX] or [scaleY] is provided.
  final double? scale;

  /// The scale to apply to the [Widget] on the x-axis. This must be null if
  /// [scale] is provided.
  final double? scaleX;

  /// The scale to apply to the [Widget] on the y-axis. This must be null if
  /// [scale] is provided.
  final double? scaleY;

  /// The alignment of the origin, relative to the size of the [Widget].
  /// This directly maps to the [Transform.alignment] property.
  final AlignmentGeometry alignment;

  /// The origin of the scale. This allows to translate the origin of the scale
  /// to a different point.
  /// (relative to the upper left corner of this render object)
  final Offset origin;

  /// Whether to apply the transformation when performing hit tests.
  final bool transformHitTests;

  /// Creates a [ScaleEffect].
  ScaleEffect({
    this.scale,
    this.scaleX,
    this.scaleY,
    this.alignment = Alignment.center,
    this.origin = Offset.zero,
    this.transformHitTests = true,
  }) : assert(scale != null || scaleX != null || scaleY != null,
            'At least one of scale, scaleX, or scaleY must be non-null');

  @override
  ScaleEffect lerp(covariant ScaleEffect other, double value) {
    final effectiveAlignment =
        AlignmentGeometry.lerp(alignment, other.alignment, value) ??
            Alignment.center;
    final effectiveOrigin =
        Offset.lerp(origin, other.origin, value) ?? Offset.zero;

    if (scale != null) {
      final effectiveScale = lerpDouble(scale, other.scale, value) ?? 1;
      return ScaleEffect(
        scale: effectiveScale,
        alignment: effectiveAlignment,
        origin: effectiveOrigin,
        transformHitTests:
            value < 0.5 ? transformHitTests : other.transformHitTests,
      );
    }

    final effectiveScaleX = lerpDouble(scaleX, other.scaleX, value) ?? 1;
    final effectiveScaleY = lerpDouble(scaleY, other.scaleY, value) ?? 1;
    return ScaleEffect(
      scaleX: effectiveScaleX,
      scaleY: effectiveScaleY,
      alignment: effectiveAlignment,
      origin: effectiveOrigin,
      transformHitTests:
          value < 0.5 ? transformHitTests : other.transformHitTests,
    );
  }

  @override
  Widget apply(BuildContext context, Widget? child) => Transform.scale(
        scale: scale,
        scaleX: scaleX,
        scaleY: scaleY,
        alignment: alignment,
        origin: origin,
        transformHitTests: transformHitTests,
        child: child,
      );

  @override
  ScaleEffect idle() => ScaleEffect(scale: 1);

  @override
  List<Object?> get props => [
        scale,
        scaleX,
        scaleY,
        alignment,
        origin,
        transformHitTests,
      ];
}
