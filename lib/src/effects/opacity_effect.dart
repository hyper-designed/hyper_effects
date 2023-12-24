import 'dart:ui';

import 'package:flutter/widgets.dart';
import '../../hyper_effects.dart';

/// Provides a extension method to apply an [OpacityEffect] to a [Widget].
extension OpacityEffectExtension on Widget {
  /// Applies an [OpacityEffect] to a [Widget].
  Widget opacity(double opacity, {double? from}) {
    return EffectWidget(
      start: from == null ? null : OpacityEffect(opacity: from),
      end: OpacityEffect(opacity: opacity),
      child: this,
    );
  }

  /// Alias to [opacity].
  Widget fade(double opacity, {double? from}) {
    return EffectWidget(
      start: from == null ? null : OpacityEffect(opacity: from),
      end: OpacityEffect(opacity: opacity),
      child: this,
    );
  }

  /// Applies an [OpacityEffect] to a [Widget] with a default fade in
  /// animation.
  Widget fadeIn({double start = 0, double end = 1}) {
    return EffectWidget(
      start: OpacityEffect(opacity: start),
      end: OpacityEffect(opacity: end),
      child: this,
    );
  }

  /// Applies an [OpacityEffect] to a [Widget] with a default fade out
  /// animation.
  Widget fadeOut({double start = 1, double end = 0}) {
    return EffectWidget(
      start: OpacityEffect(opacity: start),
      end: OpacityEffect(opacity: end),
      child: this,
    );
  }
}

/// An [Effect] that applies an opacity to a [Widget].
class OpacityEffect extends Effect {
  /// The opacity to apply to the [Widget]. Defaults to 1.
  final double opacity;

  /// Creates an [OpacityEffect].
  OpacityEffect({required this.opacity});

  @override
  OpacityEffect lerp(covariant OpacityEffect other, double value) {
    return OpacityEffect(
      opacity: lerpDouble(opacity, other.opacity, value) ?? 1,
    );
  }

  @override
  Widget apply(BuildContext context, Widget child) =>
      Opacity(opacity: opacity, child: child);

  @override
  List<Object?> get props => [opacity];
}
