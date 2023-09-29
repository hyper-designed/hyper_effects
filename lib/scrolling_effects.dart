library scrolling_effects;

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

class _ScrollAnimationState extends State<ScrollAnimation> {
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

  /// A map containing the identity form of a given effect and associated
  /// destination effect that will be applied when the scroll animation
  /// reaches the destination phase.
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

  @override
  Widget build(BuildContext context) {
    Widget child = widget.builder?.call(context, widget.child, currentPhase) ??
        widget.child;

    if (scrollable == null) return child;
    if (effects.isEmpty) return child;

    for (final MapEntry(key: identity, value: destination) in effects.entries) {
      if (identity.runtimeType == destination.runtimeType) {
        child = identity.apply(context, child, destination, currentValue);
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

/// An effect that can be applied to a widget during a scroll animation.
abstract class ScrollEffect {
  const ScrollEffect();

  /// Applies the effect to the given child widget for each frame where the
  /// viewport scroll position changes.
  Widget apply(
    BuildContext context,
    Widget child,
    covariant ScrollEffect begin,
    double value,
  );
}

/// An effect that scales its child along the 2D plane during a scroll animation.
class ScaleEffect extends ScrollEffect {
  /// The matrix to transform the child by during painting.
  final Matrix4 transform;

  /// The origin of the coordinate system (relative to the upper left corner of
  /// this render object) in which to apply the matrix.
  ///
  /// Setting an origin is equivalent to conjugating the transform matrix by a
  /// translation. This property is provided just for convenience.
  final Offset? origin;

  /// The alignment of the origin, relative to the size of the box.
  ///
  /// This is equivalent to setting an origin based on the size of the box.
  /// If it is specified at the same time as the [origin], both are applied.
  ///
  /// An [AlignmentDirectional.centerStart] value is the same as an [Alignment]
  /// whose [Alignment.x] value is `-1.0` if [Directionality.of] returns
  /// [TextDirection.ltr], and `1.0` if [Directionality.of] returns
  /// [TextDirection.rtl].	 Similarly [AlignmentDirectional.centerEnd] is the
  /// same as an [Alignment] whose [Alignment.x] value is `1.0` if
  /// [Directionality.of] returns	 [TextDirection.ltr], and `-1.0` if
  /// [Directionality.of] returns [TextDirection.rtl].
  final AlignmentGeometry? alignment;

  /// Whether to apply the transformation when performing hit tests.
  final bool transformHitTests;

  /// The filter quality with which to apply the transform as a bitmap operation.
  final FilterQuality? filterQuality;

  /// Creates a widget that scales its child along the 2D plane.
  ///
  /// The `scaleX` argument provides the scalar by which to multiply the `x`
  /// axis, and the `scaleY` argument provides the scalar by which to multiply
  /// the `y` axis. Either may be omitted, in which case the scaling factor for
  /// that axis defaults to 1.0.
  ///
  /// For convenience, to scale the child uniformly, instead of providing
  /// `scaleX` and `scaleY`, the `scale` parameter may be used.
  ///
  /// At least one of `scale`, `scaleX`, and `scaleY` must be non-null. If
  /// `scale` is provided, the other two must be null; similarly, if it is not
  /// provided, one of the other two must be provided.
  ///
  /// The [alignment] controls the origin of the scale; by default, this is
  /// the center of the box.
  ScaleEffect({
    double? scale,
    double? scaleX,
    double? scaleY,
    this.origin,
    this.alignment = Alignment.center,
    this.transformHitTests = true,
    this.filterQuality,
  })  : assert(!(scale == null && scaleX == null && scaleY == null),
            "At least one of 'scale', 'scaleX' and 'scaleY' is required to be non-null"),
        assert(scale == null || (scaleX == null && scaleY == null),
            "If 'scale' is non-null then 'scaleX' and 'scaleY' must be left null"),
        transform = Matrix4.diagonal3Values(
            scale ?? scaleX ?? 1.0, scale ?? scaleY ?? 1.0, 1.0);

  @override
  Widget apply(
    BuildContext context,
    Widget child,
    ScaleEffect begin,
    double value,
  ) {
    return Transform(
      transform: Matrix4.diagonal3Values(value, value, 1),
      origin: origin,
      alignment: alignment,
      transformHitTests: transformHitTests,
      filterQuality: filterQuality,
      child: child,
    );
  }
}

/// An effect that translates its child along the 2D plane during a scroll
/// animation.
class OffsetEffect extends ScrollEffect {
  /// The horizontal translation to apply to the child.
  final double x;

  /// The vertical translation to apply to the child.
  final double y;

  /// Whether to apply the transformation when performing hit tests.
  final bool transformHitTests;

  /// The filter quality with which to apply the transform as a bitmap operation.
  final FilterQuality? filterQuality;

  /// Creates a widget that translates its child along the 2D plane.
  ///
  /// The `x` argument provides the horizontal translation to apply to the
  /// child, and the `y` argument provides the vertical translation to apply to
  /// the child.
  const OffsetEffect({
    this.x = 0,
    this.y = 0,
    this.transformHitTests = true,
    this.filterQuality,
  });

  @override
  Widget apply(
    BuildContext context,
    Widget child,
    OffsetEffect begin,
    double value,
  ) {
    final double x = lerpDouble(begin.x, this.x, value) ?? 0;
    final double y = lerpDouble(begin.y, this.y, value) ?? 0;
    return Transform.translate(
      offset: Offset(x, y),
      child: child,
    );
  }
}

extension GlobalKeyExtension on GlobalKey {
  Rect? get globalPaintBounds {
    final renderObject = currentContext?.findRenderObject();
    final translation = renderObject?.getTransformTo(null).getTranslation();
    if (translation != null && renderObject?.paintBounds != null) {
      return renderObject!.paintBounds.shift(
        Offset(translation.x, translation.y),
      );
    } else {
      return null;
    }
  }
}

extension BuildContextExtension on BuildContext {
  Rect? get globalPaintBounds {
    final renderObject = findRenderObject();
    final translation = renderObject?.getTransformTo(null).getTranslation();
    if (translation != null && renderObject?.paintBounds != null) {
      return renderObject!.paintBounds.shift(
        Offset(translation.x, translation.y),
      );
    } else {
      return null;
    }
  }
}

extension RenderBoxExtension on RenderObject {
  Rect get globalPaintBounds {
    final translation = getTransformTo(null).getTranslation();
    return paintBounds.shift(Offset(translation.x, translation.y));
  }
}
