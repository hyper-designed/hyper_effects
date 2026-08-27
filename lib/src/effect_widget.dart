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

  /// Evaluates the closed-form spring state — (position, velocity) — at
  /// [linearValue] of the current run. The coefficients are scalars; all
  /// arithmetic happens in effect space via [VectorEffect] operators.
  (Effect, Effect) _springState(SpringMotion motion, double linearValue) {
    final double seconds =
        motion.effectiveDuration.inMicroseconds / Duration.microsecondsPerSecond;
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
