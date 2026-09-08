import 'package:flutter/widgets.dart';

import '../effect_widget.dart';
import 'effect.dart';
import 'vector_effect.dart';

/// Provides a extension method to apply an [PaddingEffect] to a [Widget].
extension PaddingEffectExt on Widget {
  /// Applies an [PaddingEffect] to a [Widget] with the given [padding].
  Widget pad(
    EdgeInsets padding, {
    EdgeInsets? from,
  }) {
    return EffectWidget(
      start: from == null ? null : PaddingEffect(padding: from),
      end: PaddingEffect(padding: padding),
      child: this,
    );
  }

  /// Applies an [PaddingEffect] to a [Widget] with the given [padding].
  Widget padAll(
    double padding, {
    double? from,
  }) {
    return EffectWidget(
      start: from == null ? null : PaddingEffect(padding: EdgeInsets.all(from)),
      end: PaddingEffect(padding: EdgeInsets.all(padding)),
      child: this,
    );
  }

  /// Applies an [PaddingEffect] to a [Widget] with the given [vertical]
  /// and [horizontal] padding.
  Widget padSymmetric(
      {double vertical = 0, double horizontal = 0, double? from}) {
    return EffectWidget(
      start: from == null
          ? null
          : PaddingEffect(
              padding: EdgeInsets.symmetric(vertical: from, horizontal: from)),
      end: PaddingEffect(
          padding:
              EdgeInsets.symmetric(vertical: vertical, horizontal: horizontal)),
      child: this,
    );
  }

  /// Applies an [PaddingEffect] to a [Widget] with the given [horizontal]
  /// padding.
  Widget padHorizontal(
    double padding, {
    double? from,
  }) {
    return EffectWidget(
      start: from == null
          ? null
          : PaddingEffect(padding: EdgeInsets.symmetric(horizontal: from)),
      end: PaddingEffect(padding: EdgeInsets.symmetric(horizontal: padding)),
      child: this,
    );
  }

  /// Applies an [PaddingEffect] to a [Widget] with the given [vertical]
  /// padding.
  Widget padVertical(
    double padding, {
    double? from,
  }) {
    return EffectWidget(
      start: from == null
          ? null
          : PaddingEffect(padding: EdgeInsets.symmetric(vertical: from)),
      end: PaddingEffect(padding: EdgeInsets.symmetric(vertical: padding)),
      child: this,
    );
  }

  /// Applies an [PaddingEffect] to a [Widget] with the given [left], [right],
  /// [top], and [bottom] padding.
  Widget padOnly({
    double left = 0,
    double right = 0,
    double top = 0,
    double bottom = 0,
    double? from,
  }) {
    return EffectWidget(
      start: from == null
          ? null
          : PaddingEffect(
              padding: EdgeInsets.only(
                  left: from, right: from, top: from, bottom: from)),
      end: PaddingEffect(
          padding: EdgeInsets.only(
              left: left, right: right, top: top, bottom: bottom)),
      child: this,
    );
  }

  /// Applies an [PaddingEffect] to a [Widget] with the given [left] padding.
  Widget padLeft(
    double padding, {
    double? from,
  }) {
    return EffectWidget(
      start: from == null
          ? null
          : PaddingEffect(padding: EdgeInsets.only(left: from)),
      end: PaddingEffect(padding: EdgeInsets.only(left: padding)),
      child: this,
    );
  }

  /// Applies an [PaddingEffect] to a [Widget] with the given [right] padding.
  Widget padRight(
    double padding, {
    double? from,
  }) {
    return EffectWidget(
      start: from == null
          ? null
          : PaddingEffect(padding: EdgeInsets.only(right: from)),
      end: PaddingEffect(padding: EdgeInsets.only(right: padding)),
      child: this,
    );
  }

  /// Applies an [PaddingEffect] to a [Widget] with the given [top] padding.
  Widget padTop(
    double padding, {
    double? from,
  }) {
    return EffectWidget(
      start: from == null
          ? null
          : PaddingEffect(padding: EdgeInsets.only(top: from)),
      end: PaddingEffect(padding: EdgeInsets.only(top: padding)),
      child: this,
    );
  }

  /// Applies an [PaddingEffect] to a [Widget] with the given [bottom] padding.
  Widget padBottom(
    double padding, {
    double? from,
  }) {
    return EffectWidget(
      start: from == null
          ? null
          : PaddingEffect(padding: EdgeInsets.only(bottom: from)),
      end: PaddingEffect(padding: EdgeInsets.only(bottom: padding)),
      child: this,
    );
  }
}

/// An effect that insets a [Widget] by a given [padding].
///
/// [PaddingEffect] is a [VectorEffect]: its four insets add, subtract and
/// scale as a single vector quantity, which is what lets padding take part
/// in the same physics as every other animatable geometry in this library.
/// Two things follow from that, and neither is available to effects that
/// stay on the normalized lerp path:
///
/// * **Overshoot is real.** A spring does not creep up on its target and
///   stop; it sails past and comes back. Under a bouncy motion `.pad()`
///   now describes the same curve as a sibling `.translateY()` driven by
///   the same motion, instead of quietly arriving early and flat. Before
///   this, mixing the two on one widget meant either accepting that the
///   geometry disagreed with itself or moving everything off padding to
///   keep it consistent.
/// * **Momentum survives a retarget.** Changing the target mid-flight
///   hands the in-flight velocity to the new spring instead of restarting
///   it from rest, so rapid re-triggers whip rather than hitch.
///
/// The price of real overshoot is that the interpolated value is no longer
/// bounded by its two endpoints: an inset animating down toward zero passes
/// through negative numbers on the way back up. [RenderPadding] asserts
/// `padding.isNonNegative`, so a negative inset can never reach a [Padding]
/// widget.
///
/// That guard lives in [apply], not in [lerp] — the same division of labour
/// `OpacityEffect` uses. Clamping inside [lerp] protects nothing that
/// [apply] cannot protect, and pays for it by flattening the curve for
/// every consumer, including the ones whose padding never goes anywhere
/// near zero. Clamping inside [apply] floors only the components that
/// actually went negative, at the last possible moment, and leaves the
/// algebra exact.
class PaddingEffect extends Effect with VectorEffect<PaddingEffect> {
  /// The insets applied to the [Widget].
  ///
  /// Mid-flight this may hold values outside the animation's endpoints,
  /// including negative ones — see the class documentation. [apply] is
  /// where it is made safe for layout.
  final EdgeInsets padding;

  /// Creates a [PaddingEffect] with the given [padding].
  PaddingEffect({
    this.padding = EdgeInsets.zero,
  });

  /// Interpolates toward [other], unclamped in both the parameter and the
  /// result.
  ///
  /// [value] below 0 or above 1 extrapolates rather than saturating: that
  /// is exactly how an overshooting curve (or a spring evaluated through
  /// this path) expresses its overshoot. Non-negativity is restored in
  /// [apply].
  @override
  PaddingEffect lerp(covariant PaddingEffect other, double value) {
    return PaddingEffect(
      padding: EdgeInsets.lerp(padding, other.padding, value) ?? EdgeInsets.zero,
    );
  }

  /// Builds the [Padding], flooring any inset that overshot below zero.
  ///
  /// Only the negative components are touched; an inset that overshot
  /// upward is passed through at full size, because a larger-than-target
  /// padding is perfectly representable and is the visible half of the
  /// bounce. This is the single point where the [RenderPadding] assert
  /// applies, because it is the single point where the value becomes
  /// layout.
  @override
  Widget apply(BuildContext context, Widget? child) {
    return Padding(
      padding: padding.isNonNegative
          ? padding
          : EdgeInsets.only(
              left: _floor(padding.left),
              top: _floor(padding.top),
              right: _floor(padding.right),
              bottom: _floor(padding.bottom),
            ),
      child: child,
    );
  }

  static double _floor(double value) => value < 0 ? 0 : value;

  @override
  PaddingEffect idle() => PaddingEffect();

  /// Field-wise sum of the four insets.
  ///
  /// [PaddingEffect] carries no configuration, so there is nothing to ride
  /// along from the left operand — every value it holds is animatable.
  @override
  PaddingEffect operator +(PaddingEffect other) =>
      PaddingEffect(padding: padding + other.padding);

  /// Field-wise difference of the four insets. Routinely negative: this is
  /// the displacement term of the spring solution, not a renderable state.
  @override
  PaddingEffect operator -(PaddingEffect other) =>
      PaddingEffect(padding: padding - other.padding);

  /// Scales all four insets by [factor].
  @override
  PaddingEffect operator *(double factor) =>
      PaddingEffect(padding: padding * factor);

  /// The squared Euclidean length of the inset 4-vector, used for settle
  /// detection.
  @override
  double get magnitudeSquared =>
      padding.left * padding.left +
      padding.top * padding.top +
      padding.right * padding.right +
      padding.bottom * padding.bottom;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaddingEffect &&
        other.runtimeType == runtimeType &&
        other.padding == padding;
  }

  @override
  int get hashCode => padding.hashCode;

  @override
  String toString() => 'PaddingEffect(padding: $padding)';
}
