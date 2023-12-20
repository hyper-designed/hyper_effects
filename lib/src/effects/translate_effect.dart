import 'package:flutter/widgets.dart';

import '../effect_builder.dart';
import 'effect.dart';

const double _kDefaultSlideOffset = 100.0;

/// Provides a extension method to apply a [TranslateEffect] to a [Widget].
extension TranslateEffectExt on Widget {
  /// Applies a [TranslateEffect] to a [Widget] with the given [offset].
  /// [fractional] determines whether the [offset] moves the [Widget] by using
  /// its own size as a percentage or by a fixed amount.
  Widget translate(Offset offset, {bool fractional = false}) {
    return EffectWidget(
      end: TranslateEffect(
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
    return EffectWidget(
      end: TranslateEffect(
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
    return EffectWidget(
      end: TranslateEffect(
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
    return EffectWidget(
      end: TranslateEffect(
        offset: Offset(x, y),
        fractional: fractional,
      ),
      child: this,
    );
  }

  /// Applies a [TranslateEffect] to a [Widget] with a default animation
  /// to slide this widget in.
  Widget slideIn(Offset offset, {bool fractional = false}) {
    return EffectWidget(
      start: TranslateEffect(
        offset: offset,
        fractional: fractional,
      ),
      end: TranslateEffect(
        offset: Offset.zero,
        fractional: fractional,
      ),
      child: this,
    );
  }

  /// Applies a [TranslateEffect] to a [Widget] with a default animation
  /// to slide this widget out.
  Widget slideOut(Offset offset, {bool fractional = false}) {
    return EffectWidget(
      start: TranslateEffect(
        offset: Offset.zero,
        fractional: fractional,
      ),
      end: TranslateEffect(
        offset: offset,
        fractional: fractional,
      ),
      child: this,
    );
  }

  /// Applies a [TranslateEffect] to a [Widget] with a default animation
  /// to slide this widget in from the right.
  Widget slideInFromLeft({
    double? value,
    bool fractional = false,
  }) => slideIn(
      Offset(value ?? (fractional ? -1 : -_kDefaultSlideOffset), 0),
      fractional: fractional,
    );

  /// Applies a [TranslateEffect] to a [Widget] with a default animation
  /// to slide this widget in from the right.
  Widget slideInFromRight({
    double? value,
    bool fractional = false,
  }) => slideIn(
      Offset(value ?? (fractional ? 1 : _kDefaultSlideOffset), 0),
      fractional: fractional,
    );

  /// Applies a [TranslateEffect] to a [Widget] with a default animation
  /// to slide this widget in from the top.
  Widget slideInFromTop({
    double? value,
    bool fractional = false,
  }) => slideIn(
      Offset(0, value ?? (fractional ? -1 : -_kDefaultSlideOffset)),
      fractional: fractional,
    );

  /// Applies a [TranslateEffect] to a [Widget] with a default animation
  /// to slide this widget in from the bottom.
  Widget slideInFromBottom({
    double? value,
    bool fractional = false,
  }) => slideIn(
      Offset(0, value ?? (fractional ? 1 : _kDefaultSlideOffset)),
      fractional: fractional,
    );

  /// Applies a [TranslateEffect] to a [Widget] with a default animation
  /// to slide this widget out to the left.
  Widget slideOutToLeft({
    double? value,
    bool fractional = false,
  }) => slideOut(
      Offset(value ?? (fractional ? -1 : -_kDefaultSlideOffset), 0),
      fractional: fractional,
    );

  /// Applies a [TranslateEffect] to a [Widget] with a default animation
  /// to slide this widget out to the right.
  Widget slideOutToRight({
    double? value,
    bool fractional = false,
  }) => slideOut(
      Offset(value ?? (fractional ? 1 : _kDefaultSlideOffset), 0),
      fractional: fractional,
    );

  /// Applies a [TranslateEffect] to a [Widget] with a default animation
  /// to slide this widget out to the top.
  Widget slideOutToTop({
    double? value,
    bool fractional = false,
  }) => slideOut(
      Offset(0, value ?? (fractional ? -1 : -_kDefaultSlideOffset)),
      fractional: fractional,
    );

  /// Applies a [TranslateEffect] to a [Widget] with a default animation
  /// to slide this widget out to the bottom.
  Widget slideOutToBottom({
    double? value,
    bool fractional = false,
  }) => slideOut(
      Offset(0, value ?? (fractional ? 1 : _kDefaultSlideOffset)),
      fractional: fractional,
    );
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
