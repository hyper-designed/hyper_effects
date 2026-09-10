import 'package:flutter/widgets.dart';

import 'pointer_transition.dart';
import 'motion/motion.dart';

/// An inherited widget that provides the animation value to it's descendants.
///
/// This widget is used by [AnimatedEffect], [ScrollTransition], and
/// [PointerTransition] widgets to provide their animation values to their
/// descendants in order to animate them.
class EffectQuery extends InheritedWidget {
  /// The linear animation value. It's value is between 0 and 1.
  final double linearValue;

  /// Identifies the logical animation run that owns these values.
  final int runId;

  /// Whether the active run continues from the render it interrupted rather
  /// than replaying from its start. True only for a run that superseded a
  /// mid-flight run AND parks through a nonzero delay: a delayed same-target
  /// retrigger must hold the interrupted position through its delay window.
  /// A zero-delay retrigger is a replay, and a completed predecessor —
  /// however recently — is never an interruption. Descendants must use this,
  /// never a stale build value, to decide whether to carry the rendered
  /// position into the new run.
  final bool continuesInterrupted;

  /// Whether the active run is solving its ending-to-starting leg.
  final bool reverseLeg;

  /// The animation value. It's value is between 0 and 1, interpolated by the
  /// [Curve] provided.
  final double curvedValue;

  /// Whether the animation is in scroll transition or not. Animations behave
  /// differently in scroll transition. This flag is used to determine the
  /// behavior of the animation.
  final bool isTransition;

  /// Whether the animation should be lerped or not. If set to false, the
  /// animation value is used as is. If set to true, the animation value is
  /// interpolated between 0 and 1.
  final bool lerpValues;

  /// Normally, an effect represents the current state of the widget and this
  /// animate effect is only in charge of lerping between states of those
  /// effect values.
  /// If this is set to true, instead of treating effects as current states
  /// to animate between, it will always animate from an initial default
  /// state towards the current state.
  final bool resetValues;

  /// The duration of the animation.
  final Duration duration;

  /// The [Motion] driving the animation, when driven by an animator that
  /// has one. Physics-aware descendants (spring-driven [EffectWidget]s)
  /// read this; transitions leave it null.
  final Motion? motion;

  /// The curve of the animation.
  final Curve curve;

  /// Creates [EffectQuery] widget.
  const EffectQuery({
    super.key,
    required super.child,
    required this.linearValue,
    this.runId = 0,
    this.continuesInterrupted = false,
    this.reverseLeg = false,
    required this.curvedValue,
    required this.isTransition,
    this.lerpValues = true,
    this.resetValues = false,
    this.duration = Duration.zero,
    this.curve = Curves.linear,
    this.motion,
  });

  @override
  bool updateShouldNotify(covariant EffectQuery oldWidget) {
    return oldWidget.linearValue != linearValue ||
        oldWidget.runId != runId ||
        oldWidget.continuesInterrupted != continuesInterrupted ||
        oldWidget.reverseLeg != reverseLeg ||
        oldWidget.curvedValue != curvedValue ||
        oldWidget.isTransition != isTransition ||
        oldWidget.lerpValues != lerpValues ||
        oldWidget.resetValues != resetValues ||
        oldWidget.duration != duration ||
        oldWidget.curve != curve ||
        oldWidget.motion != motion;
  }

  /// Returns the [EffectQuery] from the given [context].
  static EffectQuery of(BuildContext context) {
    final EffectQuery? result = maybeOf(context);
    assert(result != null, 'No EffectQuery found in context.');
    return result!;
  }

  /// Returns the [EffectQuery] from the given [context].
  static EffectQuery? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<EffectQuery>();
  }
}
