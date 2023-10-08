import 'package:flutter/widgets.dart';

import '../effect_builder.dart';
import 'effect.dart';

/// Provides a extension method to apply a [TranslateEffect] to a [Widget].
extension TranslateEffectExt on Widget {
  /// Applies a [TranslateEffect] to a [Widget] with the given [offset].
  Widget translate(Offset offset) {
    return AnimatableEffect(
      effect: TranslateEffect(
        offset: offset,
      ),
      child: this,
    );
  }

  /// Applies a [TranslateEffect] to a [Widget] only on the x-axis.
  Widget translateX(double x) {
    return AnimatableEffect(
      effect: TranslateEffect(
        offset: Offset(x, 0),
      ),
      child: this,
    );
  }

  /// Applies a [TranslateEffect] to a [Widget] only on the y-axis.
  Widget translateY(double y) {
    return AnimatableEffect(
      effect: TranslateEffect(
        offset: Offset(0, y),
      ),
      child: this,
    );
  }

  /// Applies a [TranslateEffect] to a [Widget] with the given [x] and [y] values.
  Widget translateXY(
    double x,
    double y,
  ) {
    return AnimatableEffect(
      effect: TranslateEffect(
        offset: Offset(x, y),
      ),
      child: this,
    );
  }
}

/// An effect that translates a [Widget] by a given [offset].
class TranslateEffect extends Effect {
  /// The offset by which the [Widget] is translated.
  final Offset offset;

  /// Creates a [TranslateEffect] with the given [offset].
  TranslateEffect({
    this.offset = Offset.zero,
  });

  @override
  TranslateEffect lerp(covariant TranslateEffect other, double value) {
    return TranslateEffect(
      offset: Offset.lerp(offset, other.offset, value) ?? Offset.zero,
    );
  }

  @override
  Widget apply(BuildContext context, Widget child) {
    return Transform.translate(
      offset: offset,
      child: child,
    );
  }

  @override
  List<Object?> get props => [offset];
}
