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

/// An effect that aligns a [Widget] by a given [alignment], optionally
/// sizing it to a factor of its child.
///
/// [AlignEffect] is a [VectorEffect], so an alignment animation gets real
/// spring overshoot and carries its momentum across a mid-flight retarget
/// instead of restarting from rest. The alignment itself vectorizes
/// cleanly: [AlignmentGeometry] already defines addition
/// ([AlignmentGeometry.add]), negation and scaling, and defines them ACROSS
/// the [Alignment] / [AlignmentDirectional] divide, so the two endpoints of
/// an animation are never required to agree on a runtime type.
///
/// ## Why the size factors are the awkward part
///
/// A null [widthFactor] does not mean "zero" — it means "fill the incoming
/// constraints", which is a different layout mode rather than a smaller
/// number. There is no arithmetic between a mode and a number, so
/// nullability is treated as CONFIGURATION and rides along from the LEFT
/// operand, exactly as [VectorEffect] prescribes for fields that are not
/// animatable:
///
/// * both operands carry a factor — the numbers combine, and the factor
///   animates like any other scalar;
/// * neither carries one — the result carries none;
/// * only the left carries one — its value passes through unchanged,
///   because there is nothing numeric on the right to combine it with.
///
/// That asymmetry is deliberate, and it lands on the documented behaviour
/// rather than beside it. The spring solver builds every intermediate state
/// as `target + displacement * coefficient`, with the TARGET as the left
/// operand, so a mixed null / non-null pair resolves to the target's mode
/// on the very first frame — which is precisely the snap-to-target rule
/// [lerp] has always applied, reached by a different route. The two paths
/// agreeing is a behavioural contract, not a coincidence, and
/// `test/align_effect_vector_test.dart` pins it.
///
/// ## Where the clamping lives
///
/// [RenderPositionedBox] asserts `widthFactor == null || widthFactor >= 0`,
/// so a factor that overshoots below zero is floored in [apply], where the
/// value becomes layout and the assert applies. [lerp] keeps its own floor
/// as well: unlike a clamp on the interpolation PARAMETER, flooring the
/// RESULT at zero destroys nothing, because a negative factor is not a
/// value the layout can express in the first place. Overshoot above the
/// target is untouched on both paths.
///
/// [alignment] needs no guard at all. Values outside the -1..1 box are
/// meaningful to [Align] — they simply place the child past the edge — and
/// they are what makes a bouncy `.alignX()` actually bounce.
class AlignEffect extends Effect with VectorEffect<AlignEffect> {
  /// The alignment by which the [Widget] is aligned.
  ///
  /// Mid-flight this may hold values outside the animation's endpoints;
  /// that overshoot is intentional and is passed straight through to
  /// [Align].
  final AlignmentGeometry alignment;

  /// Sets its width to the child's width multiplied by this factor.
  /// If null, the widget expands to fill its incoming width constraints,
  /// matching the default behavior of [Align].
  ///
  /// Null and non-null are different layout modes, not different numbers:
  /// see the class documentation for how a mixed pair resolves.
  final double? widthFactor;

  /// Sets its height to the child's height multiplied by this factor.
  /// If null, the widget expands to fill its incoming height constraints,
  /// matching the default behavior of [Align].
  ///
  /// Null and non-null are different layout modes, not different numbers:
  /// see the class documentation for how a mixed pair resolves.
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

  /// Combines two factors under [op], keeping nullability from the LEFT
  /// operand.
  ///
  /// A null left operand means the result has no numeric factor at all; a
  /// null right operand contributes nothing, leaving the left value as-is.
  /// See the class documentation for why this is the right shape.
  static double? _combineFactor(
    double? a,
    double? b,
    double Function(double a, double b) op,
  ) {
    if (a == null) return null;
    if (b == null) return a;
    return op(a, b);
  }

  /// Builds the [Align], flooring any factor that overshot below zero.
  ///
  /// [RenderPositionedBox] asserts non-negative factors, so this is a hard
  /// requirement rather than a stylistic one — and it is the only place the
  /// requirement applies, because it is the only place the value becomes
  /// layout. [alignment] is passed through untouched, overshoot included.
  @override
  Widget apply(BuildContext context, Widget? child) {
    return Align(
      alignment: alignment,
      widthFactor: _floorFactor(widthFactor),
      heightFactor: _floorFactor(heightFactor),
      child: child,
    );
  }

  /// Floors a factor at zero while preserving null, which is a layout mode
  /// rather than a number and must never be turned into one.
  static double? _floorFactor(double? value) {
    if (value == null) return null;
    return value < 0 ? 0 : value;
  }

  @override
  AlignEffect idle() => AlignEffect();

  /// Field-wise sum. The alignments add through
  /// [AlignmentGeometry.add], which spans absolute and directional forms;
  /// the factors follow the nullability rule in the class documentation.
  @override
  AlignEffect operator +(AlignEffect other) => AlignEffect(
        alignment: alignment.add(other.alignment),
        widthFactor: _combineFactor(widthFactor, other.widthFactor, _add),
        heightFactor: _combineFactor(heightFactor, other.heightFactor, _add),
      );

  /// Field-wise difference. [AlignmentGeometry] declares no binary `-`, so
  /// this is expressed as `a.add(-b)`, which is the same thing and works
  /// for every subtype. Routinely produces negative factors: this is the
  /// displacement term of the spring solution, not a renderable state.
  @override
  AlignEffect operator -(AlignEffect other) => AlignEffect(
        alignment: alignment.add(-other.alignment),
        widthFactor: _combineFactor(widthFactor, other.widthFactor, _subtract),
        heightFactor:
            _combineFactor(heightFactor, other.heightFactor, _subtract),
      );

  /// Scales the alignment and any present factors by [factor]. A null
  /// factor stays null: "fill the constraints" has nothing to scale.
  @override
  AlignEffect operator *(double factor) => AlignEffect(
        alignment: alignment * factor,
        widthFactor: widthFactor == null ? null : widthFactor! * factor,
        heightFactor: heightFactor == null ? null : heightFactor! * factor,
      );

  /// The squared magnitude of the animatable values, used for settle
  /// detection.
  ///
  /// [AlignmentGeometry] keeps its components private, so the alignment is
  /// read through [AlignmentGeometry.resolve] with a left-to-right
  /// direction; for the purely absolute and purely directional forms the
  /// choice is immaterial, and settle detection only needs a scalar that
  /// vanishes with the vector. Null factors contribute nothing, matching
  /// their "no numeric value" reading everywhere else here.
  @override
  double get magnitudeSquared {
    final Alignment resolved = alignment.resolve(TextDirection.ltr);
    final double width = widthFactor ?? 0;
    final double height = heightFactor ?? 0;
    return resolved.x * resolved.x +
        resolved.y * resolved.y +
        width * width +
        height * height;
  }

  static double _add(double a, double b) => a + b;

  static double _subtract(double a, double b) => a - b;

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
