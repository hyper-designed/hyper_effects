import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'animated_effect.dart';
import 'extensions.dart';
import 'scroll_phase.dart';

/// A function that builds a widget based on the current phase of the scroll
/// animation.
typedef ScrollTransitionBuilder = Widget Function(
  BuildContext context,
  Widget widget,
  ScrollPhase phase,
);

typedef CustomScrollTransitionBuilder = Widget Function(
  BuildContext context,
  Widget widget,
  ScrollPhase phase,
  ScrollPosition position,
);

extension ScrollTransitionExt on Widget {
  Widget scrollTransition(int index, ScrollTransitionBuilder builder) {
    return ScrollTransition(
      index: index,
      builder: (context, widget, phase, position) =>
          builder(context, widget, phase),
      child: this,
    );
  }

  Widget customScrollTransition(
      int index, CustomScrollTransitionBuilder builder) {
    return ScrollTransition(
      index: index,
      builder: (context, widget, phase, position) =>
          builder(context, widget, phase, position),
      child: this,
    );
  }
}

/// A widget that applies a set of effects to its child based on the current
/// phase and position of the scroll position of the parent scrollable widget.
class ScrollTransition extends StatefulWidget {
  /// The index of the scroll animation in the parent scrollable widget.
  final int index;

  /// A function that builds a widget based on the current phase of the scroll
  /// animation.
  final CustomScrollTransitionBuilder? builder;

  /// The child widget to apply the effects to.
  final Widget child;

  /// Creates a widget that applies a set of effects to its child based on the
  /// current phase and position of the scroll position of the parent scrollable
  /// widget.
  const ScrollTransition({
    super.key,
    required this.child,
    this.builder,
    this.index = 0,
  });

  @override
  State<ScrollTransition> createState() => _ScrollTransitionState();
}

class _ScrollTransitionState extends State<ScrollTransition> {
  /// The parent scrollable widget.
  ScrollableState? scrollable;

  ScrollPosition? scrollPosition;

  /// The current phase of the scroll animation.
  ScrollPhase currentPhase = ScrollPhase.identity;

  /// The current animation value indicating the progress of the scroll
  /// animation through its phase in the parent viewport.
  double currentValue = 0;

  bool isFirstFrame = true;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      isFirstFrame = false;
      updateCurrentState();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    scrollable = Scrollable.maybeOf(context);
    if (scrollPosition != scrollable?.position) {
      scrollPosition?.removeListener(onScrollChanged);
      scrollPosition = scrollable?.position;
      scrollPosition?.addListener(onScrollChanged);
    }
  }

  @override
  void dispose() {
    scrollPosition?.removeListener(onScrollChanged);
    scrollPosition = null;
    scrollable = null;
    super.dispose();
  }

  /// Calculates the current phase of the scroll animation.
  /// Returns a record of the current phase and it's associated progress
  /// through the viewport as a value between 0 and 1.
  ({ScrollPhase phase, double value}) calculatePhase() {
    if (scrollable case var scrollable?) {
      final viewPort = scrollable.context.globalPaintBounds;
      final paintBounds = context.globalPaintBounds;

      if (paintBounds != null && viewPort != null) {
        final double paintBoundsStart = scrollPosition!.axis == Axis.vertical
            ? paintBounds.top
            : paintBounds.left;
        final double paintBoundsEnd = scrollPosition!.axis == Axis.vertical
            ? paintBounds.bottom
            : paintBounds.right;
        final double paintBoundsSize = scrollPosition!.axis == Axis.vertical
            ? paintBounds.height
            : paintBounds.width;

        final double viewPortStart = scrollPosition!.axis == Axis.vertical
            ? viewPort.top
            : viewPort.left;
        final double viewPortEnd = scrollPosition!.axis == Axis.vertical
            ? viewPort.bottom
            : viewPort.right;

        if (viewPort.contains(paintBounds.topLeft) &&
            viewPort.contains(paintBounds.bottomRight)) {
          // completely inside the viewport. no effects.
          return (phase: ScrollPhase.identity, value: 1);
        } else if (viewPortStart > paintBoundsStart) {
          // Cutting at the top.
          double value = (viewPortStart - paintBoundsStart) / paintBoundsSize;
          value = value.clamp(0, 1);
          if (scrollPosition!.atStart) value = 0;
          return (phase: ScrollPhase.topLeading, value: value);
        } else if (viewPortEnd < paintBoundsEnd) {
          double value = (paintBoundsEnd - viewPortEnd) / paintBoundsSize;
          value = value.clamp(0, 1);
          if (scrollPosition!.atEnd) value = 0;
          return (phase: ScrollPhase.bottomTrailing, value: value);
        }
      }
    }
    return (phase: ScrollPhase.identity, value: 1);
  }

  /// Calculates the current phase of the scroll animation and its associated
  /// progress through the viewport as a value between 0 and 1.
  ///
  /// If the phase or value has changed, the current phase and value are updated
  /// and the effects are recalculated.
  ///
  /// If the [onChanged] callback is provided, it is called if the phase or
  /// value has changed.
  void updateCurrentState() {
    final (:phase, :value) = calculatePhase();
    if (phase != currentPhase || value != currentValue) {
      currentPhase = phase;
      currentValue = value;
      if (mounted) setState(() {});
    }
  }

  /// Called when the parent scrollable widget sends a notification that the
  /// scroll position has changed.
  void onScrollChanged() => updateCurrentState();

  @override
  Widget build(BuildContext context) {
    Widget child = scrollable != null
        ? widget.builder
                ?.call(context, widget.child, currentPhase, scrollPosition!) ??
            widget.child
        : widget.child;

    final visible = !isFirstFrame || scrollable == null;

    return Visibility(
      visible: visible,
      maintainSize: true,
      maintainState: true,
      maintainAnimation: true,
      child: EffectAnimationValue(
        value: currentValue,
        isTransition: true,
        child: child,
      ),
    );
  }
}
