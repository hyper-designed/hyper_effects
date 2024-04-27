import 'package:flutter/material.dart';

import '../../../hyper_effects.dart';

/// A builder that takes a [BuildContext] and a [Widget] and returns a [Widget].
typedef RollBuilder = Widget Function(
  BuildContext context,
  Widget child,
);

Widget _defaultRollInBuilder(BuildContext context, Widget child) => child;

Widget _defaultRollOutBuilder(BuildContext context, Widget child) => child;

/// Provides a extension method to apply an [RollEffect] to a [Widget].
extension RollEffectExtension on Widget? {
  /// Applies an [RollEffect] to a [Widget] with the given [slideInDirection],
  /// [slideOutDirection] and [multiplier].
  EffectWidget roll({
    AxisDirection slideInDirection = AxisDirection.up,
    AxisDirection slideOutDirection = AxisDirection.up,
    double multiplier = 1,
    bool useSnapshots = true,
    bool rollInitially = false,
    RollBuilder? rollInBuilder,
    RollBuilder? rollOutBuilder,
  }) =>
      EffectWidget(
        end: RollEffect(
          child: this,
          slideInDirection: slideInDirection,
          slideOutDirection: slideOutDirection,
          multiplier: multiplier,
          useSnapshots: useSnapshots,
          rollInitially: rollInitially,
          rollInBuilder: rollInBuilder ?? _defaultRollInBuilder,
          rollOutBuilder: rollOutBuilder ?? _defaultRollOutBuilder,
        ),
        child: this,
      );
}

/// An [Effect] that applies a roll animation to a [Widget] with the
/// given [slideInDirection], [slideOutDirection] and [multiplier].
class RollEffect extends Effect {
  /// The [Widget] to apply the effect to.
  final Widget? child;

  /// The direction to slide in the [Widget].
  final AxisDirection slideInDirection;

  /// The direction to slide out the [Widget].
  final AxisDirection slideOutDirection;

  /// The multiplier to apply to the slide out direction.
  final double multiplier;

  /// Determines whether the old [Widget]s that are being rolled away from
  /// should be rendered via a [SnapshotWidget] or just using the original
  /// widget directly.
  ///
  /// This may be needed in cases where state management of the old [Widget]s
  /// may be sensitive.
  final bool useSnapshots;

  /// Determines whether this effect starts from no widget and immediately rolls
  /// in the passed [child] immediately once triggered, or if this roll effect
  /// should only trigger if the [child] passed has changed from its initial
  /// or last state.
  final bool rollInitially;

  /// The builder to use when rolling in the [Widget].
  final RollBuilder rollInBuilder;

  /// The builder to use when rolling out the [Widget].
  final RollBuilder rollOutBuilder;

  /// Creates a [RollEffect] with the given parameters.
  const RollEffect({
    required this.child,
    this.slideInDirection = AxisDirection.up,
    this.slideOutDirection = AxisDirection.up,
    this.multiplier = 1,
    this.useSnapshots = true,
    this.rollInitially = false,
    this.rollInBuilder = _defaultRollInBuilder,
    this.rollOutBuilder = _defaultRollOutBuilder,
  });

  @override
  Effect lerp(covariant Effect other, double value) => other;

  @override
  Widget apply(BuildContext context, Widget? child) => RollingEffectWidget(
        slideInDirection: slideInDirection,
        slideOutDirection: slideOutDirection,
        multiplier: multiplier,
        useSnapshots: useSnapshots,
        rollInitially: rollInitially,
        rollInBuilder: rollInBuilder,
        rollOutBuilder: rollOutBuilder,
        child: child,
      );

  @override
  List<Object?> get props => [
        child,
        slideInDirection,
        slideOutDirection,
        multiplier,
        useSnapshots,
        rollInitially,
        rollInBuilder,
        rollOutBuilder,
      ];
}

/// A [StatefulWidget] that applies a roll animation to a [Widget].
class RollingEffectWidget extends StatefulWidget {
  /// The [Widget] to apply the effect to.
  final Widget? child;

  /// The direction to slide in the [Widget].
  final AxisDirection slideInDirection;

  /// The direction to slide out the [Widget].
  final AxisDirection slideOutDirection;

  /// The multiplier to apply to the slide out direction.
  final double multiplier;

  /// Determines whether the old [Widget]s that are being rolled away from
  /// should be rendered via a [SnapshotWidget] or just using the original
  /// widget directly.
  ///
  /// This may be needed in cases where state management of the old [Widget]s
  /// may be sensitive.
  final bool useSnapshots;

  /// Determines whether this effect starts from no widget and immediately rolls
  /// in the passed [child] once triggered, or if this roll effect
  /// should only trigger if the [child] passed has changed from its initial
  /// or last state.
  final bool rollInitially;

  /// The builder to use when rolling in the [Widget].
  final RollBuilder rollInBuilder;

  /// The builder to use when rolling out the [Widget].
  final RollBuilder rollOutBuilder;

  /// Creates a [RollingEffectWidget] with the given parameters.
  const RollingEffectWidget({
    super.key,
    required this.child,
    this.slideInDirection = AxisDirection.up,
    this.slideOutDirection = AxisDirection.up,
    this.multiplier = 1,
    this.useSnapshots = false,
    this.rollInitially = false,
    this.rollInBuilder = _defaultRollInBuilder,
    this.rollOutBuilder = _defaultRollOutBuilder,
  });

  @override
  State<RollingEffectWidget> createState() => _RollingEffectWidgetState();
}

class _RollingEffectWidgetState extends State<RollingEffectWidget> {
  final SnapshotController snapshotController =
      SnapshotController(allowSnapshotting: true);

  int retainedWidgets = 0;
  Widget? oldChild;

  late bool isInitialRoll = widget.rollInitially;

  bool get canRoll => isInitialRoll || oldChild != null;

  @override
  void didUpdateWidget(covariant RollingEffectWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.child?.key != widget.child?.key) {
      isInitialRoll = false;
      if (widget.useSnapshots) {
        oldChild = SnapshotWidget(
          key: ValueKey(retainedWidgets++),
          mode: SnapshotMode.forced,
          controller: snapshotController,
          child: oldWidget.child,
        );
      } else {
        oldChild = oldWidget.child;
      }
    }
  }

  @override
  void dispose() {
    snapshotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = EffectQuery.maybeOf(context);

    final timeValue = (query?.curvedValue ?? 1);

    final slideInTime = switch (widget.slideInDirection) {
      AxisDirection.up || AxisDirection.left => (canRoll ? 1 : 0) - timeValue,
      AxisDirection.down ||
      AxisDirection.right =>
        (canRoll ? -1 : 0) + timeValue,
    };
    final slideInOffset = switch (widget.slideInDirection) {
      AxisDirection.up || AxisDirection.down => Offset(0, slideInTime),
      AxisDirection.left || AxisDirection.right => Offset(slideInTime, 0),
    };

    final slideOutTime = switch (widget.slideOutDirection) {
      AxisDirection.up || AxisDirection.left => -timeValue,
      AxisDirection.down || AxisDirection.right => timeValue,
    };
    final slideOutOffset = switch (widget.slideOutDirection) {
      AxisDirection.up || AxisDirection.down => Offset(0, slideOutTime),
      AxisDirection.left || AxisDirection.right => Offset(slideOutTime, 0),
    };

    final child = widget.child == null
        ? null
        : widget.rollInBuilder(
            context,
            widget.child!,
          );

    late final oldRoll = FractionalTranslation(
      transformHitTests: false,
      translation: slideOutOffset * widget.multiplier,
      child: oldChild == null
          ? null
          : widget.rollOutBuilder(
              context,
              oldChild!,
            ),
    );

    late final double clampedTime = timeValue.clamp(0, 1);
    late final double reverseClampedTime = 1 - clampedTime;

    return AnimatedSize(
      duration: query?.duration ?? Duration.zero,
      curve: query?.curve ?? Curves.linear,
      clipBehavior: Clip.none,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (oldChild != null)
            child == null
                ? Align(
                    heightFactor: reverseClampedTime,
                    widthFactor: reverseClampedTime,
                    child: oldRoll,
                  )
                : Positioned.fill(
                    child: Align(
                      heightFactor: reverseClampedTime,
                      widthFactor: reverseClampedTime,
                      child: FittedBox(
                        fit: BoxFit.none,
                        child: oldRoll,
                      ),
                    ),
                  ),
          if (child != null)
            FractionalTranslation(
              transformHitTests: false,
              translation: slideInOffset * widget.multiplier,
              child: child,
            ),
        ],
      ),
    );
  }
}
