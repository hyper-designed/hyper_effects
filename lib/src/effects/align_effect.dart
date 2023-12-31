import 'package:flutter/widgets.dart';

import '../effect_widget.dart';
import 'effect.dart';

/// Provides a extension method to apply an [AlignEffect] to a [Widget].
extension AlignEffectExt on Widget {
  /// Applies an [AlignEffect] to a [Widget] with the given [alignment].
  Widget align(
    AlignmentGeometry alignment, {
    AlignmentGeometry? from,
  }) {
    return EffectWidget(
      start: from == null ? null : AlignEffect(alignment: from),
      end: AlignEffect(alignment: alignment),
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

  /// Creates a [AlignEffect] with the given [alignment] and [fractional].
  AlignEffect({
    this.alignment = AlignmentDirectional.topStart,
  });

  @override
  AlignEffect lerp(covariant AlignEffect other, double value) {
    return AlignEffect(
      alignment: AlignmentGeometry.lerp(alignment, other.alignment, value) ??
          AlignmentDirectional.topStart,
    );
  }

  @override
  Widget apply(BuildContext context, Widget child) {
    return Align(
      alignment: alignment,
      child: child,
    );
  }

  @override
  List<Object?> get props => [alignment];
}
