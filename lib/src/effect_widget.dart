import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'effect_query.dart';
import 'effects/effect.dart';
import 'effects/vector_effect.dart';
import 'motion/motion.dart';
import 'motion/vector_spring.dart';

/// A widget that applies given [Effect] to a [Widget]. This widget is hardly
/// used directly. Instead, use the extension methods provided by the effects
/// to apply them to a [Widget].
///
/// This widget does a parent lookup to find the [EffectQuery] widget
/// to get the animation value. If no [EffectQuery] is found, the
/// animation value is 1.
///
/// If an animation value is found, the [Effect.lerp] method is called to
/// interpolate between two [Effect]s. The resulting [Effect] is then applied
/// to the [child] by calling [Effect.apply].
class EffectWidget extends StatefulWidget {
  /// The effect applied to the [child] to interpolate to.
  final Effect end;

  /// The effect applied to the [child] to interpolate from.
  final Effect? start;

  /// The [Widget] to apply the [end] to.
  final Widget? child;

  /// Creates an [EffectWidget].
  const EffectWidget({
    super.key,
    this.start,
    required this.end,
    required this.child,
  });

  /// The set of effect runtime types this process has already warned about
  /// via the spring-downgrade diagnostic (see [_EffectWidgetState
  /// ._warnSpringDowngrade]). Static and process-wide, and lives here on
  /// the public [EffectWidget] — rather than on the private state class
  /// that actually populates it — purely so [resetSpringDowngradeWarningsForTesting]
  /// has a name a test file can reach; privacy in Dart is per-library, and
  /// the state class's name is not importable from outside this file.
  static final Set<Type> _warnedSpringDowngradeTypes = <Type>{};

  /// Clears the set of effect types already warned about by the
  /// spring-downgrade diagnostic, so a test that triggers the same
  /// downgrade more than once (e.g. once per test case in a single test
  /// run) can observe the diagnostic each time instead of only the first.
  @visibleForTesting
  static void resetSpringDowngradeWarningsForTesting() {
    _warnedSpringDowngradeTypes.clear();
  }

  @override
  State<EffectWidget> createState() => _EffectWidgetState();
}

class _EffectWidgetState extends State<EffectWidget> {
  /// The [Effect] to interpolate to.
  late Effect end;

  /// The [Effect] to interpolate from.
  late Effect start;

  /// caches the previous animation value to use in didUpdateWidget
  /// to calculate the begin value. This is used to create a smooth transition
  /// between two [Effect]s when the [Effect] changes mid animation.
  double previousAnimationValue = 0;

  /// The previous LINEAR animation value: spring physics runs on real time,
  /// not curved progress.
  double previousLinearValue = 0;

  int? previousRunId;
  Motion? previousMotion;
  bool previousReverseLeg = false;
  bool _capturedDuringWidgetUpdate = false;

  /// The typed velocity carried across spring retargets — an effect-shaped
  /// "units per second", captured analytically at the interruption instant.
  Effect? velocity;

  /// Whether the current start/end pair can be driven by spring physics.
  bool _isSpringDriven(EffectQuery? query) =>
      query != null &&
      !query.isTransition &&
      query.lerpValues &&
      query.motion is SpringMotion &&
      start is VectorEffect &&
      end is VectorEffect &&
      start.runtimeType == end.runtimeType;

  /// The mirror image of [_isSpringDriven]: true exactly when a
  /// [SpringMotion] WOULD be driving this pair, except that the effect
  /// doesn't mix in [VectorEffect] and so is about to fall back to the
  /// normalized [Effect.lerp] path instead of real physics.
  ///
  /// This is deliberately built from the same clauses as [_isSpringDriven]
  /// rather than as its plain negation, so it inherits the same guards
  /// against false positives: it agrees with [_isSpringDriven] on every
  /// condition (a live, non-transition, lerped query actually carrying a
  /// spring, with matching start/end runtime types) and disagrees only on
  /// the one clause that decides the downgrade. The two predicates are
  /// therefore mutually exclusive by construction, which is what lets
  /// [build] call this right where [_isSpringDriven] gave up, with no risk
  /// of firing on `isTransition` queries, `lerpValues: false` queries, or
  /// curve-driven motions — those are different code paths entirely, not
  /// silent degradations.
  bool _isSilentlyDowngradedFromSpring(EffectQuery? query) =>
      query != null &&
      !query.isTransition &&
      query.lerpValues &&
      query.motion is SpringMotion &&
      start.runtimeType == end.runtimeType &&
      start is! VectorEffect;

  /// Warns, at most once per effect runtime type for the lifetime of the
  /// process, that [effectType] is being driven by a [SpringMotion] but
  /// doesn't mix in [VectorEffect] — so it has silently fallen back to the
  /// normalized `lerp` path instead of real spring physics.
  ///
  /// The fallback isn't merely an alternate implementation of the same
  /// physics. It loses the closed-form spring state in effect space. The
  /// scalar [SpringMotion] progress can still exceed 1, so an unclamped
  /// [Effect.lerp] MAY render overshoot and settle-back. But that behavior is
  /// now implementation-dependent: an effect whose `lerp` clamps progress
  /// flattens the overshoot entirely, and even an extrapolating `lerp` follows
  /// scalar interpolation rather than the vector spring trajectory.
  ///
  /// Velocity handoff on retarget is lost unconditionally. [didUpdateWidget]
  /// only captures the in-flight spring's momentum inside the
  /// [_isSpringDriven] branch, so retargeting a downgraded effect mid-flight
  /// restarts it from rest instead of carrying its speed into the new run.
  ///
  /// This is a debug console warning rather than a [FlutterError]: the
  /// downgrade is actionable developer guidance, not a framework failure.
  /// Sending it through [FlutterError.reportError] would also feed it into
  /// consuming apps' Crashlytics/Sentry handlers and make `flutter_test`
  /// promote the warning to a test failure.
  ///
  /// This method is called from [build], which runs on every frame of every
  /// animation driven by this widget. Warning unconditionally would flood the
  /// console for the lifetime of a repeatedly-rebuilding, permanently-
  /// downgraded effect. Warning is deliberately keyed by runtime [Type]
  /// rather than widget identity: "this kind of effect is missing
  /// VectorEffect" is a fact about the effect's class, not any one instance.
  /// A screen with a dozen affected widgets therefore reports the one-line
  /// class fix once instead of printing a dozen identical warnings.
  static void _warnSpringDowngrade(Type effectType) {
    assert(() {
      if (EffectWidget._warnedSpringDowngradeTypes.add(effectType)) {
        debugPrint(
          'hyper_effects: SpringMotion downgraded for $effectType\n'
          '$effectType does not mix in VectorEffect, so it is using the '
          'normalized Effect.lerp path instead of closed-form vector spring '
          'physics. Scalar spring progress may still exceed 1, but overshoot '
          "and settle-back now depend on whether $effectType's lerp "
          'extrapolates or clamps; a clamping lerp flattens them. Mid-flight '
          'retargets always lose velocity handoff and restart from rest.\n'
          'Remedy: mix VectorEffect<$effectType> into $effectType, or switch '
          'this animation to CurvedMotion if non-physical interpolation is '
          'intended.',
        );
      }
      return true;
    }());
  }

  /// The endpoints the active leg runs between: a reverse leg is a fresh
  /// forward-time solve from [end] back to the start. This is the single
  /// owner of the endpoint rule — resting frames and mid-flight samples
  /// both derive from it.
  (Effect from, Effect target) _legEndpoints(
    bool reverse,
    Effect? effectiveStart,
  ) {
    final Effect resolvedStart = effectiveStart ?? start;
    return reverse ? (end, resolvedStart) : (resolvedStart, end);
  }

  /// Evaluates the closed-form spring position at [linearValue] of the
  /// current run — the per-frame path, which never needs the velocity half
  /// of the solution. The coefficients are scalars; all arithmetic happens
  /// in effect space via [VectorEffect] operators.
  Effect _springPosition(
    SpringMotion motion,
    double linearValue, {
    bool reverse = false,
    Effect? effectiveStart,
  }) {
    final (Effect from, Effect target) = _legEndpoints(reverse, effectiveStart);
    // Endpoints are exact: the settling bound leaves a sub-tolerance
    // residual which must not leak into resting keyframes.
    if (linearValue >= 1) return target;
    final double seconds = motion.effectiveDuration.inMicroseconds /
        Duration.microsecondsPerSecond;
    final SpringCoefficients c =
        springCoefficients(motion.description, linearValue * seconds);
    final dynamic displacement = (from as dynamic) - target;
    dynamic position = (target as dynamic) + displacement * c.a;
    final dynamic v0 = reverse ? null : velocity;
    if (v0 != null) {
      position = position + v0 * c.b;
    }
    return position as Effect;
  }

  /// Evaluates position AND instantaneous velocity. Only needed when a
  /// retarget captures the in-flight state — per trigger, not per frame —
  /// so re-solving the coefficients for the velocity half is fine.
  (Effect, Effect) _springState(
    SpringMotion motion,
    double linearValue, {
    bool reverse = false,
  }) {
    final Effect position =
        _springPosition(motion, linearValue, reverse: reverse);
    if (linearValue >= 1) {
      return (position, ((position as dynamic) - position) as Effect);
    }
    final double seconds = motion.effectiveDuration.inMicroseconds /
        Duration.microsecondsPerSecond;
    final SpringCoefficients c =
        springCoefficients(motion.description, linearValue * seconds);
    final (Effect from, Effect target) = _legEndpoints(reverse, null);
    dynamic speed = ((from as dynamic) - target) * c.da;
    final dynamic v0 = reverse ? null : velocity;
    if (v0 != null) {
      speed = speed + v0 * c.db;
    }
    return (position, speed as Effect);
  }

  @override
  void initState() {
    super.initState();
    end = widget.end;
    start = widget.start ?? widget.end;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final effectQuery = EffectQuery.maybeOf(context);
    final int? runId = effectQuery?.runId;
    if (previousRunId != null && runId != previousRunId) {
      // Only a run that HOLDS its interrupted predecessor (a delayed
      // same-target retrigger) carries the rendered position into its
      // start. The last-built frame value cannot decide this: a completed
      // run's final frame may never build when its successor starts within
      // the same frame, leaving previousLinearValue stranded strictly
      // inside (0, 1). Every other new run is a replay: it repaints from
      // the author's explicit start when given, and otherwise keeps the
      // pair start untouched — the only record of where this pair began.
      if (!_capturedDuringWidgetUpdate) {
        if (effectQuery != null && !effectQuery.isTransition) {
          if (effectQuery.continuesInterrupted &&
              previousLinearValue > 0 &&
              previousLinearValue < 1) {
            start = start.lerp(end, previousAnimationValue);
          } else if (widget.start != null) {
            start = widget.start!;
          }
        }
        velocity = null;
      }
    }
    _capturedDuringWidgetUpdate = false;
    previousRunId = runId;
    previousMotion = effectQuery?.motion;
    previousReverseLeg = effectQuery?.reverseLeg ?? false;
    previousAnimationValue = effectQuery?.curvedValue ?? 0;
    previousLinearValue = effectQuery?.linearValue ?? 0;
  }

  /// Set on hot reload ([reassemble] fires only then) and consumed by the
  /// next [didUpdateWidget]: a hot reload must behave like a fresh mount,
  /// re-seeding from the edited widget configuration. Otherwise the
  /// animation-continuation state below masks source edits whenever a
  /// driving [EffectQuery] — its own `.animate()` or ANY ancestor one —
  /// rests at an animation value of 0.
  bool _reassembled = false;

  @override
  void reassemble() {
    super.reassemble();
    _reassembled = true;
  }

  /// Re-adopts the widget configuration as the rendered pair, discarding any
  /// continuation state. The single body behind every "this is not a
  /// continuable retarget" branch in [didUpdateWidget].
  void _adoptWidgetPair() {
    start = widget.start ?? widget.end;
    end = widget.end;
    velocity = null;
  }

  @override
  void didUpdateWidget(covariant EffectWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // A hot reload, an incompatible effect subtype, or a changed explicit
    // start is not a continuable retarget: re-seed from configuration.
    if (_reassembled ||
        oldWidget.end.runtimeType != widget.end.runtimeType ||
        (oldWidget.end == widget.end && oldWidget.start != widget.start)) {
      _reassembled = false;
      _adoptWidgetPair();
      return;
    }

    final effectQuery = EffectQuery.maybeOf(context);

    // Static usage: with no animation or transition driving this widget,
    // the rendered state must track the widget configuration directly,
    // otherwise rebuilds (e.g. hot reload with a changed parameter) keep
    // showing the values captured in initState. An unconditional version of
    // this sync (see git history of update pack v2) broke scroll
    // transitions, which is why it is gated on the absence of a query.
    if (effectQuery == null) {
      _adoptWidgetPair();
      return;
    }

    if (oldWidget.end != widget.end && start.runtimeType == end.runtimeType) {
      _capturedDuringWidgetUpdate = true;
      if (!effectQuery.isTransition) {
        if (_isSpringDriven(effectQuery)) {
          // Capture BOTH the rendered position and the instantaneous
          // velocity of the in-flight spring: the new run starts from the
          // captured position with the captured momentum.
          final outgoingMotion = previousMotion;
          final (Effect position, Effect speed) = _springState(
            outgoingMotion is SpringMotion
                ? outgoingMotion
                : effectQuery.motion! as SpringMotion,
            previousLinearValue,
            reverse: previousReverseLeg,
          );
          start = position;
          velocity = speed;
        } else {
          start = start.lerp(end, previousAnimationValue);
          velocity = null;
        }
      }

      end = widget.end;
    }
  }

  Effect _effectiveStart(EffectQuery? query) =>
      widget.start == null && query?.resetValues == true ? end.idle() : start;

  @override
  Widget build(BuildContext context) {
    final effectQuery = EffectQuery.maybeOf(context);

    final child = widget.child;

    if (effectQuery?.lerpValues == false) {
      return end.apply(context, child);
    } else {
      if (start.runtimeType != end.runtimeType) {
        return child ?? const SizedBox.shrink();
      }

      if (_isSpringDriven(effectQuery)) {
        final Effect position = _springPosition(
          effectQuery!.motion! as SpringMotion,
          effectQuery.linearValue,
          reverse: effectQuery.reverseLeg,
          effectiveStart: _effectiveStart(effectQuery),
        );
        return position.apply(context, child);
      }

      if (_isSilentlyDowngradedFromSpring(effectQuery)) {
        _warnSpringDowngrade(end.runtimeType);
      }

      final double animationValue = effectQuery?.curvedValue ?? 0;
      final Effect newEffect =
          _effectiveStart(effectQuery).lerp(end, animationValue);
      return newEffect.apply(context, child);
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Effect>('start', start));
    properties.add(DiagnosticsProperty<Effect>('end', end));
  }
}
