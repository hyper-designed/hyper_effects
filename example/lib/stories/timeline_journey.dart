import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

/// The looping journey formerly built from oneShot + animateAfter chains +
/// resetAll: the ball travels a circuit forever, restarting seamlessly.
///
/// Keyframes are absolute positions, the last keyframe matches the first,
/// and `trigger: #immediate` with `repeat: -1` loops the single controller — no reset snapping.
class TimelineJourney extends StatelessWidget {
  const TimelineJourney({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset('assets/pin_ball_256x.png', width: 150, height: 150)
          .translateXY(-100, 0)
          .step(duration: const Duration(milliseconds: 350))
          .translateXY(100, 0)
          .step(duration: const Duration(milliseconds: 350))
          .translateXY(100, 200)
          .step(duration: const Duration(milliseconds: 350))
          .translateXY(-100, 200)
          .step(duration: const Duration(milliseconds: 350))
          .translateXY(-100, 0)
          .timeline(trigger: #immediate, repeat: -1),
    );
  }
}
