import 'package:flutter/material.dart';

import '../../../hyper_effects.dart';

extension RollEffectExtension on Widget {
  EffectWidget rollWidget({
    SlideDirection slideInDirection = SlideDirection.up,
    SlideDirection slideOutDirection = SlideDirection.right,
    double slideOutMultiplier = 1,
  }) =>
      EffectWidget(
        end: RollEffect(
          child: this,
          slideInDirection: slideInDirection,
          slideOutDirection: slideOutDirection,
          slideOutMultiplier: slideOutMultiplier,
        ),
        child: this,
      );
}

class RollEffect extends Effect {
  final Widget child;
  final SlideDirection slideInDirection;
  final SlideDirection slideOutDirection;
  final double slideOutMultiplier;

  const RollEffect({
    required this.child,
    this.slideInDirection = SlideDirection.up,
    this.slideOutDirection = SlideDirection.right,
    this.slideOutMultiplier = 1,
  });

  @override
  Effect lerp(covariant Effect other, double value) => other;

  @override
  Widget apply(BuildContext context, Widget child) => RollingEffectWidget(
        slideInDirection: slideInDirection,
        slideOutDirection: slideOutDirection,
        slideOutMultiplier: slideOutMultiplier,
        child: child,
      );

  @override
  List<Object?> get props => [child];
}

class RollingEffectWidget extends StatefulWidget {
  final Widget child;
  final SlideDirection slideInDirection;
  final SlideDirection slideOutDirection;
  final double slideOutMultiplier;

  const RollingEffectWidget({
    super.key,
    required this.child,
    this.slideOutDirection = SlideDirection.right,
    this.slideInDirection = SlideDirection.up,
    this.slideOutMultiplier = 1,
  });

  @override
  State<RollingEffectWidget> createState() => _RollingEffectWidgetState();
}

class _RollingEffectWidgetState extends State<RollingEffectWidget> {
  int retainedWidgets = 0;

  Widget? oldChild;
  final SnapshotController snapshotController = SnapshotController();

  @override
  void didUpdateWidget(covariant RollingEffectWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.child.key != widget.child.key) {
      oldChild = oldWidget.child;
      oldChild = SnapshotWidget(
        key: ValueKey(retainedWidgets++),
        mode: SnapshotMode.forced,
        controller: snapshotController,
        child: oldWidget.child,
      );
    }
  }

  @override
  void dispose() {
    snapshotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectAnimationValue = EffectQuery.maybeOf(context);

    final timeValue =
        (effectAnimationValue?.curvedValue ?? 1) - (oldChild == null ? 0 : 1);

    final slideInTime = switch (widget.slideInDirection) {
      SlideDirection.up || SlideDirection.left => -timeValue,
      SlideDirection.down || SlideDirection.right => timeValue,
    };
    final slideInOffset = switch (widget.slideInDirection) {
      SlideDirection.up || SlideDirection.down => Offset(0, slideInTime),
      SlideDirection.left || SlideDirection.right => Offset(slideInTime, 0),
    };

    final slideOutTime = switch (widget.slideOutDirection) {
      SlideDirection.up || SlideDirection.left => -timeValue - 1,
      SlideDirection.down || SlideDirection.right => timeValue + 1,
    };
    final slideOutOffset = switch (widget.slideOutDirection) {
      SlideDirection.up || SlideDirection.down => Offset(0, slideOutTime),
      SlideDirection.left || SlideDirection.right => Offset(slideOutTime, 0),
    };

    return RepaintBoundary(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (oldChild != null)
            FractionalTranslation(
              translation: slideOutOffset * widget.slideOutMultiplier,
              child: oldChild!,
            ),
          FractionalTranslation(
            translation: slideInOffset,
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
