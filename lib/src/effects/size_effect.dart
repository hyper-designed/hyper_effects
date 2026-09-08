import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../effect_widget.dart';
import 'effect.dart';
import 'vector_effect.dart';

/// Provides extension methods to apply a [SizeEffect] to a [Widget].
///
/// These are deliberately not named `width`, `height`, or `size`: core
/// widgets this extension targets — [SizedBox] and [Image] among them —
/// already declare instance fields with those exact names, and Dart
/// resolves a member access against the receiver's declared instance
/// members before it ever considers an extension. `someSizedBox.width` would
/// silently resolve to [SizedBox.width] (a `double?` field) instead of this
/// extension's method, and calling it — `someSizedBox.width(120)` — fails to
/// compile because a `double?` field is not callable. [PaddingEffectExt]
/// hits the identical hazard against [Padding.padding]/[Container.padding]
/// and sidesteps it the same way, naming its methods `pad`/`padAll` instead
/// of `padding`; the `To` suffix used here follows that precedent while
/// staying close to the requested vocabulary.
extension SizeEffectExt on Widget {
  /// Applies a [SizeEffect] that constrains this [Widget]'s width to
  /// [width], leaving its height unconstrained, optionally animating from
  /// [from].
  ///
  /// Unlike [scale], which resizes the widget at paint time without telling
  /// its parent, this changes the actual layout size: the parent sees the
  /// new width and reflows around it.
  Widget widthTo(double width, {double? from}) {
    return EffectWidget(
      start: from == null ? null : SizeEffect(width: from),
      end: SizeEffect(width: width),
      child: this,
    );
  }

  /// Applies a [SizeEffect] that constrains this [Widget]'s height to
  /// [height], leaving its width unconstrained, optionally animating from
  /// [from].
  ///
  /// Unlike [scale], which resizes the widget at paint time without telling
  /// its parent, this changes the actual layout size: the parent sees the
  /// new height and reflows around it.
  Widget heightTo(double height, {double? from}) {
    return EffectWidget(
      start: from == null ? null : SizeEffect(height: from),
      end: SizeEffect(height: height),
      child: this,
    );
  }

  /// Applies a [SizeEffect] that constrains this [Widget] to [size],
  /// optionally animating from [from].
  ///
  /// Both axes are set together. To animate one axis while leaving the
  /// other unconstrained — or to give each axis its own starting value —
  /// use [sizeOf] instead, since [Size] cannot express "no constraint on
  /// this axis".
  Widget sizeTo(Size size, {Size? from}) {
    return EffectWidget(
      start: from == null
          ? null
          : SizeEffect(width: from.width, height: from.height),
      end: SizeEffect(width: size.width, height: size.height),
      child: this,
    );
  }

  /// Applies a [SizeEffect] with independently nullable [width] and
  /// [height], each with its own optional starting value.
  ///
  /// [sizeTo] takes a [Size], which cannot represent "leave this axis
  /// unconstrained" or give the two axes independent `from` values in a
  /// single call. This method exists for the cases [sizeTo] cannot cover:
  /// setting only one axis while leaving the other to its incoming
  /// constraints, or animating both axes from different starting points.
  /// A null [width] or [height] here means the same thing it means on
  /// [SizeEffect]: don't constrain that axis at all.
  Widget sizeOf({
    double? width,
    double? height,
    double? fromWidth,
    double? fromHeight,
  }) {
    return EffectWidget(
      start: fromWidth == null && fromHeight == null
          ? null
          : SizeEffect(
              width: fromWidth ?? width,
              height: fromHeight ?? height,
            ),
      end: SizeEffect(width: width, height: height),
      child: this,
    );
  }
}

/// An effect that constrains a [Widget] to an explicit width and/or height
/// via a [SizedBox].
///
/// ## This changes layout, not just paint
///
/// [ScaleEffect] resizes a widget's painted pixels without changing what it
/// reports to its parent during layout — the parent lays it out at its
/// natural size and the scale is applied on top, so surrounding widgets
/// never reflow. [SizeEffect] is the opposite: it wraps the child in a
/// [SizedBox], so the constraint it produces IS what the parent sees during
/// layout. A pill whose width springs to fit a growing label, with
/// siblings sliding out of the way as it grows, needs [SizeEffect] for
/// exactly this reason — [ScaleEffect] would stretch the pixels without
/// ever telling the row that it needs more room.
///
/// ## What a null axis means
///
/// [width] and [height] are independently nullable, matching [SizedBox]:
/// null means "do not constrain this axis," not "constrain it to zero."
/// Those are different layout modes, and there is no number partway
/// between "unconstrained" and "300 pixels wide." This is the same
/// situation [AlignEffect] has with `widthFactor`/`heightFactor`, and this
/// effect follows its precedent: nullability is treated as CONFIGURATION
/// and rides along from the LEFT operand in [operator +] and
/// [operator -], and a null paired with a non-null axis in [lerp] snaps
/// straight to the target instead of animating, because there is no
/// arithmetic between a mode and a number.
///
/// ## The `double.infinity` hazard
///
/// [SizedBox] accepts `double.infinity` as a legitimate width or height —
/// it means "expand to fill." But the spring solver computes a
/// displacement as `start - end` and later recombines it as
/// `target + displacement * coefficient`; if both endpoints of an axis are
/// infinite, `start - end` is `double.infinity - double.infinity`, which is
/// NaN, and every frame built from that NaN is poisoned for the rest of
/// the animation. [operator -] is the one place this can actually happen —
/// it is the only operator that subtracts two endpoints — so it is the
/// only place a non-finite check is needed: whenever either side of an
/// axis is non-finite there, that axis poisons to `null` in the
/// displacement, exactly as a null axis would, and flows through
/// [operator +] and [operator *] from then on as an absent quantity. Those
/// two operators need no finite check of their own, because by the time
/// they run, an axis that started non-finite has already been nulled out
/// by [operator -] — [operator +] never sees a finite/infinite pair on the
/// same axis to add. [lerp] applies the same rule directly: a non-finite
/// endpoint on either side snaps to the target rather than interpolating,
/// generalizing the null-snap rule above.
///
/// ## Where the non-negative clamp lives
///
/// A spring that overshoots past its target can swing an axis below zero,
/// and [SizedBox] asserts non-negative dimensions. Following
/// [OpacityEffect] (which clamps in `apply`, not in `lerp`), the floor
/// lives only in [apply]: [lerp] is also used for the curve-based,
/// non-spring path, where the interpolation `value` itself can exceed
/// `[0, 1]` for overshoot curves like `Curves.easeOutBack`, and clamping
/// the *result* there would quietly discard overshoot the curve was asked
/// to produce. The floor only needs to exist at the one point where a
/// negative value would otherwise become a real constraint and hit
/// [SizedBox]'s assert — which is [apply], after every other combination
/// has already happened.
class SizeEffect extends Effect with VectorEffect<SizeEffect> {
  /// The width this [Widget] is constrained to, or null to leave the width
  /// unconstrained.
  ///
  /// Null and non-null are different layout modes, not different numbers:
  /// see the class documentation for how a mixed pair resolves.
  final double? width;

  /// The height this [Widget] is constrained to, or null to leave the
  /// height unconstrained.
  ///
  /// Null and non-null are different layout modes, not different numbers:
  /// see the class documentation for how a mixed pair resolves.
  final double? height;

  /// Creates a [SizeEffect] with the given [width] and [height].
  SizeEffect({this.width, this.height});

  @override
  SizeEffect lerp(covariant SizeEffect other, double value) {
    return SizeEffect(
      width: _lerpAxis(width, other.width, value),
      height: _lerpAxis(height, other.height, value),
    );
  }

  /// Interpolates one axis, snapping straight to [b] whenever either side
  /// is null or non-finite — see the class documentation for why neither
  /// case can be meaningfully interpolated.
  static double? _lerpAxis(double? a, double? b, double value) {
    if (a == null || b == null) return b;
    if (!a.isFinite || !b.isFinite) return b;
    return lerpDouble(a, b, value);
  }

  /// Builds the [SizedBox], flooring any axis that overshot below zero.
  ///
  /// [SizedBox] asserts non-negative dimensions, so this is a hard
  /// requirement rather than a stylistic one — and it is the only place
  /// the requirement applies, because it is the only place the value
  /// becomes a real layout constraint. See the class documentation for why
  /// the floor does not also live in [lerp].
  @override
  Widget apply(BuildContext context, Widget? child) {
    return SizedBox(
      width: _floorAxis(width),
      height: _floorAxis(height),
      child: child,
    );
  }

  /// Floors an axis at zero while preserving null, which is a layout mode
  /// rather than a number and must never be turned into one.
  static double? _floorAxis(double? value) {
    if (value == null) return null;
    return value < 0 ? 0 : value;
  }

  /// The neutral state: both axes unconstrained.
  ///
  /// [idle] is what an effect looks like when it is not really "on" —
  /// [EffectWidget] uses it as the implicit starting point when a widget
  /// animates in without an explicit `from`. For [SizeEffect] that neutral
  /// state is "no constraint at all," the same as never having applied a
  /// [SizeEffect] in the first place, not a copy of whatever width or
  /// height happens to be set on this instance. This mirrors
  /// `AlignEffect.idle()`, whose factors reset to null for the same reason.
  @override
  SizeEffect idle() => SizeEffect();

  /// Field-wise sum, keeping nullability from the LEFT operand: see the
  /// class documentation for why this is the right shape for a field that
  /// means "unconstrained" rather than "zero" when null.
  @override
  SizeEffect operator +(SizeEffect other) => SizeEffect(
        width: _addAxis(width, other.width),
        height: _addAxis(height, other.height),
      );

  /// Field-wise difference — the displacement term of the spring solution.
  /// This is the one operator that can actually produce
  /// `double.infinity - double.infinity`, so it is also the one operator
  /// that checks for non-finite endpoints: see the class documentation for
  /// why poisoning the axis to null here is enough to keep [operator +]
  /// and [operator *] safe without their own finite checks.
  @override
  SizeEffect operator -(SizeEffect other) => SizeEffect(
        width: _subtractAxis(width, other.width),
        height: _subtractAxis(height, other.height),
      );

  /// Scales width and height by [factor]. A null axis stays null: there is
  /// nothing numeric to scale when the axis means "unconstrained."
  @override
  SizeEffect operator *(double factor) => SizeEffect(
        width: width == null ? null : width! * factor,
        height: height == null ? null : height! * factor,
      );

  /// Combines two axis values under [op], keeping nullability from the
  /// LEFT operand. A null left operand means the result is unconstrained
  /// on that axis; a null right operand contributes nothing, leaving the
  /// left value as-is.
  static double? _addAxis(double? a, double? b) {
    if (a == null) return null;
    if (b == null) return a;
    return a + b;
  }

  /// Subtracts two axis values, preserving a present left value when the
  /// right side is null and poisoning the result to null when the left side
  /// is null or either present side is non-finite. See the class documentation
  /// for why a non-finite pair cannot produce a usable displacement.
  static double? _subtractAxis(double? a, double? b) {
    if (a == null) return null;
    if (b == null) return a;
    if (!a.isFinite || !b.isFinite) return null;
    return a - b;
  }

  /// The squared magnitude of the animatable values, used for settle
  /// detection. Null axes contribute nothing, matching their "no numeric
  /// value" reading everywhere else here. A defensive finite check guards
  /// settle-detection arithmetic even though, by construction, a
  /// displacement built by [operator -] never carries a non-finite axis.
  @override
  double get magnitudeSquared {
    final double w = width ?? 0;
    final double h = height ?? 0;
    return (w.isFinite ? w * w : 0) + (h.isFinite ? h * h : 0);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SizeEffect &&
        other.runtimeType == runtimeType &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => 'SizeEffect(width: $width, height: $height)';
}
