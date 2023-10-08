import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

/// An [Effect] that can be applied to a [Widget]. This is the base class for
/// all effects.
///
/// Effects define how a [Widget] should be transformed. For example, a
/// [ScaleEffect] defines how a [Widget] should be scaled.
///
/// [AnimatableEffect] takes an [Effect] and applies it to a [Widget].
///
/// An effect can be animated by parent [AnimatedEffect] or [ScrollTransition].
/// An animation value is passed to [Effect.lerp] method. This value is
/// interpolated by the parent [AnimatedEffect] or [ScrollTransition]
/// depending on the [Curve] provided to them.
///
/// If no parent [AnimatedEffect] or [ScrollTransition] is provided, the
/// animation value is 0.
abstract class Effect with EquatableMixin {
  /// Creates an [Effect].
  const Effect();

  /// Linearly interpolates between two [Effect]s. This is used to animate
  /// between two [Effect]s. The [value] argument is a fraction that
  /// determines the position of this effect between [this] and [other].
  ///
  /// If a [Curve] is provided to the parent [AnimatableEffect], the [value]
  /// will be interpolated by the [Curve]. Otherwise, the [value] will be
  /// interpolated linearly.
  ///
  /// The implementation should return [this] if [value] is 0.0 and [other]
  /// if [value] is 1.0. Otherwise, returns an [Effect] that is a combination
  /// of [this] and [other] by interpolating between them.
  ///
  /// If no parent [AnimatableEffect] or [ScrollTransition] is provided, then
  /// this method is called with [other] being the same as [this] effectively
  /// nullifying the effect.
  ///
  /// Check out [ScaleEffect.lerp] for an example of how to implement this
  /// method.
  ///
  /// Returns a new [Effect] that is a combination of [this] and [other]. This
  /// returned [Effect] is then applied to the [Widget] by calling [apply].
  Effect lerp(covariant Effect other, double value);

  /// Applies this [Effect] to given [child]. This is called by Effect builder
  /// widgets to apply the effect to given [child].
  ///
  /// Returns a [Widget] with the effect applied. [lerp] is called before
  /// [apply] to interpolate between two [Effect]s. [apply] is then called
  /// on the resulting [Effect] from [lerp].
  ///
  /// Check out [ScaleEffect.apply] for an example of how to implement this
  /// method.
  Widget apply(BuildContext context, Widget child);
}
