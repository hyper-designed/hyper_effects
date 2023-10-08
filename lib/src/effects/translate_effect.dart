import 'package:flutter/widgets.dart';

import '../effect_builder.dart';
import 'effect.dart';

/// Provides a extension method to apply a [TranslateEffect] to a [Widget].
extension TranslateEffectExt on Widget {
  /// Applies a [TranslateEffect] to a [Widget] with the given [offset].
  /// [fractional] determines whether the [offset] moves the [Widget] by using
  /// its own size as a percentage or by a fixed amount.
  Widget translate(Offset offset, {bool fractional = false}) {
    return AnimatableEffect(
      effect: TranslateEffect(
        offset: offset,
        fractional: fractional,
      ),
      child: this,
    );
  }

  /// Applies a [TranslateEffect] to a [Widget] only on the x-axis.
  /// [fractional] determines whether the [offset] moves the [Widget] by using
  /// its own size as a percentage or by a fixed amount.
  Widget translateX(double x, {bool fractional = false}) {
    return AnimatableEffect(
      effect: TranslateEffect(
        offset: Offset(x, 0),
        fractional: fractional,
      ),
      child: this,
    );
  }

  /// Applies a [TranslateEffect] to a [Widget] only on the y-axis.
  /// [fractional] determines whether the [offset] moves the [Widget] by using
  /// its own size as a percentage or by a fixed amount.
  Widget translateY(double y, {bool fractional = false}) {
    return AnimatableEffect(
      effect: TranslateEffect(
        offset: Offset(0, y),
        fractional: fractional,
      ),
      child: this,
    );
  }

  /// Applies a [TranslateEffect] to a [Widget] with the given [x] and [y]
  /// values.
  /// [fractional] determines whether the [offset] moves the [Widget] by using
  /// its own size as a percentage or by a fixed amount.
  Widget translateXY(
    double x,
    double y, {
    bool fractional = false,
  }) {
    return AnimatableEffect(
      effect: TranslateEffect(
        offset: Offset(x, y),
        fractional: fractional,
      ),
      child: this,
    );
  }
}

/// An effect that translates a [Widget] by a given [offset].
class TranslateEffect extends Effect {
  /// The offset by which the [Widget] is translated.
  final Offset offset;

  /// Whether the [offset] is fractional. If true, the [offset] is a percentage
  /// of the [Widget]'s size. If false, the [offset] is a fixed amount.
  final bool fractional;

  /// Creates a [TranslateEffect] with the given [offset] and [fractional].
  TranslateEffect({
    this.offset = Offset.zero,
    this.fractional = false,
  });

  @override
  TranslateEffect lerp(covariant TranslateEffect other, double value) {
    return TranslateEffect(
      offset: Offset.lerp(offset, other.offset, value) ?? Offset.zero,
    );
  }

  @override
  Widget apply(BuildContext context, Widget child) {
    if (fractional) {
      return FractionalTranslation(
        translation: offset,
        child: child,
      );
    } else {
      return Transform.translate(
        offset: offset,
        child: child,
      );
    }
  }

  @override
  List<Object?> get props => [offset, fractional];
}
