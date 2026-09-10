import 'package:flutter/widgets.dart';

import '../effect_widget.dart';
import 'effect.dart';
import 'vector_effect.dart';

const double _kDefaultSlideOffset = 100.0;

/// Provides a extension method to apply a [TranslateEffect] to a [Widget].
extension TranslateEffectExt on Widget {
  /// Applies a [TranslateEffect] to a [Widget] with the given [offset].
  /// [fractional] determines whether the [offset] moves the [Widget] by using
  /// its own size as a percentage or by a fixed amount.
  /// [transformHitTests] matches Flutter's [Transform.translate] default:
  /// hit testing follows the painted widget. Pass false only for deliberately
  /// paint-only movement whose interactive region must stay in layout space.
  Widget translate(
    Offset offset, {
    bool fractional = false,
    bool transformHitTests = true,
    Offset? from,
  }) {
    return EffectWidget(
      start: from == null
          ? null
          : TranslateEffect(
              offset: from,
              fractional: fractional,
              transformHitTests: transformHitTests,
            ),
      end: TranslateEffect(
        offset: offset,
        fractional: fractional,
        transformHitTests: transformHitTests,
      ),
      child: this,
    );
  }

  /// Applies a [TranslateEffect] to a [Widget] only on the x-axis.
  /// [fractional] determines whether the [offset] moves the [Widget] by using
  /// its own size as a percentage or by a fixed amount.
  Widget translateX(
    double x, {
    bool fractional = false,
    bool transformHitTests = true,
    double? from,
  }) {
    return EffectWidget(
      start: from == null
          ? null
          : TranslateEffect(
              offset: Offset(from, 0),
              fractional: fractional,
              transformHitTests: transformHitTests,
            ),
      end: TranslateEffect(
        offset: Offset(x, 0),
        fractional: fractional,
        transformHitTests: transformHitTests,
      ),
      child: this,
    );
  }

  /// Applies a [TranslateEffect] to a [Widget] only on the y-axis.
  /// [fractional] determines whether the [offset] moves the [Widget] by using
  /// its own size as a percentage or by a fixed amount.
  Widget translateY(
    double y, {
    bool fractional = false,
    bool transformHitTests = true,
    double? from,
  }) {
    return EffectWidget(
      start: from == null
          ? null
          : TranslateEffect(
              offset: Offset(0, from),
              fractional: fractional,
              transformHitTests: transformHitTests,
            ),
      end: TranslateEffect(
        offset: Offset(0, y),
        fractional: fractional,
        transformHitTests: transformHitTests,
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
    bool transformHitTests = true,
    Offset? from,
  }) {
    return EffectWidget(
      start: from == null
          ? null
          : TranslateEffect(
              offset: from,
              fractional: fractional,
              transformHitTests: transformHitTests,
            ),
      end: TranslateEffect(
        offset: Offset(x, y),
        fractional: fractional,
        transformHitTests: transformHitTests,
      ),
      child: this,
    );
  }

  /// Applies a [TranslateEffect] to a [Widget] with a default animation
  /// to slide this widget in.
  Widget slideIn(
    Offset offset, {
    bool fractional = false,
    bool transformHitTests = true,
  }) {
    return EffectWidget(
      start: TranslateEffect(
        offset: offset,
        fractional: fractional,
        transformHitTests: transformHitTests,
      ),
      end: TranslateEffect(
        offset: Offset.zero,
        fractional: fractional,
        transformHitTests: transformHitTests,
      ),
      child: this,
    );
  }

  /// Applies a [TranslateEffect] to a [Widget] with a default animation
  /// to slide this widget in.
  Widget slideInVertically(
    double y, {
    bool fractional = false,
    bool transformHitTests = true,
  }) {
    return EffectWidget(
      start: TranslateEffect(
        offset: Offset(0, y),
        fractional: fractional,
        transformHitTests: transformHitTests,
      ),
      end: TranslateEffect(
        offset: Offset.zero,
        fractional: fractional,
        transformHitTests: transformHitTests,
      ),
      child: this,
    );
  }

  /// Applies a [TranslateEffect] to a [Widget] with a default animation
  /// to slide this widget in.
  Widget slideInHorizontally(
    double x, {
    bool fractional = false,
    bool transformHitTests = true,
  }) {
    return EffectWidget(
      start: TranslateEffect(
        offset: Offset(x, 0),
        fractional: fractional,
        transformHitTests: transformHitTests,
      ),
      end: TranslateEffect(
        offset: Offset.zero,
        fractional: fractional,
        transformHitTests: transformHitTests,
      ),
      child: this,
    );
  }

  /// Applies a [TranslateEffect] to a [Widget] with a default animation
  /// to slide this widget out.
  Widget slideOut(
    Offset offset, {
    bool fractional = false,
    bool transformHitTests = true,
  }) {
    return EffectWidget(
      start: TranslateEffect(
        offset: Offset.zero,
        fractional: fractional,
        transformHitTests: transformHitTests,
      ),
      end: TranslateEffect(
        offset: offset,
        fractional: fractional,
        transformHitTests: transformHitTests,
      ),
      child: this,
    );
  }

  /// Applies a [TranslateEffect] to a [Widget] with a default animation
  /// to slide this widget out.
  Widget slideOutVertically(
    double y, {
    bool fractional = false,
    bool transformHitTests = true,
  }) {
    return EffectWidget(
      start: TranslateEffect(
        offset: Offset.zero,
        fractional: fractional,
        transformHitTests: transformHitTests,
      ),
      end: TranslateEffect(
        offset: Offset(0, y),
        fractional: fractional,
        transformHitTests: transformHitTests,
      ),
      child: this,
    );
  }

  /// Applies a [TranslateEffect] to a [Widget] with a default animation
  /// to slide this widget out.
  Widget slideOutHorizontally(
    double x, {
    bool fractional = false,
    bool transformHitTests = true,
  }) {
    return EffectWidget(
      start: TranslateEffect(
        offset: Offset.zero,
        fractional: fractional,
        transformHitTests: transformHitTests,
      ),
      end: TranslateEffect(
        offset: Offset(x, 0),
        fractional: fractional,
        transformHitTests: transformHitTests,
      ),
      child: this,
    );
  }

  /// Applies a [TranslateEffect] to a [Widget] with a default animation
  /// to slide this widget in from the right.
  Widget slideInFromLeft({
    double? value,
    bool fractional = false,
    bool transformHitTests = true,
  }) =>
      slideIn(
        Offset(value ?? (fractional ? -1 : -_kDefaultSlideOffset), 0),
        fractional: fractional,
        transformHitTests: transformHitTests,
      );

  /// Applies a [TranslateEffect] to a [Widget] with a default animation
  /// to slide this widget in from the right.
  Widget slideInFromRight({
    double? value,
    bool fractional = false,
    bool transformHitTests = true,
  }) =>
      slideIn(
        Offset(value ?? (fractional ? 1 : _kDefaultSlideOffset), 0),
        fractional: fractional,
        transformHitTests: transformHitTests,
      );

  /// Applies a [TranslateEffect] to a [Widget] with a default animation
  /// to slide this widget in from the top.
  Widget slideInFromTop({
    double? value,
    bool fractional = false,
    bool transformHitTests = true,
  }) =>
      slideIn(
        Offset(0, value ?? (fractional ? -1 : -_kDefaultSlideOffset)),
        fractional: fractional,
        transformHitTests: transformHitTests,
      );

  /// Applies a [TranslateEffect] to a [Widget] with a default animation
  /// to slide this widget in from the bottom.
  Widget slideInFromBottom({
    double? value,
    bool fractional = false,
    bool transformHitTests = true,
  }) =>
      slideIn(
        Offset(0, value ?? (fractional ? 1 : _kDefaultSlideOffset)),
        fractional: fractional,
        transformHitTests: transformHitTests,
      );

  /// Applies a [TranslateEffect] to a [Widget] with a default animation
  /// to slide this widget out to the left.
  Widget slideOutToLeft({
    double? value,
    bool fractional = false,
    bool transformHitTests = true,
  }) =>
      slideOut(
        Offset(value ?? (fractional ? -1 : -_kDefaultSlideOffset), 0),
        fractional: fractional,
        transformHitTests: transformHitTests,
      );

  /// Applies a [TranslateEffect] to a [Widget] with a default animation
  /// to slide this widget out to the right.
  Widget slideOutToRight({
    double? value,
    bool fractional = false,
    bool transformHitTests = true,
  }) =>
      slideOut(
        Offset(value ?? (fractional ? 1 : _kDefaultSlideOffset), 0),
        fractional: fractional,
        transformHitTests: transformHitTests,
      );

  /// Applies a [TranslateEffect] to a [Widget] with a default animation
  /// to slide this widget out to the top.
  Widget slideOutToTop({
    double? value,
    bool fractional = false,
    bool transformHitTests = true,
  }) =>
      slideOut(
        Offset(0, value ?? (fractional ? -1 : -_kDefaultSlideOffset)),
        fractional: fractional,
        transformHitTests: transformHitTests,
      );

  /// Applies a [TranslateEffect] to a [Widget] with a default animation
  /// to slide this widget out to the bottom.
  Widget slideOutToBottom({
    double? value,
    bool fractional = false,
    bool transformHitTests = true,
  }) =>
      slideOut(
        Offset(0, value ?? (fractional ? 1 : _kDefaultSlideOffset)),
        fractional: fractional,
        transformHitTests: transformHitTests,
      );
}

/// An effect that translates a [Widget] by a given [offset].
class TranslateEffect extends Effect with VectorEffect<TranslateEffect> {
  /// The offset by which the [Widget] is translated.
  final Offset offset;

  /// Whether the [offset] is fractional. If true, the [offset] is a percentage
  /// of the [Widget]'s size. If false, the [offset] is a fixed amount.
  final bool fractional;

  /// Whether hit testing follows this effect's painted translation.
  ///
  /// Defaults to true, matching Flutter's [Transform.translate]. False is an
  /// explicit paint-only mode: the widget draws at [offset], but any gesture
  /// target inside it continues answering where layout originally placed it.
  /// That split is useful for visual-only motion and surprising for controls,
  /// so the framework's interactive-safe behavior is the default.
  final bool transformHitTests;

  /// Creates a [TranslateEffect] with the given [offset] and [fractional].
  TranslateEffect({
    this.offset = Offset.zero,
    this.fractional = false,
    this.transformHitTests = true,
  });

  @override
  TranslateEffect lerp(covariant TranslateEffect other, double value) {
    return TranslateEffect(
      fractional: other.fractional,
      transformHitTests:
          value < 0.5 ? transformHitTests : other.transformHitTests,
      offset: Offset.lerp(offset, other.offset, value) ?? Offset.zero,
    );
  }

  @override
  Widget apply(BuildContext context, Widget? child) {
    if (fractional) {
      return FractionalTranslation(
        translation: offset,
        transformHitTests: transformHitTests,
        child: child,
      );
    } else {
      return Transform.translate(
        offset: offset,
        transformHitTests: transformHitTests,
        child: child,
      );
    }
  }

  @override
  TranslateEffect idle() => TranslateEffect(
        offset: Offset.zero,
        fractional: fractional,
        transformHitTests: transformHitTests,
      );

  @override
  TranslateEffect operator +(TranslateEffect other) => TranslateEffect(
        offset: offset + other.offset,
        fractional: fractional,
        transformHitTests: transformHitTests,
      );

  @override
  TranslateEffect operator -(TranslateEffect other) => TranslateEffect(
        offset: offset - other.offset,
        fractional: fractional,
        transformHitTests: transformHitTests,
      );

  @override
  TranslateEffect operator *(double factor) => TranslateEffect(
        offset: offset * factor,
        fractional: fractional,
        transformHitTests: transformHitTests,
      );

  @override
  double get magnitudeSquared => offset.distanceSquared;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TranslateEffect &&
        other.runtimeType == runtimeType &&
        other.offset == offset &&
        other.fractional == fractional &&
        other.transformHitTests == transformHitTests;
  }

  @override
  int get hashCode => Object.hash(
        offset,
        fractional,
        transformHitTests,
      );

  @override
  String toString() =>
      'TranslateEffect(offset: $offset, fractional: $fractional, transformHitTests: $transformHitTests)';
}
