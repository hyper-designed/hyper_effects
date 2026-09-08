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
  /// Throughout the wait the effects are held at the values the run is about
  /// to start from — the delay is dead time, not a preview of the target. A
  /// re-trigger that lands mid-flight therefore freezes wherever it was
  /// interrupted and continues from there once the wait is over. When
  /// [repeat] is set, every repetition waits out its own delay, holding at
  /// the value that repetition begins at.
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
  /// animation as soon as it is added to the widget tree.
  /// [AnimationStartState.lazy], the default, holds the effects at their
  /// starting values until [trigger] changes for the first time.
  /// [AnimationStartState.eager] plays the animation once on mount and then
  /// keeps following [trigger] as usual.
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
  /// method already expresses. To play on mount AND keep a live trigger for
  /// later replays, use `animate(trigger: ..., startState:
  /// AnimationStartState.eager)` instead.
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
  /// Throughout the wait the effects are held at the values the run is about
  /// to start from — the delay is dead time, not a preview of the target.
  /// When [repeat] is set, every repetition waits out its own delay, holding
  /// at the value that repetition begins at.
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
/// Both values insert the widget at its STARTING values. They differ only in
/// whether the animation runs on mount without waiting for a trigger change.
enum AnimationStartState {
  /// The widget is inserted at its STARTING values and immediately plays
  /// through to its ending values, once per [State] lifetime. Rebuilds do not
  /// replay it.
  ///
  /// The [AnimatedEffect.trigger] stays live: every subsequent change of it
  /// plays the animation again, exactly as it would under [lazy]. This is the
  /// difference from `trigger: #immediate`, which pins the trigger to a
  /// sentinel whose identity never changes and therefore never replays.
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
  /// to the widget tree. [AnimationStartState.eager] plays the animation once
  /// on mount; [AnimationStartState.lazy] waits for the first [trigger]
  /// change.
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
  ///
  /// The wait is dead time, not a preview of where the animation is going:
  /// the internal controller is parked at the value the upcoming run starts
  /// from before the wait begins, so the effects hold at their starting
  /// values for the full delay and only then move. A re-trigger that lands
  /// mid-flight freezes at the position it interrupted and resumes from
  /// there.
  ///
  /// With [repeat], each repetition waits out this delay in turn, holding at
  /// the value that leg begins at — 1 for a [reverse] leg, the start value
  /// for a forward one.
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
    value: shouldSkip ? 1 : 0,
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

  /// Identifies the newest interruptable logical run.
  ///
  /// [Future.delayed] cannot be cancelled. Every fresh interruptable trigger
  /// advances this generation instead, so an older delayed callback can wake,
  /// see that it no longer owns the animation, and retire without touching the
  /// controller. Repetitions inherit their logical run's generation rather
  /// than advancing it, while non-interruptable runs deliberately ignore this
  /// token and retain their serialized wait-on-[driveFuture] behavior.
  int _driveGeneration = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (didPlay) return;

    // Both the `#immediate` sentinel and [AnimationStartState.eager] play on
    // mount, once per State lifetime. They differ in what happens afterwards:
    // `#immediate` pins the trigger to a sentinel whose identity never
    // changes, so it can never replay, while `eager` leaves the caller's
    // trigger live and plays again on every subsequent change of it.
    if (widget.trigger == #immediate ||
        widget.startState == AnimationStartState.eager) {
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
  Future<void> onAnimationStatusChanged(int? generation) async {
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

        // A repetition is another cycle of this same logical run. Awaiting it
        // here keeps a non-interruptable run's [driveFuture] pending until its
        // full repeat/reverse budget is exhausted, so later queued triggers
        // cannot overlap one of its repetitions.
        return _driveNow(generation);
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
    _driveGeneration++;
    controller.reset();
  }

  /// Drives the animation.
  ///
  /// A fresh interruptable invocation starts a new logical run and supersedes
  /// every older one. A repetition passes its existing [generation] back in,
  /// because it is another leg of the same run rather than a competing run.
  /// Non-interruptable invocations do not use generations: each one attaches
  /// itself to [driveFuture] immediately, preserving their serialized order.
  Future<void> drive({int? generation}) {
    if (!widget.interruptable) {
      final previous = driveFuture;
      final future = _driveAfter(previous);
      driveFuture = future;
      return future;
    }

    final currentGeneration = generation ?? ++_driveGeneration;
    final future = _driveNow(currentGeneration);
    driveFuture = future;
    return future;
  }

  /// Waits for the preceding non-interruptable cycle before starting this one.
  Future<void> _driveAfter(Future<void>? previous) async {
    if (previous != null) {
      await previous;
      if (!mounted) return;
    }
    return _driveNow(null);
  }

  /// Runs one animation cycle.
  ///
  /// A non-null [generation] belongs to an interruptable logical run. The
  /// generation is checked at every asynchronous resume point so an obsolete
  /// delay or a controller future cancelled by a newer trigger cannot restart
  /// the animation, consume its repeat budget, or call [AnimatedEffect.onEnd].
  Future<void> _driveNow(int? generation) async {
    bool isCurrentRun() => generation == null || generation == _driveGeneration;

    // Park the controller at the value the upcoming run will start from,
    // BEFORE the delay window opens.
    //
    // A delay defers the controller's start, but on its own it does not
    // rewind the controller: through the whole wait, the controller keeps
    // reporting whatever the PREVIOUS run left it at — 1 after a completed
    // forward leg. Meanwhile the descendant [EffectWidget]s have already
    // folded that finished run into their `start` and adopted the new `end`,
    // so their `start.lerp(end, curvedValue)` evaluates at 1 and paints the
    // NEW TARGET instantly. The effect flashes its destination, holds it for
    // the length of the delay, snaps back to the start value, and only then
    // animates. The very first run of any effect hides this, because a
    // controller that has never run already rests at 0 — which is why the bug
    // only shows up from the second run onward.
    //
    // The parked value must mirror the branch below that chooses between
    // `reverse()` (which runs 1 -> 0) and `forward(from: 0)`, so a delayed
    // reverse leg holds at its own start of 1 rather than snapping to 0.
    //
    // Only park a run that is actually going to play. `playIf` returning
    // false makes the body below return without touching the controller at
    // all, and `skipIf` returning true makes it jump straight to 1; rewinding
    // the controller for either would be a visible reset for an animation
    // that never runs — the same class of glitch this is fixing.
    if (widget.delay != Duration.zero && shouldPlay && !shouldSkip) {
      controller.value = (widget.reverse && shouldReverse) ? 1 : 0;
    }

    await ensureDelay(() async {
      if (!mounted || !isCurrentRun()) return;
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

      if (!mounted || !isCurrentRun()) return;
      return onAnimationStatusChanged(generation);
    });
    if (!mounted || !isCurrentRun()) return;
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
