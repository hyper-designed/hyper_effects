import 'package:flutter/widgets.dart';
import 'pointer_transition.dart';

/// An inherited widget that provides the animation value to it's descendants.
///
/// This widget is used by [AnimatedEffect], [ScrollTransition], and
/// [PointerTransition] widgets to provide their animation values to their
/// descendants in order to animate them.
class EffectQuery extends InheritedWidget {
  /// The linear animation value. It's value is between 0 and 1.
  final double linearValue;

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

  /// The duration of the animation.
  final Duration duration;

  /// The curve of the animation.
  final Curve curve;

  /// Creates [EffectQuery] widget.
  const EffectQuery({
    super.key,
    required super.child,
    required this.linearValue,
    required this.curvedValue,
    required this.isTransition,
    this.lerpValues = true,
    this.duration = Duration.zero,
    this.curve = Curves.linear,
  });

  @override
  bool updateShouldNotify(covariant EffectQuery oldWidget) {
    return oldWidget.curvedValue != curvedValue ||
        oldWidget.isTransition != isTransition ||
        oldWidget.lerpValues != lerpValues;
  }

  /// Returns the [EffectQuery] from the given [context].
  static EffectQuery of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<EffectQuery>()!;
  }

  /// Returns the [EffectQuery] from the given [context].
  static EffectQuery? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<EffectQuery>();
  }
}
