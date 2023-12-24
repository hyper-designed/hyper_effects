import 'package:flutter/widgets.dart';
import '../hyper_effects.dart';

/// A callback that returns whether an animation should be allowed
/// to follow through with its animation or be skipped completely,
/// even when explicitly triggered.
typedef BooleanCallback = bool Function();

/// Represents the different ways that can trigger an animation.
enum AnimationTriggerType {
  /// The animation is triggered by a [trigger] parameter.
  trigger,

  /// The animation is fired immediately when the widget is built.
  oneShot,

  /// The animation stays idle until the last animation in the chain.
  /// This does not give this effect autonomy over its animations, rather
  /// it stays idle. The last animation that plays will look up the
  /// ancestor tree for the next [AnimatedEffect] and trigger it
  /// manually if `shouldTriggerAfterLast` is true.
  afterLast;
}

/// Provides extension methods for [Widget] to animate it's appearance.
extension AnimatedEffectExt on Widget {
  /// Animate the effects applied to this widget.
  ///
  /// The [trigger] parameter is used to trigger the animation. As long as the
  /// value of [trigger] is the same, the animation will not be triggered again.
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
    required Object? trigger,
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = appleEaseInOut,
    int repeat = 0,
    bool reverse = false,
    Duration delay = Duration.zero,
    VoidCallback? onEnd,
    BooleanCallback? playIf,
  }) {
    return AnimatedEffect(
      triggerType: AnimationTriggerType.trigger,
      trigger: trigger,
      duration: duration,
      curve: curve,
      repeat: repeat,
      reverse: reverse,
      delay: delay,
      onEnd: onEnd,
      playIf: playIf,
      child: this,
    );
  }

  /// Animate the effects applied to this widget after the last animation
  /// in the chain ends.
  Widget animateAfter(
      {Duration duration = const Duration(milliseconds: 350),
      Curve curve = appleEaseInOut,
      int repeat = 0,
      bool reverse = false,
      Duration delay = Duration.zero,
      VoidCallback? onEnd,
      BooleanCallback? playIf}) {
    return AnimatedEffect(
      triggerType: AnimationTriggerType.afterLast,
      trigger: false,
      duration: duration,
      curve: curve,
      repeat: repeat,
      reverse: reverse,
      delay: delay,
      onEnd: onEnd,
      playIf: playIf,
      child: this,
    );
  }

  /// Animate the effects applied to this widget.
  ///
  /// Unlike [animate], this method triggers the animation immediately without
  /// a [trigger] parameter.
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
  AnimatedEffect oneShot(
      {Duration duration = const Duration(milliseconds: 350),
      Curve curve = appleEaseInOut,
      int repeat = 0,
      bool reverse = false,
      Duration delay = Duration.zero,
      VoidCallback? onEnd,
      BooleanCallback? playIf}) {
    return AnimatedEffect(
      triggerType: AnimationTriggerType.oneShot,
      duration: duration,
      curve: curve,
      onEnd: onEnd,
      repeat: repeat,
      reverse: reverse,
      delay: delay,
      playIf: playIf,
      child: this,
    );
  }

  /// Resets all animations in the chain by going down
  /// the children tree and resetting all animations.
  Widget resetAll() => ResetAllAnimationsEffect(child: this);
}

/// A widget that animates the effects applied to it's child.
class AnimatedEffect extends StatefulWidget {
  /// The widget below this widget in the tree.
  final Widget child;

  /// The value used to trigger the animation. As long as the value of [trigger]
  /// is the same, the animation will not be triggered again.
  final Object? trigger;

  /// Defines how the animation is fired.
  final AnimationTriggerType triggerType;

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

  /// A callback that returns whether the animation should be played
  /// or skipped. If the callback returns false, the animation will
  /// be skipped, even when it is explicitly triggered.
  final BooleanCallback? playIf;

  /// Creates [AnimatedEffect] widget.
  const AnimatedEffect({
    super.key,
    required this.child,
    required this.duration,
    required this.triggerType,
    this.trigger,
    this.curve = appleEaseInOut,
    this.onEnd,
    this.repeat = 0,
    this.reverse = false,
    this.delay = Duration.zero,
    this.playIf,
  });

  @override
  State<AnimatedEffect> createState() => _AnimatedEffectState();

  /// Returns the animation value of the nearest [EffectQuery] ancestor.
  /// If there is no ancestor, it returns null.
  EffectQuery? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EffectQuery>();
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

  bool get shouldPlay => widget.playIf?.call() ?? true;

  @override
  void initState() {
    super.initState();

    if (widget.triggerType == AnimationTriggerType.oneShot) {
      drive();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;

    if (widget.trigger != oldWidget.trigger) {
      drive();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> onAnimationStatusChanged() async {
    final status = _controller.status;
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      widget.onEnd?.call();

      if (_repeatTimes == -1 || _repeatTimes > 0) {
        if (_repeatTimes != -1) {
          _repeatTimes--;
        }
        drive();
      } else if (_repeatTimes == 0) {
        // chaining animations
        final parentState =
            context.findAncestorStateOfType<_AnimatedEffectState>();
        if (parentState != null) {
          final triggerType = parentState.widget.triggerType;
          if (triggerType == AnimationTriggerType.afterLast) {
            await parentState.drive();
          }
        } else {
          final resetState =
              context.findAncestorStateOfType<_ResetAllAnimationsEffectState>();
          resetState?.reset();
        }
      }
    }
  }

  void reset() {
    _repeatTimes = widget.repeat;
    _controller.reset();
  }

  Future<void> drive() async {
    return ensureDelay(() async {
      if (!mounted) return;
      if (!shouldPlay) return;
      if (widget.reverse && shouldReverse) {
        shouldReverse = false;
        await _controller.reverse().orCancel;
      } else {
        shouldReverse = widget.reverse;
        await _controller.forward(from: 0).orCancel;
      }

      return onAnimationStatusChanged();
    });
  }

  Future<void> ensureDelay(Future Function() fn) async {
    if (widget.delay == Duration.zero) {
      return fn();
    } else {
      return Future.delayed(widget.delay, fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => EffectQuery(
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

/// Provides the functionality to reset all animations in
/// its child widget tree.
/// This is particularly useful when you want to reset a
/// series of chained animations to their initial state.
class ResetAllAnimationsEffect extends StatefulWidget {
  /// The widget below this widget in the tree.
  final Widget child;

  /// Creates [ResetAllAnimationsEffect] widget.
  const ResetAllAnimationsEffect({super.key, required this.child});

  @override
  State<ResetAllAnimationsEffect> createState() =>
      _ResetAllAnimationsEffectState();
}

class _ResetAllAnimationsEffectState extends State<ResetAllAnimationsEffect> {
  /// Finds the last possible [AnimatedEffect] state in the tree while
  /// resetting all the ones on the way down.
  _AnimatedEffectState? findLeafAnimatedEffectState(BuildContext context) {
    _AnimatedEffectState? result;

    void visitor(Element element) {
      final Widget widget = element.widget;
      if (widget is AnimatedEffect) {
        final StatefulElement editableTextElement = element as StatefulElement;

        result = editableTextElement.state as _AnimatedEffectState;

        // Reset ALL animations in the chain.
        result?.reset();
      }
      element.visitChildren(visitor);
    }

    context.visitChildElements(visitor);
    return result;
  }

  /// Resets all animations in the chain by going down
  /// the children tree and resetting all animations.
  void reset() {
    final state = findLeafAnimatedEffectState(context);
    if (state?.widget.triggerType == AnimationTriggerType.oneShot) {
      state?.drive();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
