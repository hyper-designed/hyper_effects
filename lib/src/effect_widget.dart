import 'package:flutter/widgets.dart';

import 'effect_query.dart';
import 'effects/effect.dart';

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
  late double previousAnimationValue = 0;

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
  }

  @override
  void didUpdateWidget(covariant EffectWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.end != widget.end &&
        oldWidget.end.runtimeType == widget.end.runtimeType &&
        start.runtimeType == end.runtimeType) {
      final effectQuery = EffectQuery.maybeOf(context);
      if (effectQuery != null && !effectQuery.isTransition) {
        start = start.lerp(end, previousAnimationValue);
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

      final double animationValue = effectQuery?.curvedValue ?? 0;
      Effect effectiveStart = start;
      if (widget.start == null && effectQuery?.resetValues == true) {
        effectiveStart = start.idle();
      }
      final Effect newEffect = effectiveStart.lerp(end, animationValue);
      return newEffect.apply(context, child);
    }
  }
}
