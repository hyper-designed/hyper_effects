library scrolling_effects;

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'scroll_phase.dart';

typedef EffectsBuilder = List<ScrollEffect> Function(ScrollPhase phase);

typedef PhasedWidgetBuilder = Widget Function(
  BuildContext context,
  Widget child,
  ScrollPhase phase,
);

class ScrollAnimation extends StatefulWidget {
  final int index;
  final EffectsBuilder? effectsBuilder;
  final PhasedWidgetBuilder? builder;
  final Widget child;

  const ScrollAnimation({
    super.key,
    required this.child,
    this.effectsBuilder,
    this.builder,
    required this.index,
  });

  @override
  State<ScrollAnimation> createState() => _ScrollAnimationState();
}

class _ScrollAnimationState extends State<ScrollAnimation>
    with SingleTickerProviderStateMixin {
  /// The current phase of the scroll animation.
  ScrollPhase currentPhase = ScrollPhase.identity;

  /// The parent scrollable widget.
  late final ScrollableState? scrollable = Scrollable.maybeOf(context);

  /// The scroll controller of the parent scrollable widget.
  late final ScrollController? scrollController =
      scrollable?.widget.controller ?? PrimaryScrollController.maybeOf(context);

  /// The current animation value indicating the progress of the scroll
  /// animation through its phase in the parent viewport.
  double currentValue = 0;

  /// identity -> current
  Map<ScrollEffect, ScrollEffect> effects = {};

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      updateCurrentState();
      scrollController?.addListener(onScrollChanged);
    });
  }

  @override
  void dispose() {
    scrollController?.removeListener(onScrollChanged);
    super.dispose();
  }

  void updateCurrentState([VoidCallback? onChanged]) {
    final (:phase, :value) = calculatePhase();
    if (phase != currentPhase || value != currentValue) {
      currentPhase = phase;
      currentValue = value;
      final currentEffects = widget.effectsBuilder?.call(currentPhase) ?? [];
      final identityEffects =
          widget.effectsBuilder?.call(ScrollPhase.identity) ?? [];
      effects = {
        for (final (index, effect) in identityEffects.indexed)
          effect: currentEffects.elementAtOrNull(index) ?? effect,
      };

      onChanged?.call();
    }
  }

  void onScrollChanged() {
    updateCurrentState(() {
      if (mounted) setState(() {});
    });
  }

  Widget _buildScaleEffect(
      Widget child, ScaleEffect currentEffect, ScaleEffect identityEffect) {
    final double scale =
        lerpDouble(currentEffect.scale, identityEffect.scale, currentValue) ??
            1;
    return Transform.scale(
      scale: scale,
      child: child,
    );
  }

  Widget _buildOffsetEffect(
      Widget child, OffsetEffect currentEffect, OffsetEffect identityEffect) {
    final double x =
        lerpDouble(currentEffect.x, identityEffect.x, currentValue) ?? 1;
    final double y =
        lerpDouble(currentEffect.y, identityEffect.y, currentValue) ?? 1;
    return Transform.translate(
      offset: Offset(x, y),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget child = widget.builder?.call(context, widget.child, currentPhase) ??
        widget.child;

    if (scrollable == null) return child;
    if (effects.isEmpty) return child;

    for (final MapEntry(key: destinationEffect, value: currentEffect)
    in effects.entries) {
      if (destinationEffect is ScaleEffect && currentEffect is ScaleEffect) {
        child = _buildScaleEffect(child, currentEffect, destinationEffect);
      } else if (destinationEffect is OffsetEffect &&
          currentEffect is OffsetEffect) {
        child = _buildOffsetEffect(child, currentEffect, destinationEffect);
      }
    }

    return child;
  }

  /// Calculates the current phase of the scroll animation.
  /// Returns a record of the current phase and it's associated progress
  /// through the viewport as a value between 0 and 1.
  ({ScrollPhase phase, double value}) calculatePhase() {
    if (scrollable case var scrollable?) {
      final viewPort = scrollable.context.globalPaintBounds;
      final paintBounds = context.globalPaintBounds;
      if (paintBounds != null && viewPort != null) {
        if (viewPort.contains(paintBounds.topLeft) &&
            viewPort.contains(paintBounds.bottomRight)) {
          return (phase: ScrollPhase.identity, value: 1);
        } else if (viewPort.top > paintBounds.top) {
          final value =
              1 - (viewPort.top - paintBounds.top) / paintBounds.height;
          return (phase: ScrollPhase.topLeading, value: value);
        } else if (viewPort.bottom < paintBounds.bottom) {
          final value =
              1 - (paintBounds.bottom - viewPort.bottom) / paintBounds.height;
          return (phase: ScrollPhase.bottomTrailing, value: value);
        }
      }
    }
    return (phase: ScrollPhase.identity, value: 1);
  }
}


abstract class ScrollEffect {
  const ScrollEffect();

  // Widget apply(BuildContext context, Widget child, ScrollPhase phase, ScrollEffect begin);
}

class ScaleEffect extends ScrollEffect {
  final double scale;

  const ScaleEffect(this.scale);

  // @override
  // Widget apply(BuildContext context, Widget child, ScrollPhase phase, ScrollEffect begin) {
  //   final double scale =
  //       lerpDouble(currentEffect.scale, identityEffect.scale, animationValue) ??
  //           1;
  //   return Transform.scale(
  //     scale: scale,
  //     child: child,
  //   );
  // }
}

class OffsetEffect extends ScrollEffect {
  final double x;
  final double y;

  const OffsetEffect({this.x = 0, this.y = 0});
}

Color randomColor(int index) {
  final r = Random(index * 100).nextInt(255);
  final g = Random(index * 200).nextInt(255);
  final b = Random(index * 300).nextInt(255);
  return Color.fromARGB(255, r, g, b);
}

extension GlobalKeyExtension on GlobalKey {
  Rect? get globalPaintBounds {
    final renderObject = currentContext?.findRenderObject();
    var translation = renderObject?.getTransformTo(null).getTranslation();
    if (translation != null && renderObject?.paintBounds != null) {
      return renderObject!.paintBounds
          .shift(Offset(translation.x, translation.y));
    } else {
      return null;
    }
  }
}

extension BuildContextExtension on BuildContext {
  Rect? get globalPaintBounds {
    final renderObject = findRenderObject();
    var translation = renderObject?.getTransformTo(null).getTranslation();
    if (translation != null && renderObject?.paintBounds != null) {
      return renderObject!.paintBounds
          .shift(Offset(translation.x, translation.y));
    } else {
      return null;
    }
  }
}

extension RenderBoxExtension on RenderObject {
  Rect get globalPaintBounds {
    var translation = getTransformTo(null).getTranslation();
    return paintBounds.shift(Offset(translation.x, translation.y));
  }
}
