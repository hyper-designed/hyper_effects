import 'package:flutter/widgets.dart';

import '../hyper_effects.dart';
import 'utils.dart';

/// A callback that returns whether an animation should be allowed
/// to follow through with its animation or be skipped completely,
/// even when explicitly triggered.
typedef BooleanCallback = bool Function();

/// Provides extension methods for [Widget] to animate it's appearance.
extension AnimatedEffectExt on Widget? {
  /// Animate the effects applied to this widget.
  ///
  /// The [trigger] parameter is used to trigger the animation. As long as the
  /// value of [trigger] is the same, the animation will not be triggered again.
  ///
  /// Passing the sentinel `#immediate` as the [trigger] plays the animation
  /// as soon as it is mounted, once per State lifetime. Rebuilds do not
  /// replay it, since the sentinel's identity never changes. [immediate] is
  /// a shorthand for exactly this.
  ///
  /// The [key] parameter is forwarded to the underlying [AnimatedEffect].
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
  /// The [resetValues] parameter is used to determine whether the animation
  /// should start from idle values or from the current state of the widget.
  ///
  /// The [interruptable] parameter is used to determine how a re-trigger is
  /// handled while an animation is still in flight. When true (the default),
  /// the in-flight animation is interrupted and re-driven from the beginning
  /// right away. When false, the new run waits for the in-flight one to
  /// finish before it starts.
  ///
  /// The [startState] parameter is used to determine the behavior of the
  /// animation as soon as it is added to the widget tree. See
  /// [AnimationStartState.eager] and [AnimationStartState.lazy].
  ///
  /// The [playIf] parameter is used to determine whether the animation should
  /// be played or skipped. If the callback returns false, the animation will
  /// be skipped, even when it is explicitly triggered.
  ///
  /// The [skipIf] parameter is used to determine whether the animation should
  /// be skipped by setting the animation value to 1, effectively skipping the
  /// animation to the ending values.
  Widget animate({
    required Object? trigger,
    Key? key,
    Duration? duration,
    Curve? curve,
    Motion? motion,
    int repeat = 0,
    bool reverse = false,
    bool resetValues = false,
    bool interruptable = true,
    Duration delay = Duration.zero,
    AnimationStartState startState = AnimationStartState.lazy,
    VoidCallback? onEnd,
    BooleanCallback? playIf,
    BooleanCallback? skipIf,
    AnimationBehavior? animationBehavior,
  }) {
    return AnimatedEffect(
      key: key,
      trigger: trigger,
      motion: Utils.resolveMotion(motion, duration, curve),
      repeat: repeat,
      reverse: reverse,
      resetValues: resetValues,
      interruptable: interruptable,
      delay: delay,
      startState: startState,
      onEnd: onEnd,
      playIf: playIf,
      skipIf: skipIf,
      animationBehavior: animationBehavior,
      child: this,
    );
  }

  /// Animate the effects applied to this widget.
  ///
  /// Unlike [animate], this method takes no [trigger]: it plays the animation
  /// as soon as it is mounted, once per [State] lifetime. It is shorthand for
  /// `animate(trigger: #immediate)`, and since the sentinel's identity never
  /// changes, rebuilds do not replay it.
  ///
  /// There is no `startState` parameter here: play-on-mount is what this
  /// method already expresses.
  ///
  /// The [key] parameter is forwarded to the underlying [AnimatedEffect].
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
  /// The [resetValues] parameter is used to determine whether the animation
  /// should start from idle values or from the current state of the widget.
  /// If set to true, the animation will always animate from the initial
  /// default state of an effect towards the current state.
  /// When false, the animation will animate from the previous effect state
  /// towards the current state.
  ///
  /// The [interruptable] parameter is used to determine how a re-trigger is
  /// handled while an animation is still in flight. When true (the default),
  /// the in-flight animation is interrupted and re-driven from the beginning
  /// right away. When false, the new run waits for the in-flight one to
  /// finish before it starts.
  ///
  /// The [delay] parameter is used to set a delay before the animation starts.
  ///
  /// The [playIf] parameter is used to determine whether the animation should
  /// be played or skipped. If the callback returns false, the animation will
  /// be skipped, even when it is explicitly triggered.
  ///
  /// The [skipIf] parameter is used to determine whether the animation should
  /// be skipped by setting the animation value to 1, effectively skipping the
  /// animation to the ending values.
  AnimatedEffect immediate({
    Key? key,
    Duration? duration,
    Curve? curve,
    Motion? motion,
    int repeat = 0,
    bool reverse = false,
    bool resetValues = false,
    bool interruptable = true,
    Duration delay = Duration.zero,
    VoidCallback? onEnd,
    BooleanCallback? playIf,
    BooleanCallback? skipIf,
    AnimationBehavior? animationBehavior,
  }) {
    return AnimatedEffect(
      key: key,
      trigger: #immediate,
      motion: Utils.resolveMotion(motion, duration, curve),
      onEnd: onEnd,
      repeat: repeat,
      reverse: reverse,
      resetValues: resetValues,
      interruptable: interruptable,
      delay: delay,
      playIf: playIf,
      skipIf: skipIf,
      animationBehavior: animationBehavior,
      child: this,
    );
  }

  /// Resets all animations in the chain by going down
  /// the children tree and resetting all animations.
  @Deprecated(
    'Auto-resetting chains fire on every completion and cross-talk between '
    'unrelated animations. Loop with .timeline(repeat:) or rewind with '
    'TimelineController.seek(0) instead. Will be removed in 0.5.0.',
  )
  // ignore: deprecated_member_use_from_same_package
  Widget resetAll() => ResetAllAnimationsEffect(child: this);
}

/// Determines the behavior of the [AnimatedEffect] as soon as it is added
/// to the widget tree.
///
/// Neither value plays an animation on mount. To play on mount, pass
/// `trigger: #immediate` (or use `immediate()`).
enum AnimationStartState {
  /// The widget is inserted with its effects already applied at their ENDING
  /// values: the internal controller starts at 1 rather than 0.
  ///
  /// Nothing animates on insertion — the end state is simply what the widget
  /// looks like from its very first frame. The next trigger interpolates from
  /// there towards the then-current effect values.
  eager,

  /// The widget is inserted inert, with its effects held at their STARTING
  /// values: the internal controller starts at 0.
  ///
  /// Nothing animates until the animation is triggered at least once.
  lazy;
}

/// A widget that animates the effects applied to it's child.
class AnimatedEffect extends StatefulWidget {
  /// The widget below this widget in the tree.
  final Widget? child;

  /// The value used to trigger the animation. As long as the value of [trigger]
  /// is the same, the animation will not be triggered again.
  ///
  /// The sentinel `#immediate` plays the animation as soon as it mounts, once
  /// per [State] lifetime.
  final Object? trigger;

  /// Determines the behavior of this [AnimatedEffect] as soon as it is added
  /// to the widget tree.
  final AnimationStartState startState;

  /// How the animation moves: a [CurvedMotion] built from the
  /// duration/curve sugar, or any [Motion] (springs included).
  final Motion motion;

  /// A callback that is called when the animation ends.
  final VoidCallback? onEnd;

  /// Determines how many times the animation should be repeated.
  final int repeat;

  /// Whether the animation should be reversed after each repetition.
  final bool reverse;

  /// Normally, an effect represents the current state of the widget and this
  /// animate effect is only in charge of lerping between states of those
  /// effect values.
  /// If this is set to true, instead of treating effects as current states
  /// to animate between, it will always animate from an initial default
  /// state towards the current state.
  final bool resetValues;

  /// How a re-trigger is handled while an animation is still in flight.
  ///
  /// When true (the default), the in-flight animation is interrupted and
  /// re-driven from the beginning right away. When false, the new run waits
  /// for the in-flight one to finish before it starts.
  final bool interruptable;

  /// A delay before the animation starts.
  final Duration delay;

  /// A callback that returns whether the animation should be played
  /// or skipped. If the callback returns false, the animation will
  /// be skipped, even when it is explicitly triggered.
  final BooleanCallback? playIf;

  /// A callback that determines whether the animation should be skipped by
  /// setting the animation value to 1, effectively skipping the animation to
  /// the ending values.
  final BooleanCallback? skipIf;

  /// The behavior of the controller when
  /// [AccessibilityFeatures.disableAnimations] is true.
  final AnimationBehavior? animationBehavior;

  /// Creates [AnimatedEffect] widget.
  const AnimatedEffect({
    super.key,
    required this.child,
    this.motion =
        const CurvedMotion(Duration(milliseconds: 350), appleEaseInOut),
    this.startState = AnimationStartState.lazy,
    this.trigger,
    this.onEnd,
    this.repeat = 0,
    this.reverse = false,
    this.resetValues = false,
    this.interruptable = true,
    this.delay = Duration.zero,
    this.playIf,
    this.skipIf,
    this.animationBehavior,
  });

  @override
  State<AnimatedEffect> createState() => AnimatedEffectState();

  /// Returns the animation value of the nearest [EffectQuery] ancestor.
  /// If there is no ancestor, it returns null.
  EffectQuery? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EffectQuery>();
}

/// The state of [AnimatedEffect].
class AnimatedEffectState extends State<AnimatedEffect>
    with SingleTickerProviderStateMixin {
  /// Tracks whether the animation has played or not.
  bool didPlay = false;

  /// Returns whether the animation should be played or skipped based
  /// on the [playIf] callback.
  bool get shouldPlay => widget.playIf?.call() ?? true;

  /// Returns whether the animation should be skipped based on the [skipIf]
  /// callback.
  bool get shouldSkip => widget.skipIf?.call() ?? false;

  /// The animation controller that drives the animation.
  late final AnimationController controller = AnimationController(
    vsync: this,
    value: widget.startState == AnimationStartState.eager || shouldSkip ? 1 : 0,
    duration: widget.motion.effectiveDuration,
    animationBehavior: widget.animationBehavior ??
        HyperEffectsAnimationConfig.maybeOf(context)?.animationBehavior ??
        AnimationBehavior.normal,
  );

  /// The number of times the animation should be repeated.
  late int repeatTimes = widget.repeat;

  /// Whether the animation should be reversed after each repetition.
  bool shouldReverse = false;

  /// A future that represents a single animation cycle.
  Future<void>? driveFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (didPlay) return;

    // The `#immediate` sentinel plays on mount, once per State lifetime.
    if (widget.trigger == #immediate) {
      drive();
      didPlay = true;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    controller.duration = widget.motion.effectiveDuration;

    // If the trigger value changed, drive the animation.
    if (widget.trigger != oldWidget.trigger) {
      repeatTimes = widget.repeat;
      shouldReverse = false;
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
  /// In addition, once the run is truly over, it notifies the nearest
  /// deprecated `ResetAllAnimationsEffect` ancestor, if any, so that it can
  /// reset the animations below it.
  Future<void> onAnimationStatusChanged() async {
    final status = controller.status;
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
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
        if (!mounted) return;

        widget.onEnd?.call();

        final resetState =
            context.findAncestorStateOfType<ResetAllAnimationsEffectState>();
        resetState?.reset();
      }
    }
  }

  /// Resets the animation. Called by [ResetAllAnimationsEffect] if
  /// it is found in the widget tree.
  void reset() {
    repeatTimes = widget.repeat;
    driveFuture = null;
    controller.reset();
  }

  /// Drives the animation.
  Future<void> drive() async {
    if (!widget.interruptable && driveFuture != null) {
      await driveFuture;
    }

    return driveFuture = ensureDelay(() async {
      if (!mounted) return;
      if (!shouldPlay) return;
      if (shouldSkip) {
        controller.value = 1;
        return;
      }
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
        curvedValue: widget.motion.transform(controller.value),
        motion: widget.motion,
        isTransition: false,
        resetValues: widget.resetValues,
        duration: widget.motion.effectiveDuration,
        curve: switch (widget.motion) {
          CurvedMotion(:final curve) => curve,
          _ => Curves.linear,
        },
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
@Deprecated(
  'Auto-resetting chains fire on every completion and cross-talk between '
  'unrelated animations. Loop with .timeline(repeat:) or rewind with '
  'TimelineController.seek(0) instead. Will be removed in 0.5.0.',
)
class ResetAllAnimationsEffect extends StatefulWidget {
  /// The widget below this widget in the tree.
  final Widget? child;

  /// Creates [ResetAllAnimationsEffect] widget.
  const ResetAllAnimationsEffect({super.key, required this.child});

  @override
  State<ResetAllAnimationsEffect> createState() =>
      ResetAllAnimationsEffectState();
}

/// The state of [ResetAllAnimationsEffect].
@Deprecated(
  'Deprecated along with ResetAllAnimationsEffect. '
  'Will be removed in 0.5.0.',
)
// ignore: deprecated_member_use_from_same_package
class ResetAllAnimationsEffectState extends State<ResetAllAnimationsEffect> {
  /// Finds the last possible [AnimatedEffect] state in the tree while
  /// resetting all the ones on the way down.
  AnimatedEffectState? findLeafAnimatedEffectState(BuildContext context) {
    AnimatedEffectState? result;

    void visitor(Element element) {
      final Widget widget = element.widget;
      if (widget is AnimatedEffect) {
        final StatefulElement animatedEffectEl = element as StatefulElement;

        result = animatedEffectEl.state as AnimatedEffectState;

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

    // Once resetting is complete, re-drive `#immediate` animations, which
    // would otherwise never play again for the lifetime of their State.
    if (state?.widget.trigger == #immediate) {
      state?.drive();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child ?? const SizedBox.shrink();
}
