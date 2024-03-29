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
  ///
  /// The [reverse] parameter is used to determine whether the animation should
  /// play backwards after each repetition.
  ///
  /// The [delay] parameter is used to set a delay before the animation starts.
  ///
  /// The [playIf] parameter is used to determine whether the animation should
  /// be played or skipped. If the callback returns false, the animation will
  /// be skipped, even when it is explicitly triggered.
  ///
  /// The [startImmediately] parameter is used to determine whether the
  /// animation should be triggered immediately when the widget is built,
  /// ignoring the value of [trigger] initially.
  Widget animate({
    required Object? trigger,
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = appleEaseInOut,
    int repeat = 0,
    bool reverse = false,
    bool startImmediately = false,
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
      startImmediately: startImmediately,
      delay: delay,
      onEnd: onEnd,
      playIf: playIf,
      child: this,
    );
  }

  /// Animate the effects applied to this widget after the last animation
  /// in the chain ends.
  ///
  /// Unlike [animate], this method does not trigger the animation immediately
  /// and instead waits for the last animation in the chain to end.
  /// This does not give this effect autonomy over its animations, rather
  /// it stays idle. The last animation that plays will look up the
  /// ancestor tree for the next [AnimatedEffect] and trigger it
  /// manually if `shouldTriggerAfterLast` is true.
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
  ///
  /// The [reverse] parameter is used to determine whether the animation should
  /// play backwards after each repetition.
  ///
  /// The [delay] parameter is used to set a delay before the animation starts.
  ///
  /// The [playIf] parameter is used to determine whether the animation should
  /// be played or skipped. If the callback returns false, the animation will
  /// be skipped, even when it is explicitly triggered.
  Widget animateAfter({
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = appleEaseInOut,
    int repeat = 0,
    bool reverse = false,
    Duration delay = Duration.zero,
    VoidCallback? onEnd,
    BooleanCallback? playIf,
  }) {
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
  ///
  /// The [reverse] parameter is used to determine whether the animation should
  /// play backwards after each repetition.
  ///
  /// The [delay] parameter is used to set a delay before the animation starts.
  ///
  /// The [playIf] parameter is used to determine whether the animation should
  /// be played or skipped. If the callback returns false, the animation will
  /// be skipped, even when it is explicitly triggered.
  ///
  AnimatedEffect oneShot({
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = appleEaseInOut,
    int repeat = 0,
    bool reverse = false,
    Duration delay = Duration.zero,
    VoidCallback? onEnd,
    BooleanCallback? playIf,
  }) {
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

  /// Whether the animation should be triggered immediately when the widget is
  /// built, ignoring the value of [trigger] initially.
  final bool startImmediately;

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
    this.startImmediately = false,
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
  /// Returns whether the animation should be played or skipped based
  /// on the [playIf] callback.
  bool get shouldPlay => widget.playIf?.call() ?? true;

  /// The animation controller that drives the animation.
  late final AnimationController controller = AnimationController(
    vsync: this,
    value: 0,
    duration: widget.duration,
  );

  /// The number of times the animation should be repeated.
  late int repeatTimes = widget.repeat;

  /// Whether the animation should be reversed after each repetition.
  bool shouldReverse = false;

  @override
  void initState() {
    super.initState();

    // If the trigger type is one shot or trigger immediately is true,
    // drive the animation.
    if (widget.triggerType == AnimationTriggerType.oneShot ||
        widget.startImmediately) {
      drive();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    controller.duration = widget.duration;

    // If the trigger value changed, drive the animation.
    if (widget.trigger != oldWidget.trigger) {
      drive();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  /// Handles status changes of the animation controller. This is used to
  /// determine whether the animation should be repeated or not, and whether
  /// the [onEnd] callback should be called.
  ///
  /// If the animation is repeated, it calls [drive] again. If the animation
  /// is not repeated, it calls [onEnd] callback if it is not null.
  ///
  /// In addition, if the animation is not repeated, it looks up the widget
  /// tree for the next [AnimatedEffect] and triggers it manually if the
  /// ancestor's [AnimationTriggerType] is [AnimationTriggerType.afterLast].
  Future<void> onAnimationStatusChanged() async {
    final status = controller.status;
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      widget.onEnd?.call();

      // If repeatTimes is set to -1, repeat the animation indefinitely.
      // If repeatTimes is > 0, we keep repeating the animation until
      // repeatTimes becomes 0.
      if (repeatTimes == -1 || repeatTimes > 0) {
        // Only decrement if the animation is not meant to play forever.
        if (repeatTimes != -1) {
          repeatTimes--;
        }

        // The animation must be repeated, call [drive] again.
        drive();
      } else if (repeatTimes == 0) {
        // If the animation is not repeated and just ended, look up the widget
        // tree for the next [AnimatedEffect] and trigger it manually if the
        // ancestor's [AnimationTriggerType] is
        // [AnimationTriggerType.afterLast].
        final parentState =
            context.findAncestorStateOfType<_AnimatedEffectState>();
        if (parentState != null) {
          final triggerType = parentState.widget.triggerType;
          if (triggerType == AnimationTriggerType.afterLast) {
            // Trigger the next animation.
            await parentState.drive();
          }
        }
        // If instead of an [AnimatedEffect] we find  a
        // [ResetAllAnimationsEffect], reset all animations in the chain.
        else {
          final resetState =
              context.findAncestorStateOfType<_ResetAllAnimationsEffectState>();
          resetState?.reset();
        }
      }
    }
  }

  /// Resets the animation. Called by [ResetAllAnimationsEffect] if
  /// it is found in the widget tree.
  void reset() {
    repeatTimes = widget.repeat;
    controller.reset();
  }

  /// Drives the animation.
  Future<void> drive() async {
    return ensureDelay(() async {
      if (!mounted) return;
      if (!shouldPlay) return;
      if (widget.reverse && shouldReverse) {
        shouldReverse = false;
        await controller.reverse().catchError((err) {
          // ignore
        });
      } else {
        shouldReverse = widget.reverse;
        await controller.forward(from: 0).catchError((err) {
          // ignore
        });
      }

      return onAnimationStatusChanged();
    });
  }

  /// Ensures that the animation is delayed if [widget.delay] is not
  /// [Duration.zero].
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
      animation: controller,
      builder: (context, child) => EffectQuery(
        linearValue: controller.value,
        curvedValue: widget.curve.transform(controller.value),
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
