import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../hyper_effects.dart';

/// Provides a extension method to apply an [AlignEffect] to a [Widget].
extension AlignEffectExt on Widget {
  /// Applies an [AlignEffect] to a [Widget] with the given [alignment],
  /// optionally animating from [from].
  ///
  /// [widthFactor] and [heightFactor] mirror [Align]'s parameters: when
  /// null (the default), the widget expands to fill its incoming
  /// constraints; when set, the widget sizes itself to the child's size
  /// multiplied by the factor. [fromWidthFactor] and [fromHeightFactor]
  /// provide the starting factors, defaulting to [widthFactor] and
  /// [heightFactor]. A null and a non-null factor cannot be interpolated,
  /// so such a pair snaps to the target value instead of animating.
  Widget align(
    AlignmentGeometry alignment, {
    AlignmentGeometry? from,
    double? heightFactor,
    double? widthFactor,
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
  ///
  /// The widget expands to fill its incoming constraints, matching the
  /// default behavior of [Align].
  Widget alignX(double x, {double? from}) {
    return EffectWidget(
      start: from == null ? null : AlignEffect(alignment: Alignment(from, 0)),
      end: AlignEffect(alignment: Alignment(x, 0)),
      child: this,
    );
  }

  /// Applies an [AlignEffect] to a [Widget] only on the y-axis.
  ///
  /// The widget expands to fill its incoming constraints, matching the
  /// default behavior of [Align].
  Widget alignY(double y, {double? from}) {
    return EffectWidget(
      start: from == null ? null : AlignEffect(alignment: Alignment(0, from)),
      end: AlignEffect(alignment: Alignment(0, y)),
      child: this,
    );
  }

  /// Applies an [AlignEffect] to a [Widget] with the given [x] and [y]
  /// values.
  ///
  /// The widget expands to fill its incoming constraints, matching the
  /// default behavior of [Align].
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
  /// If null, the widget expands to fill its incoming width constraints,
  /// matching the default behavior of [Align].
  final double? widthFactor;

  /// Sets its height to the child's height multiplied by this factor.
  /// If null, the widget expands to fill its incoming height constraints,
  /// matching the default behavior of [Align].
  final double? heightFactor;

  /// Creates an [AlignEffect] with the given [alignment], [widthFactor],
  /// and [heightFactor].
  AlignEffect({
    this.alignment = AlignmentDirectional.topStart,
    this.widthFactor,
    this.heightFactor,
  });

  @override
  AlignEffect lerp(covariant AlignEffect other, double value) {
    return AlignEffect(
      alignment: AlignmentGeometry.lerp(alignment, other.alignment, value) ??
          AlignmentDirectional.topStart,
      widthFactor: _lerpFactor(widthFactor, other.widthFactor, value),
      heightFactor: _lerpFactor(heightFactor, other.heightFactor, value),
    );
  }

  /// A null factor means "fill the incoming constraints", which cannot be
  /// numerically interpolated with a size factor, so mixed endpoints snap
  /// to the target value.
  static double? _lerpFactor(double? a, double? b, double value) {
    if (a == null || b == null) return b;
    return (lerpDouble(a, b, value) ?? 1).clampUnderZero;
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
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AlignEffect &&
        other.runtimeType == runtimeType &&
        other.alignment == alignment &&
        other.widthFactor == widthFactor &&
        other.heightFactor == heightFactor;
  }

  @override
  int get hashCode => Object.hash(
        alignment,
        widthFactor,
        heightFactor,
      );

  @override
  String toString() =>
      'AlignEffect(alignment: $alignment, widthFactor: $widthFactor, heightFactor: $heightFactor)';
}
