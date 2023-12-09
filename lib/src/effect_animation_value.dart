import 'package:flutter/widgets.dart';
import 'package:hyper_effects/src/pointer_transition.dart';

/// An inherited widget that provides the animation value to it's descendants.
///
/// This widget is used by [AnimatedEffect], [ScrollTransition], and
/// [PointerTransition] widgets to provide their animation values to their
/// descendants in order to animate them.
class EffectAnimationValue extends InheritedWidget {
  /// The animation value. It's value is between 0 and 1.
  final double value;

  /// Whether the animation is in scroll transition or not. Animations behave
  /// differently in scroll transition. This flag is used to determine the
  /// behavior of the animation.
  final bool isTransition;

  /// Whether the animation should be lerped or not. If set to false, the
  /// animation value is used as is. If set to true, the animation value is
  /// interpolated between 0 and 1.
  final bool lerpValues;

  /// Creates [EffectAnimationValue] widget.
  const EffectAnimationValue({
    super.key,
    required super.child,
    required this.value,
    required this.isTransition,
    this.lerpValues = true,
  });

  @override
  bool updateShouldNotify(covariant EffectAnimationValue oldWidget) {
    return oldWidget.value != value ||
        oldWidget.isTransition != isTransition ||
        oldWidget.lerpValues != lerpValues;
  }
}
