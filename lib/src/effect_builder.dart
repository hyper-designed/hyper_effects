import 'package:flutter/widgets.dart';

import 'animated_effect.dart';
import 'effects/effect.dart';

class AnimatableEffect extends StatefulWidget {
  final Effect effect;
  final Widget child;

  const AnimatableEffect({
    super.key,
    required this.effect,
    required this.child,
  });

  @override
  State<AnimatableEffect> createState() => AnimatableEffectState();
}

class AnimatableEffectState extends State<AnimatableEffect> {
  late Effect end = widget.effect;
  late Effect begin = widget.effect;

  late double previousAnimationValue = 0;

  EffectAnimationValue? get effectAnimationValue =>
      context.dependOnInheritedWidgetOfExactType<EffectAnimationValue>();

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
    final Effect newEffect = begin.lerp(end, animationValue);
    return newEffect.apply(context, widget.child);
  }
}
