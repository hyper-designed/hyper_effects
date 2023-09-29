library scrolling_effects;

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';



class ScrollAnimation extends StatefulWidget {
  final int index;
  final Widget child;
  final List<ScrollEffect> Function(ScrollPhase phase)? effectsBuilder;

  final Widget Function(BuildContext context, Widget child, ScrollPhase phase)?
  builder;

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
  ScrollPhase currentPhase = ScrollPhase.identity;

  late final ScrollableState? scrollable = Scrollable.maybeOf(context);

  late final ScrollController? scrollController =
      scrollable?.widget.controller ?? PrimaryScrollController.maybeOf(context);

  double animationValue = 0;

  // identity -> current
  Map<ScrollEffect, ScrollEffect> effects = {};

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      onFirstFrame();
    });
  }

  void onScrollChanged() {
    final (newPhase, newAnimationValue) = calculatePhase();
    if (newPhase != currentPhase || newAnimationValue != animationValue) {
      currentPhase = newPhase;
      animationValue = newAnimationValue;
      final currentEffects = widget.effectsBuilder?.call(currentPhase) ?? [];
      final identityEffects =
          widget.effectsBuilder?.call(ScrollPhase.identity) ?? [];
      effects = {
        for (final (index, effect) in identityEffects.indexed)
          effect: currentEffects.elementAtOrNull(index) ?? effect,
      };
      if (mounted) setState(() {});
    }
  }

  void onFirstFrame() {
    if (scrollable == null) return;
    final result = calculatePhase();
    currentPhase = result.$1;
    animationValue = result.$2;
    final currentEffects = widget.effectsBuilder?.call(currentPhase) ?? [];
    final identityEffects =
        widget.effectsBuilder?.call(ScrollPhase.identity) ?? [];
    effects = {
      for (final (index, effect) in identityEffects.indexed)
        effect: currentEffects.elementAtOrNull(index) ?? effect,
    };
    // NotificationListener(child: child);
    // ScrollNotificationObserver.of(scrollable!.context!).addListener((_) => onScrollChanged);
    scrollController?.addListener(onScrollChanged);
  }

  @override
  Widget build(BuildContext context) {
    final ScrollableState? scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) return widget.child;

    Widget child = widget.builder == null
        ? widget.child
        : widget.builder!(context, widget.child, currentPhase);

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

  (ScrollPhase, double) calculatePhase() {
    if (scrollable case var scrollable?) {
      final viewPort = scrollable.context.globalPaintBounds;
      final paintBounds = context.globalPaintBounds;
      if (paintBounds != null && viewPort != null) {
        if (viewPort.contains(paintBounds.topLeft) &&
            viewPort.contains(paintBounds.bottomRight)) {
          return (ScrollPhase.identity, 1);
        } else if (viewPort.top > paintBounds.top) {
          final value =
              1 - (viewPort.top - paintBounds.top) / paintBounds.height;
          return (ScrollPhase.topLeading, value);
        } else if (viewPort.bottom < paintBounds.bottom) {
          final value =
              1 - (paintBounds.bottom - viewPort.bottom) / paintBounds.height;
          return (ScrollPhase.bottomTrailing, value);
        }
      }
    }
    return (ScrollPhase.identity, 1);
  }

  @override
  void dispose() {
    scrollController?.removeListener(onScrollChanged);
    super.dispose();
  }

  Widget _buildScaleEffect(
      Widget child, ScaleEffect currentEffect, ScaleEffect identityEffect) {
    final double scale =
        lerpDouble(currentEffect.scale, identityEffect.scale, animationValue) ??
            1;
    return Transform.scale(
      scale: scale,
      child: child,
    );
  }

  Widget _buildOffsetEffect(
      Widget child, OffsetEffect currentEffect, OffsetEffect identityEffect) {
    final double x =
        lerpDouble(currentEffect.x, identityEffect.x, animationValue) ?? 1;
    final double y =
        lerpDouble(currentEffect.y, identityEffect.y, animationValue) ?? 1;
    return Transform.translate(
      offset: Offset(x, y),
      child: child,
    );
  }
}

enum ScrollPhase {
  topLeading,
  identity,
  bottomTrailing;

  bool get isTopLeading => this == ScrollPhase.topLeading;

  bool get isIdentity => this == ScrollPhase.identity;

  bool get isBottomTrailing => this == ScrollPhase.bottomTrailing;
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
