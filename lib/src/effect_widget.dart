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

  /// Evaluates the closed-form spring state — (position, velocity) — at
  /// [linearValue] of the current run. The coefficients are scalars; all
  /// arithmetic happens in effect space via [VectorEffect] operators.
  (Effect, Effect) _springState(SpringMotion motion, double linearValue) {
    final double seconds = motion.effectiveDuration.inMicroseconds /
        Duration.microsecondsPerSecond;
    final SpringCoefficients c =
        springCoefficients(motion.description, linearValue * seconds);
    final dynamic displacement = (start as dynamic) - end;
    dynamic position = (end as dynamic) + displacement * c.a;
    dynamic speed = displacement * c.da;
    final dynamic v0 = velocity;
    if (v0 != null) {
      position = position + v0 * c.b;
      speed = speed + v0 * c.db;
    }
    return (position as Effect, speed as Effect);
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
    final double animationValue = effectQuery?.curvedValue ?? 0;
    previousAnimationValue = animationValue;
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

  @override
  void didUpdateWidget(covariant EffectWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_reassembled) {
      _reassembled = false;
      start = widget.start ?? widget.end;
      end = widget.end;
      velocity = null;
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
      start = widget.start ?? widget.end;
      end = widget.end;
      velocity = null;
      return;
    }

    if (oldWidget.end != widget.end &&
        oldWidget.end.runtimeType == widget.end.runtimeType &&
        start.runtimeType == end.runtimeType) {
      if (!effectQuery.isTransition) {
        if (_isSpringDriven(effectQuery)) {
          // Capture BOTH the rendered position and the instantaneous
          // velocity of the in-flight spring: the new run starts from the
          // captured position with the captured momentum.
          final (Effect position, Effect speed) = _springState(
            effectQuery.motion! as SpringMotion,
            previousLinearValue,
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
        final double linearValue = effectQuery!.linearValue;
        // Endpoints are exact: the settling bound leaves a sub-tolerance
        // residual which must not leak into resting keyframes.
        if (linearValue >= 1) {
          return end.apply(context, child);
        }
        final (Effect position, _) = _springState(
          effectQuery.motion! as SpringMotion,
          linearValue,
        );
        return position.apply(context, child);
      }

      if (_isSilentlyDowngradedFromSpring(effectQuery)) {
        _warnSpringDowngrade(end.runtimeType);
      }

      final double animationValue = effectQuery?.curvedValue ?? 0;
      Effect effectiveStart = start;
      if (widget.start == null && effectQuery?.resetValues == true) {
        effectiveStart = start.idle();
      }

      final Effect newEffect = effectiveStart.lerp(end, animationValue);
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
