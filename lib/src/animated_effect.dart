import 'package:flutter/widgets.dart';
import 'package:hyper_effects/src/apple_curve.dart';

import 'effect_animation_value.dart';

/// Provides extension methods for [Widget] to animate it's appearance.
extension AnimatedEffectExt on Widget {
  /// Animate the effects applied to this widget.
  ///
  /// The [toggle] parameter is used to trigger the animation. As long as the
  /// value of [toggle] is the same, the animation will not be triggered again.
  ///
  /// The [duration] parameter is used to set the duration of the animation.
  ///
  /// The [curve] parameter is used to set the curve of the animation.
  Widget animate({
    required Object? toggle,
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = appleEaseInOut,
  }) {
    return AnimatedEffect(
      toggle: toggle,
      duration: duration,
      curve: curve,
      child: this,
    );
  }
}

/// A widget that animates the effects applied to it's child.
class AnimatedEffect extends StatefulWidget {
  /// The widget below this widget in the tree.
  final Widget child;

  /// The value used to trigger the animation. As long as the value of [toggle]
  /// is the same, the animation will not be triggered again.
  final Object? toggle;

  /// The duration of the animation.
  final Duration duration;

  /// The curve of the animation.
  final Curve curve;

  /// Creates [AnimatedEffect] widget.
  const AnimatedEffect({
    super.key,
    required this.child,
    required this.toggle,
    required this.duration,
    this.curve = appleEaseInOut,
  });

  @override
  State<AnimatedEffect> createState() => _AnimatedEffectState();

  /// Returns the animation value of the nearest [EffectAnimationValue] ancestor.
  /// If there is no ancestor, it returns null.
  EffectAnimationValue? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EffectAnimationValue>();
}

class _AnimatedEffectState extends State<AnimatedEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 1,
    duration: widget.duration,
  );

  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: widget.curve,
  );

  @override
  void didUpdateWidget(covariant AnimatedEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.toggle != oldWidget.toggle) _controller.forward(from: 0);
    _controller.duration = widget.duration;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => EffectAnimationValue(
        value: _animation.value,
        isTransition: false,
        child: child!,
      ),
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
