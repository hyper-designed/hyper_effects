import 'package:flutter/widgets.dart';

import 'effect_query.dart';
import 'extensions.dart';
import 'post_frame_widget.dart';
import 'scroll_phase.dart';

/// Represents the scroll event for [ScrollTransition].
class ScrollTransitionEvent {
  /// The current phase of the scroll animation on given [Widget].
  final ScrollPhase phase;

  /// The current progress an element's phase is going through.
  /// If [phase] is identity this value is 1.
  /// If [phase] is topLeading, it goes from 0 towards 1 as it leaves the
  /// screen.
  /// If [phase] is bottomTrailing, it goes from 0 towards 1 as it enters the
  /// screen.
  final double phaseOffsetFraction;

  /// The current progress an element is going through the scrolling viewport.
  /// If the item is near the center of the scroll view, the value tends towards
  /// 0.
  /// As the item moves towards the ceiling of the scroll view, the value tends
  /// towards 1. It clamps to 1 when the item is fully out of the scroll view.
  /// As the item moves towards the floor of the scroll view, the value tends
  /// towards -1. It clamps to -1 when the item is fully out of the scroll view.
  final double screenOffsetFraction;

  /// The number of pixels scrolled inside of the parent scroll view.
  final double? scrollPixels;

  /// The height or width of the parent scroll view.
  final double? viewportSize;

  /// The change in scroll position since the last update.
  final double scrollDelta;

  /// The direction the scroll view is being scrolled to.
  final AxisDirection scrollDirection;

  /// The position of the pointer device in the global coordinate space.
  final Offset pointerPosition;

  /// The distance from the pointer device to the center of this widget.
  final Offset distanceFromPointer;

  /// The visual index is the index in which the item is displayed in the
  /// scroll view. For example, instead of the regular index of a list,
  /// if you scroll down, the first item that is visible inside the scroll view
  /// will have some arbitrary index, but the visual index would be 0 as it is
  /// the index that is perceived by the user.
  final int visualIndex;

  /// The [visualIndex] calculated in the opposite direction.
  final int reverseVisualIndex;

  /// Creates a [ScrollTransitionEvent].
  ScrollTransitionEvent({
    required this.phase,
    required this.phaseOffsetFraction,
    required this.screenOffsetFraction,
    required this.scrollPixels,
    required this.viewportSize,
    required this.scrollDelta,
    required this.scrollDirection,
    required this.pointerPosition,
    required this.distanceFromPointer,
    required this.visualIndex,
    required this.reverseVisualIndex,
  });
}

/// A function that builds a widget based on the current phase of the scroll
/// animation.
typedef ScrollTransitionBuilder = Widget Function(
  BuildContext context,
  Widget widget,
  ScrollTransitionEvent event,
);

/// Provides extension methods for [Widget] to apply scroll transition effects.
extension ScrollTransitionExt on Widget {
  /// Applies scroll transition effects to this widget.
  Widget scrollTransition(ScrollTransitionBuilder builder) {
    return ScrollTransition(
      builder: builder,
      child: this,
    );
  }
}

/// A widget that applies a set of effects to its child based on the current
/// phase and position of the scroll position of the parent scrollable widget.
class ScrollTransition extends StatefulWidget {
  /// A function that builds a widget based on the current phase of the scroll
  /// animation.
  final ScrollTransitionBuilder? builder;

  /// The child widget to apply the effects to.
  final Widget child;

  /// Whether this transition should rely on
  /// [WidgetsBinding.instance.pointerRouter.addGlobalRoute] to read
  /// the pointer device's position, which is useful for reading cursor
  /// events that may not be read properly via [MouseRegion]s like if the
  /// cursor is outside the bounds of the physical window or applies some
  /// unusual gesture that may not be normally detected.
  ///
  /// If set to false, a traditional [MouseRegion] is used to read
  /// the pointer device's position.
  final bool usePointerRouter;

  /// Creates a new [ScrollTransition] with the given [builder] and [child].
  const ScrollTransition({
    super.key,
    required this.child,
    this.builder,
    this.usePointerRouter = true,
  });

  @override
  State<ScrollTransition> createState() => _ScrollTransitionState();
}

class _ScrollTransitionState extends State<ScrollTransition> {
  /// The parent scrollable widget.
  ScrollableState? scrollable;

  /// The current scroll position of the parent scrollable widget.
  ScrollPosition? scrollPosition;

  /// The current phase of the scroll animation.
  ScrollPhase phase = ScrollPhase.identity;

  /// The current animation value indicating the progress of the scroll
  /// animation through its phase in the parent viewport.
  double phaseOffsetFraction = 0;

  /// The current animation value indicating the progress of the scroll
  /// animation through the parent viewport.
  double screenOffsetFraction = 0;

  /// Keeps track of the last scroll position in pixels.
  /// This is used to calculate the [_scrollDelta].
  double? _lastScrollPixels;

  /// The change in scroll position since the last update.
  double _scrollDelta = 0;

  /// The position of the pointer device in the global coordinate space.
  Offset _pointerPosition = Offset.zero;

  /// The distance from the pointer device that was used to trigger the
  /// scroll transition effect to the center of this widget.
  Offset _distanceFromPointer = Offset.zero;

  /// The visual index is the index in which the item is displayed in the
  /// scroll view. For example, instead of the regular index of a list,
  /// if you scroll down, the first item that is visible inside the scroll view
  /// will have some arbitrary index, but the visual index would be 0 as it is
  /// the index that is perceived by the user.
  int _visualIndex = 0;

  /// The visual index calculated in the opposite direction.
  int _reverseVisualIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.usePointerRouter) {
      WidgetsBinding.instance.pointerRouter.addGlobalRoute(updateState);
    }
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
  void didUpdateWidget(covariant ScrollTransition oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.usePointerRouter != widget.usePointerRouter) {
      if (widget.usePointerRouter) {
        WidgetsBinding.instance.pointerRouter.addGlobalRoute(updateState);
      } else {
        WidgetsBinding.instance.pointerRouter.removeGlobalRoute(updateState);
      }
    }
  }

  @override
  void dispose() {
    scrollPosition?.removeListener(onScrollChanged);
    scrollPosition = null;
    scrollable = null;

    if (widget.usePointerRouter) {
      WidgetsBinding.instance.pointerRouter.removeGlobalRoute(updateState);
    }

    super.dispose();
  }

  void updateState(PointerEvent event) {
    _pointerPosition = event.position;
  }

  /// Calculates the current phase of the scroll animation.
  /// Returns a record of the current phase and it's associated progress
  /// through the viewport as a value between 0 and 1.
  ({
    ScrollPhase phase,
    double phaseOffsetFraction,
    double screenOffsetFraction,
  }) calculatePhase() {
    if (scrollable case var scrollable?) {
      final viewPort = scrollable.context.globalPaintBounds;
      final paintBounds = context.globalPaintBounds;

      if (paintBounds != null && viewPort != null) {
        final bool isVertical = scrollPosition!.axis == Axis.vertical;
        final double paintBoundsStart =
            isVertical ? paintBounds.top : paintBounds.left;
        final double paintBoundsEnd =
            isVertical ? paintBounds.bottom : paintBounds.right;
        final double paintBoundsSize =
            isVertical ? paintBounds.height : paintBounds.width;

        final double viewPortStart = isVertical ? viewPort.top : viewPort.left;
        final double viewPortEnd =
            isVertical ? viewPort.bottom : viewPort.right;

        final bool doesFit = isVertical
            ? viewPort.top <= paintBounds.top &&
                viewPort.bottom >= paintBounds.bottom
            : viewPort.left <= paintBounds.left &&
                viewPort.right >= paintBounds.right;

        double screenOffsetFraction = isVertical
            ? (viewPort.center.dy - paintBounds.center.dy) / viewPort.height
            : (viewPort.center.dx - paintBounds.center.dx) / viewPort.width;
        screenOffsetFraction *= 2;

        if (doesFit) {
          return (
            phase: ScrollPhase.identity,
            phaseOffsetFraction: 1.0,
            screenOffsetFraction: screenOffsetFraction
          );
        } else if (viewPortStart > paintBoundsStart) {
          // Cutting at the top.
          double value = (viewPortStart - paintBoundsStart) / paintBoundsSize;
          value = value.clamp(0, 1);
          if (scrollPosition!.atStart) value = 0;
          return (
            phase: ScrollPhase.topLeading,
            phaseOffsetFraction: value,
            screenOffsetFraction: screenOffsetFraction,
          );
        } else if (viewPortEnd < paintBoundsEnd) {
          double value = (paintBoundsEnd - viewPortEnd) / paintBoundsSize;
          value = value.clamp(0, 1);
          if (scrollPosition!.atEnd) value = 0;
          return (
            phase: ScrollPhase.bottomTrailing,
            phaseOffsetFraction: value,
            screenOffsetFraction: screenOffsetFraction,
          );
        }
      }
    }
    return (
      phase: ScrollPhase.identity,
      phaseOffsetFraction: 1,
      screenOffsetFraction: screenOffsetFraction,
    );
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
    if (!mounted) return;

    final (:phase, :phaseOffsetFraction, :screenOffsetFraction) =
        calculatePhase();
    this.phase = phase;
    this.phaseOffsetFraction = phaseOffsetFraction;
    this.screenOffsetFraction = screenOffsetFraction;
    final double currentPixels =
        scrollPosition?.hasPixels == true ? scrollPosition!.pixels : 0.0;
    _scrollDelta =
        _lastScrollPixels != null ? currentPixels - _lastScrollPixels! : 0;
    _lastScrollPixels = currentPixels;
    _distanceFromPointer = _pointerPosition - context.globalPaintBounds!.center;

    final distanceToTopOfView = context.globalPaintBounds!.top -
        scrollable!.context.globalPaintBounds!.top;
    final distanceToBottomOfView = context.globalPaintBounds!.bottom -
        scrollable!.context.globalPaintBounds!.bottom;
    final visualIndex =
        (distanceToTopOfView / context.globalPaintBounds!.height).ceil();
    final reverseVisualIndex =
        (distanceToBottomOfView / context.globalPaintBounds!.height).ceil();
    if (visualIndex != _visualIndex) {
      _visualIndex = visualIndex;
    }
    if (reverseVisualIndex != _reverseVisualIndex) {
      _reverseVisualIndex = reverseVisualIndex;
    }

    if (mounted) setState(() {});
  }

  /// Called when the parent scrollable widget sends a notification that the
  /// scroll position has changed.
  void onScrollChanged() => updateCurrentState();

  /// Called after the first frame is rendered.
  void onPostFrame() => updateCurrentState();

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (scrollable != null) {
      child = widget.builder?.call(
              context,
              widget.child,
              ScrollTransitionEvent(
                phase: phase,
                phaseOffsetFraction: phaseOffsetFraction,
                screenOffsetFraction: screenOffsetFraction,
                scrollPixels: scrollPosition?.hasPixels == true
                    ? scrollPosition!.pixels
                    : null,
                viewportSize: scrollPosition?.hasViewportDimension == true
                    ? scrollPosition!.viewportDimension
                    : null,
                scrollDelta: _scrollDelta,
                scrollDirection:
                    scrollPosition?.axisDirection ?? AxisDirection.down,
                pointerPosition: _pointerPosition,
                distanceFromPointer: _distanceFromPointer,
                visualIndex: _visualIndex,
                reverseVisualIndex: _reverseVisualIndex,
              )) ??
          widget.child;
    } else {
      child = widget.child;
    }

    return PostFrame(
      enabled: scrollable != null,
      onPostFrame: onPostFrame,
      child: EffectQuery(
        curvedValue: phaseOffsetFraction,
        linearValue: phaseOffsetFraction,
        isTransition: true,
        child: child,
      ),
    );
  }
}
