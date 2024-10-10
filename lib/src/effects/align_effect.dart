import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../hyper_effects.dart';

/// Provides a extension method to apply an [AlignEffect] to a [Widget].
extension AlignEffectExt on Widget {
  /// Applies an [AlignEffect] to a [Widget] with the given [alignment].
  Widget align(
    AlignmentGeometry alignment, {
    AlignmentGeometry? from,
    double heightFactor = 1,
    double widthFactor = 1,
    double? fromHeightFactor,
    double? fromWidthFactor,
  }) {
    return EffectWidget(
      start: from == null && fromHeightFactor == null && fromWidthFactor == null
          ? null
          : AlignEffect(
              alignment: from ?? alignment,
              heightFactor: fromHeightFactor ?? heightFactor,
              widthFactor: fromWidthFactor ?? widthFactor,
            ),
      end: AlignEffect(
        alignment: alignment,
        heightFactor: heightFactor,
        widthFactor: widthFactor,
      ),
      child: this,
    );
  }

  /// Applies an [AlignEffect] to a [Widget] only on the x-axis.
  Widget alignX(double x, {double? from}) {
    return EffectWidget(
      start: from == null ? null : AlignEffect(alignment: Alignment(from, 0)),
      end: AlignEffect(alignment: Alignment(x, 0)),
      child: this,
    );
  }

  /// Applies an [AlignEffect] to a [Widget] only on the y-axis.
  Widget alignY(double y, {double? from}) {
    return EffectWidget(
      start: from == null ? null : AlignEffect(alignment: Alignment(0, from)),
      end: AlignEffect(alignment: Alignment(0, y)),
      child: this,
    );
  }

  /// Applies an [AlignEffect] to a [Widget] with the given [x] and [y]
  /// values.
  Widget alignXY(
    double x,
    double y, {
    AlignmentGeometry? from,
  }) {
    return EffectWidget(
      start: from == null ? null : AlignEffect(alignment: from),
      end: AlignEffect(alignment: Alignment(x, y)),
      child: this,
    );
  }
}

/// An effect that aligns a [Widget] by a given [alignment].
class AlignEffect extends Effect {
  /// The alignment by which the [Widget] is aligned.
  final AlignmentGeometry alignment;

  /// Sets its width to the child's width multiplied by this factor.
  final double widthFactor;

  /// Sets its height to the child's height multiplied by this factor.
  final double heightFactor;

  /// Creates a [AlignEffect] with the given [alignment] and [fractional].
  AlignEffect({
    this.alignment = AlignmentDirectional.topStart,
    this.widthFactor = 1,
    this.heightFactor = 1,
  });

  @override
  AlignEffect lerp(covariant AlignEffect other, double value) {
    return AlignEffect(
      alignment: AlignmentGeometry.lerp(alignment, other.alignment, value) ??
          AlignmentDirectional.topStart,
      widthFactor: (lerpDouble(widthFactor, other.widthFactor, value) ?? 1)
          .clampUnderZero,
      heightFactor: (lerpDouble(heightFactor, other.heightFactor, value) ?? 1)
          .clampUnderZero,
    );
  }

  @override
  Widget apply(BuildContext context, Widget? child) {
    return Align(
      alignment: alignment,
      widthFactor: widthFactor,
      heightFactor: heightFactor,
      child: child,
    );
  }

  @override
  AlignEffect idle() => AlignEffect();

  @override
  List<Object?> get props => [alignment, widthFactor, heightFactor];
}
