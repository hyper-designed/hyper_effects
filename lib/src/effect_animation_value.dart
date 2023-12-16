import 'package:flutter/widgets.dart';
import 'package:hyper_effects/src/pointer_transition.dart';

/// An inherited widget that provides the animation value to it's descendants.
///
/// This widget is used by [AnimatedEffect], [ScrollTransition], and
/// [PointerTransition] widgets to provide their animation values to their
/// descendants in order to animate them.
class EffectAnimationValue extends InheritedWidget {

  /// The linear animation value. It's value is between 0 and 1.
  final double linearValue;

  /// The animation value. It's value is between 0 and 1, interpolated by the
  /// [Curve] provided.
  final double curvedValue;

  /// Whether the animation is in scroll transition or not. Animations behave
  /// differently in scroll transition. This flag is used to determine the
  /// behavior of the animation.
  final bool isTransition;

  /// Whether the animation should be lerped or not. If set to false, the
  /// animation value is used as is. If set to true, the animation value is
  /// interpolated between 0 and 1.
  final bool lerpValues;

  /// The duration of the animation.
  final Duration duration;

  /// The curve of the animation.
  final Curve curve;

  /// Creates [EffectAnimationValue] widget.
  const EffectAnimationValue({
    super.key,
    required super.child,
    required this.linearValue,
    required this.curvedValue,
    required this.isTransition,
    this.lerpValues = true,
    this.duration = Duration.zero,
    this.curve = Curves.linear,
  });

  @override
  bool updateShouldNotify(covariant EffectAnimationValue oldWidget) {
    return oldWidget.curvedValue != curvedValue ||
        oldWidget.isTransition != isTransition ||
        oldWidget.lerpValues != lerpValues;
  }

  /// Returns the [EffectAnimationValue] from the given [context].
  static EffectAnimationValue of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<EffectAnimationValue>()!;
  }

  /// Returns the [EffectAnimationValue] from the given [context].
  static EffectAnimationValue? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<EffectAnimationValue>();
  }
}
