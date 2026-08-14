import 'dart:async';

import 'package:flutter/widgets.dart';

import '../effects/effect.dart';
import 'timeline_controller.dart';
import 'timeline_spec.dart';

/// Provides the entry point that turns a declarative effect/step chain into
/// a running timeline.
extension TimelineEffectExt on Widget {
  /// Compiles the effect/[TimelineChainExt.step] chain this is called on
  /// into a single-controller timeline and plays it on [trigger] changes.
  ///
  /// Unlike `animate`, every effect in the chain is a keyframe VALUE on a
  /// shared timeline — values are absolute and hand off between keyframes,
  /// they do not stack.
  ///
  /// A [trigger] is purely an identity signal: any change restarts the
  /// timeline from the beginning and plays it forward. It never implies a
  /// direction. For directional or positional control — reversing, pausing,
  /// seeking, scrubbing — attach a [TimelineController] instead.
  ///
  /// Passing the sentinel `#immediate` as the [trigger] plays the timeline
  /// as soon as it is mounted — once per State lifetime, since rebuilds do
  /// not change the sentinel's identity. Combined with [repeat] this
  /// expresses auto-playing and looping timelines without any imperative
  /// code.
  Widget timeline({
    Object? trigger,
    TimelineController? controller,
    VoidCallback? onEnd,
    int repeat = 0,
  }) =>
      TimelineEffect(
        trigger: trigger,
        controller: controller,
        onEnd: onEnd,
        repeat: repeat,
        chain: this,
      );
}

/// A widget that drives a compiled [TimelineSpec] with a single
/// [AnimationController].
class TimelineEffect extends StatefulWidget {
  /// The declarative effect/step chain to compile.
  final Widget chain;

  /// An identity signal: any change restarts the timeline from the
  /// beginning, playing forward. Direction is never inferred from the
  /// trigger's value; use a [controller] for directional control.
  ///
  /// The sentinel `#immediate` plays the timeline as soon as it mounts,
  /// once per State lifetime.
  final Object? trigger;

  /// An optional external handle for driving this timeline imperatively.
  final TimelineController? controller;

  /// Called when the timeline completes in either direction.
  final VoidCallback? onEnd;

  /// How many ADDITIONAL times a run plays after its first cycle: 0 plays
  /// once, 2 plays three cycles, -1 loops forever. Applies to every run
  /// started by a [trigger] change or the `#immediate` sentinel.
  final int repeat;

  /// Creates a [TimelineEffect].
  const TimelineEffect({
    super.key,
    required this.chain,
    this.trigger,
    this.controller,
    this.onEnd,
    this.repeat = 0,
  });

  @override
  State<TimelineEffect> createState() => TimelineEffectState();
}

/// The state of a [TimelineEffect].
class TimelineEffectState extends State<TimelineEffect>
    with SingleTickerProviderStateMixin {
  /// The compiled timeline. Recompiled on every widget update so keyframe
  /// values that depend on outside state stay current.
  late TimelineSpec spec = TimelineSpec.compile(widget.chain);

  /// The single controller that drives every track of the timeline.
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: spec.totalDuration,
  )..addStatusListener(_onStatusChanged);

  @override
  void initState() {
    super.initState();
    widget.controller?.attach(controller);
    if (widget.trigger == #immediate) {
      _play();
    }
  }

  /// Invalidates in-flight cycle loops when a newer run takes over.
  int _runGeneration = 0;

  /// Cycles left in the current run AFTER the one in flight. While positive,
  /// a completed status is a cycle boundary, not the end of the timeline.
  int _pendingCycles = 0;

  /// Starts a run from the beginning, honoring the widget's repeat budget.
  void _play() {
    _runGeneration++;
    _pendingCycles = 0;
    if (widget.repeat == -1) {
      // Native repeat is safe here: it never completes, so it cannot rest
      // at a wrapped value the way a counted repeat would.
      controller.value = 0;
      controller.repeat();
    } else {
      unawaited(_driveCycles(widget.repeat + 1));
    }
  }

  /// Plays [cycles] full forward passes, resting at the final keyframe.
  ///
  /// Uses `.orCancel` so an interruption (new run, seek, pause, dispose)
  /// surfaces as [TickerCanceled] instead of leaving a future that never
  /// resolves.
  Future<void> _driveCycles(int cycles) async {
    _runGeneration++;
    final int generation = _runGeneration;
    for (int i = 0; i < cycles; i++) {
      if (!mounted || generation != _runGeneration) return;
      // Rewinding emits a synchronous `dismissed`; keep the count high until
      // the cycle is running so that rewind never reads as a terminal end.
      _pendingCycles = cycles - i;
      final TickerFuture ticket = controller.forward(from: 0);
      _pendingCycles = cycles - i - 1;
      try {
        await ticket.orCancel;
      } on TickerCanceled {
        // A newer run owns the controller now; only a still-current loop
        // may clear its own bookkeeping.
        if (generation == _runGeneration) {
          _pendingCycles = 0;
        }
        return;
      }
    }
  }

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      if (_pendingCycles > 0) return;
      widget.onEnd?.call();
    }
  }

  @override
  void didUpdateWidget(covariant TimelineEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    spec = TimelineSpec.compile(widget.chain);
    controller.duration = spec.totalDuration;

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.detach(controller);
      widget.controller?.attach(controller);
    }

    if (widget.trigger != oldWidget.trigger) {
      _play();
    }
  }

  @override
  void dispose() {
    widget.controller?.detach(controller);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        Widget result = child!;
        for (final Effect effect in spec.evaluate(controller.value)) {
          result = effect.apply(context, result);
        }
        return result;
      },
      child: spec.child,
    );
  }
}
