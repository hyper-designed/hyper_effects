import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:hyper_effects/hyper_effects.dart';

/// Provides a extension method to apply an [OpacityEffect] to a [Widget].
extension OpacityEffectExtension on Widget {
  /// Applies an [OpacityEffect] to a [Widget].
  Widget opacity(double opacity) {
    return AnimatableEffect(
      effect: OpacityEffect(opacity: opacity),
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
