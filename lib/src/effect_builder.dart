import 'package:flutter/widgets.dart';

import 'effect_animation_value.dart';
import 'effects/effect.dart';

/// A widget that applies given [Effect] to a [Widget]. This widget is hardly
/// used directly. Instead, use the extension methods provided by the effects
/// to apply them to a [Widget].
///
/// This widget does a parent lookup to find the [EffectAnimationValue] widget
/// to get the animation value. If no [EffectAnimationValue] is found, the
/// animation value is 1.
///
/// If an animation value is found, the [Effect.lerp] method is called to
/// interpolate between two [Effect]s. The resulting [Effect] is then applied
/// to the [child] by calling [Effect.apply].
class AnimatableEffect extends StatefulWidget {
  /// The effect to apply to the [child].
  final Effect effect;

  /// The [Widget] to apply the [effect] to.
  final Widget child;

  /// Creates an [AnimatableEffect].
  const AnimatableEffect({
    super.key,
    required this.effect,
    required this.child,
  });

  @override
  State<AnimatableEffect> createState() => _AnimatableEffectState();
}

class _AnimatableEffectState extends State<AnimatableEffect> {
  late Effect end = widget.effect;
  late Effect begin = widget.effect;

  /// caches the previous animation value to use in didUpdateWidget
  /// to calculate the begin value. This is used to create a smooth transition
  /// between two [Effect]s when the [Effect] changes mid animation.
  late double previousAnimationValue = 0;

  /// Pulls the parent [EffectAnimationValue] inherited widget.
  EffectAnimationValue? get effectAnimationValue =>
      context.dependOnInheritedWidgetOfExactType<EffectAnimationValue>();

  /// Pulls the animation value from the parent [EffectAnimationValue] widget.
  double get animationValue =>
      context
          .dependOnInheritedWidgetOfExactType<EffectAnimationValue>()
          ?.value ??
      1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    previousAnimationValue = animationValue;
  }

  @override
  void didUpdateWidget(covariant AnimatableEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.effect != widget.effect) {
      if (effectAnimationValue != null && !effectAnimationValue!.isTransition) {
        begin = begin.lerp(end, previousAnimationValue);
      }
      end = widget.effect;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (effectAnimationValue?.lerpValues == false) {
      return end.apply(context, widget.child);
    } else {
      final Effect newEffect = begin.lerp(end, animationValue);
      return newEffect.apply(context, widget.child);
    }
  }
}
