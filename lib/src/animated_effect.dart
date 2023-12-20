import 'package:flutter/widgets.dart';
import 'package:hyper_effects/src/apple_curves.dart';

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
  ///
  /// The [onEnd] parameter is used to set a callback that is called when the
  /// animation ends.
  ///
  /// The [repeat] parameter is used to determine how the animation should be
  /// repeated.
  Widget animate({
    required Object? toggle,
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = appleEaseInOut,
    int repeat = 0,
    bool reverse = false,
    Duration delay = Duration.zero,
    VoidCallback? onEnd,
  }) {
    return AnimatedEffect(
      toggle: toggle,
      duration: duration,
      curve: curve,
      repeat: repeat,
      reverse: reverse,
      delay: delay,
      onEnd: onEnd,
      child: this,
    );
  }

  /// Animate the effects applied to this widget.
  ///
  /// Unlike [animate], this method triggers the animation immediately without
  /// a [toggle] parameter.
  ///
  /// The [duration] parameter is used to set the duration of the animation.
  ///
  /// The [curve] parameter is used to set the curve of the animation.
  ///
  /// The [onEnd] parameter is used to set a callback that is called when the
  /// animation ends.
  ///
  /// The [repeat] parameter is used to determine how the animation should be
  /// repeated.
  Widget oneShot({
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = appleEaseInOut,
    int repeat = 0,
    bool reverse = false,
    Duration delay = const Duration(milliseconds: 350),
    VoidCallback? onEnd,
  }) {
    return AnimatedEffect(
      duration: duration,
      curve: curve,
      onEnd: onEnd,
      repeat: repeat,
      reverse: reverse,
      startImmediately: true,
      delay: delay,
      child: this,
    );
  }

  /// Animates the next effects only after the previous effects have finished.
  Widget then(
    BuildContext context, {
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = appleEaseInOut,
    int times = 0,
    bool reverse = false,
    Duration delay = Duration.zero,
  }) {
    // if (this case AnimatedEffect widget) {
    //
    //   return AnimatedEffect(
    //     toggle: null,
    //     duration: duration,
    //     curve: curve,
    //     startImmediately: true,
    //     repeat: times,
    //     reverse: reverse,
    //     startAfter: state?._controller,
    //     child: this,
    //   );
    // }

    return AnimatedEffect(
      toggle: null,
      duration: duration,
      curve: curve,
      startImmediately: true,
      repeat: times,
      reverse: reverse,
      child: this,
    );
  }

  /// Repeats the chain of preceding effects.
  /// [delay] is the delay between each repetition.
  /// [repeat] determines how the animation should be repeated.
  Widget repeat({
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = appleEaseInOut,
    Duration delay = Duration.zero,
    int times = -1,
    bool reverse = false,
  }) {
    return AnimatedEffect(
      toggle: null,
      duration: duration,
      curve: curve,
      startImmediately: true,
      repeat: times,
      reverse: reverse,
      delay: delay,
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

  /// Whether the animation should start immediately as soon as the widget is
  /// built.
  final bool startImmediately;

  /// The duration of the animation.
  final Duration duration;

  /// The curve of the animation.
  final Curve curve;

  /// A callback that is called when the animation ends.
  final VoidCallback? onEnd;

  /// Determines how many times the animation should be repeated.
  final int repeat;

  /// Whether the animation should be reversed after each repetition.
  final bool reverse;

  /// A delay before the animation starts.
  final Duration delay;

  final AnimationController? startAfter;

  /// Creates [AnimatedEffect] widget.
  const AnimatedEffect({
    super.key,
    required this.child,
    required this.duration,
    this.toggle,
    this.startImmediately = false,
    this.curve = appleEaseInOut,
    this.onEnd,
    this.repeat = 0,
    this.reverse = false,
    this.delay = Duration.zero,
    this.startAfter,
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
  late int _repeatTimes = widget.repeat;

  bool shouldReverse = false;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 0,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();

    _controller.addStatusListener(onAnimationStatusChanged);

    if (widget.startImmediately && widget.startAfter == null) {
      forward();
    }

    if (widget.startAfter != null) {
      widget.startAfter!.addStatusListener(startAfterListener);
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;

    if (widget.toggle != oldWidget.toggle) {
      forward();
    }
  }

  @override
  void dispose() {
    widget.startAfter?.removeStatusListener(startAfterListener);
    _controller.removeStatusListener(onAnimationStatusChanged);
    _controller.dispose();
    super.dispose();
  }

  void startAfterListener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      forward();
    }
  }

  void onAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      widget.onEnd?.call();

      if (_repeatTimes == -1 || _repeatTimes > 0) {
        if (_repeatTimes != -1 && (!widget.reverse || !shouldReverse)) {
          _repeatTimes--;
        }
        forward();
      }
    }
  }

  void forward() {
    ensureDelay(() {
      if (!mounted) return;
      if (widget.reverse && shouldReverse) {
        _controller.reverse();
      } else {
        _controller.forward(from: 0);
      }
      shouldReverse = !shouldReverse;
    });
  }

  void ensureDelay(VoidCallback fn) {
    if (widget.delay == Duration.zero) {
      fn();
    } else {
      Future.delayed(widget.delay, fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => EffectAnimationValue(
        linearValue: _controller.value,
        curvedValue: widget.curve.transform(_controller.value),
        isTransition: false,
        duration: widget.duration,
        curve: widget.curve,
        child: child!,
      ),
      child: widget.child,
    );
  }
}
