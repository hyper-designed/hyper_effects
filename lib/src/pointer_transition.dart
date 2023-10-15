import 'package:flutter/widgets.dart';
import 'package:hyper_effects/src/post_frame_widget.dart';

import 'apple_curves.dart';
import 'effect_animation_value.dart';

/// Represents the pointer event for [PointerTransition].
class PointerTransitionEvent {
  /// The position of the pointer device from the top left corner of the
  /// target.
  final Offset position;

  /// Defines the distance of the pointer device from the [origin].
  /// A value of zero is when the pointer device is at the [origin].
  /// A value of 1 or -1 is when the pointer device is at the farthest point
  /// from the [origin].
  ///
  /// This value is the average of the [valueOffset]'s x and y values.
  final double value;

  /// Defines the distance of the pointer device from the [origin] as an offset.
  /// A value offset of (0, 0) is when the pointer device is at the [origin].
  /// A value offset of (1, 1) is when the pointer device is at the farthest
  /// point from the [origin].
  final Offset valueOffset;

  /// Whether the pointer device is inside the bounds of the widget.
  final bool isInsideBounds;

  /// Creates a new [PointerTransitionEvent] with the given [position],
  /// [value], [valueOffset], and [isInsideBounds].
  const PointerTransitionEvent({
    required this.position,
    required this.value,
    required this.valueOffset,
    required this.isInsideBounds,
  });
}

/// A function that builds a widget based on the current position of the pointer
/// device.
typedef PointerTransitionBuilder = Widget Function(
  BuildContext context,
  Widget widget,
  PointerTransitionEvent event,
);

/// Provides extension methods for [Widget] to apply scroll transition effects.
extension PointerTransitionExt on Widget {
  /// Applies pointer transition effects to this widget.
  Widget pointerTransition(
    PointerTransitionBuilder builder, {
    Alignment origin = Alignment.center,
    bool useGlobalPointer = false,
    bool transitionBetweenBounds = true,
    bool resetOnExitBounds = true,
    Curve curve = appleEaseInOut,
    Duration duration = const Duration(milliseconds: 125),
  }) {
    return PointerTransition(
      builder: builder,
      origin: origin,
      useGlobalPointer: useGlobalPointer,
      transitionBetweenBounds: transitionBetweenBounds,
      resetOnExitBounds: resetOnExitBounds,
      curve: curve,
      duration: duration,
      child: this,
    );
  }
}

/// A widget that applies a set of effects to its child based on the current
/// position of the pointer device.
class PointerTransition extends StatefulWidget {
  /// A function that builds a widget based on the current position of the
  /// pointer device.
  final PointerTransitionBuilder? builder;

  /// Defines where the origin of the pointer should be.
  /// If the origin is set to [Alignment.center], as the pointer moves away
  /// from the center of the screen, the [value] value will increase.
  /// If the origin is set to [Alignment.topLeft], as the pointer moves away
  /// from the top left corner of the screen, the [value] value will
  /// increase.
  final Alignment origin;

  /// Decides whether this transition calculates the value based on the global
  /// position of the pointer device or the local position of the pointer
  /// device.
  final bool useGlobalPointer;

  /// Decides whether this transition should transition between when the pointer
  /// device is inside the bounds of the widget or outside the bounds of the
  final bool transitionBetweenBounds;

  /// Decides whether this transition should reset the position of the child
  /// back to a value of zero when the pointer device is outside the bounds of
  /// the widget.
  final bool resetOnExitBounds;

  /// The child widget to apply the effects to.
  final Widget child;

  /// The curve of the animation to use when the position of the [child] is
  /// about to reset.
  final Curve curve;

  /// The duration of the animation to use when the position of the [child] is
  /// about to reset.
  final Duration duration;

  /// Creates a new [PointerTransition] with the given [builder], [origin],
  /// [useGlobalPointer], [child], [curve], and [duration].
  const PointerTransition({
    super.key,
    required this.child,
    this.origin = Alignment.center,
    this.useGlobalPointer = false,
    this.transitionBetweenBounds = true,
    this.resetOnExitBounds = true,
    this.builder,
    this.curve = appleEaseInOut,
    this.duration = const Duration(milliseconds: 125),
  });

  @override
  State<PointerTransition> createState() => _PointerTransitionState();
}

class _PointerTransitionState extends State<PointerTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  late Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: widget.curve,
  );

  final GlobalKey _key = GlobalKey();

  /// The global position of the pointer device from the top left corner of the
  /// screen.
  Offset? globalPosition;

  /// The local position of the pointer device from the top left corner of the
  /// widget.
  Offset? localPosition;

  /// The latest value the pointer device is at.
  double newValue = 0;

  /// The latest value offset the pointer device is at.
  Offset newValueOffset = Offset.zero;

  /// The current value the pointer device is at.
  double currentValue = 0;

  /// The current value offset the pointer device is at.
  Offset currentValueOffset = Offset.zero;

  /// The last value the pointer device was at before the current value.
  Offset lastValueOffset = Offset.zero;

  /// The last value offset the pointer device was at before the current value.
  double lastValue = 0;

  /// Whether the pointer device was inside the bounds of the widget.
  bool wasInsideBounds = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.pointerRouter.addGlobalRoute(updateState);
    _controller.addListener(animationListener);
  }

  @override
  void didUpdateWidget(covariant PointerTransition oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }

    if (widget.curve != oldWidget.curve) {
      _animation = CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      );
    }
  }

  void animationListener() {
    currentValueOffset = Offset.lerp(
      lastValueOffset,
      newValueOffset,
      _animation.value,
    )!;
    currentValue = (currentValueOffset.dx + currentValueOffset.dy) / 2;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(animationListener);
    _controller.dispose();
    WidgetsBinding.instance.pointerRouter.removeGlobalRoute(updateState);
    super.dispose();
  }

  void updateState(PointerEvent event) {
    globalPosition = event.position;
    recalculateValue();
  }

  /// Calculates the current value offset of the pointer device based on the
  /// [origin] and [globalPosition].
  void recalculateValue() {
    if (globalPosition == null) {
      if (mounted) setState(() {});
      return;
    }

    if (widget.useGlobalPointer) {
      final screenSize = MediaQuery.of(context).size;

      if (globalPosition!.dx < 0 ||
          globalPosition!.dy < 0 ||
          globalPosition!.dx > screenSize.width ||
          globalPosition!.dy > screenSize.height) {
        resetValue();
      } else {
        final screenOriginPosition = widget.origin.alongSize(screenSize);
        final globalValue = globalPosition! - screenOriginPosition;
        final globalValueOffset = Offset(
          globalValue.dx / screenSize.width,
          globalValue.dy / screenSize.height,
        );

        final offset = Offset(
          globalValueOffset.dx * 2,
          globalValueOffset.dy * 2,
        );
        final value = (offset.dx + offset.dy) / 2;

        if (!wasInsideBounds) {
          wasInsideBounds = true;
          lastValueOffset = currentValueOffset;
          lastValue = newValue;

          if (widget.transitionBetweenBounds) {
            newValueOffset = offset;
            newValue = value;
            _controller.forward(from: 0);
          } else {
            currentValueOffset = newValueOffset = offset;
            currentValue = newValue = value;
          }
        } else {
          currentValueOffset = newValueOffset = offset;
          currentValue = newValue = value;
        }
      }
    } else {
      final obj = _key.currentContext?.findRenderObject();
      if (obj case RenderBox box) {
        localPosition = box.globalToLocal(globalPosition!);
        final widgetSize = box.size;

        if (localPosition!.dx < 0 ||
            localPosition!.dy < 0 ||
            localPosition!.dx > widgetSize.width ||
            localPosition!.dy > widgetSize.height) {
          resetValue();
        } else {
          final localOriginPosition = widget.origin.alongSize(widgetSize);
          final localValue = localPosition! - localOriginPosition;
          final localValueOffset = Offset(
            localValue.dx / widgetSize.width,
            localValue.dy / widgetSize.height,
          );
          final offset = Offset(
            localValueOffset.dx * 2,
            localValueOffset.dy * 2,
          );
          final value = (offset.dx + offset.dy) / 2;

          if (!wasInsideBounds) {
            wasInsideBounds = true;
            lastValueOffset = currentValueOffset;
            lastValue = newValue;

            if (widget.transitionBetweenBounds) {
              newValueOffset = offset;
              newValue = value;
              _controller.forward(from: 0);
            } else {
              currentValueOffset = newValueOffset = offset;
              currentValue = newValue = value;
            }
          } else {
            currentValueOffset = newValueOffset = offset;
            currentValue = newValue = value;
          }
        }
      }
    }

    if (mounted) setState(() {});
  }

  void resetValue() {
    if (!widget.resetOnExitBounds) {
      wasInsideBounds = false;
      return;
    }

    const Offset offset = Offset.zero;
    const double value = 0;

    if (wasInsideBounds) {
      wasInsideBounds = false;
      lastValueOffset = currentValueOffset;
      lastValue = currentValue;

      if (widget.transitionBetweenBounds) {
        newValueOffset = offset;
        newValue = value;
        _controller.forward(from: 0);
      } else {
        currentValueOffset = newValueOffset = offset;
        currentValue = newValue = value;
      }
    } else {
      currentValueOffset = newValueOffset = offset;
      currentValue = newValue = value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget child = widget.builder?.call(
          context,
          widget.child,
          PointerTransitionEvent(
            position: globalPosition ?? Offset.zero,
            value: currentValue,
            valueOffset: currentValueOffset,
            isInsideBounds: wasInsideBounds,
          ),
        ) ??
        widget.child;

    return PostFrameWidget(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) => EffectAnimationValue(
          value: currentValue,
          isTransition: true,
          lerpValues: false,
          child: KeyedSubtree(
            key: _key,
            child: child!,
          ),
        ),
        child: child,
      ),
    );
  }
}
