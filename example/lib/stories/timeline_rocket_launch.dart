import 'dart:async';

import 'package:hyper_effects/hyper_effects.dart';
import 'package:material_ui/material_ui.dart';

/// VERY COMPLEX: a five-track launch sequence — pre-ignition shake, crouch,
/// liftoff, and burn-out — with a full external transport: play, pause,
/// reverse, restart, and a scrubber that seeks the timeline by hand.
class TimelineRocketLaunch extends StatefulWidget {
  const TimelineRocketLaunch({super.key});

  @override
  State<TimelineRocketLaunch> createState() => _TimelineRocketLaunchState();
}

class _TimelineRocketLaunchState extends State<TimelineRocketLaunch> {
  final TimelineController controller = TimelineController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'A launch sequence on one timeline: shake, crouch, liftoff,\n'
            'burn-out. Scrub it, pause it, or play it backwards.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 320,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: const Icon(Icons.rocket, size: 96)
                  // Keyframe 0: on the pad.
                  .translateXY(0, 0)
                  .scale(1)
                  .rotate(0)
                  .opacity(1)
                  .step(duration: const Duration(milliseconds: 120))
                  // Pre-ignition shake: left...
                  .translateXY(-4, 0)
                  .step(duration: const Duration(milliseconds: 120))
                  // ...right...
                  .translateXY(4, 0)
                  .step(
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeIn,
                  )
                  // ...and a crouch before the jump.
                  .translateXY(0, 0)
                  .scale(1.06)
                  .step(
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeInQuart,
                    delay: const Duration(milliseconds: 100),
                  )
                  // Liftoff: accelerate away, shrinking with distance.
                  .translateXY(0, -240)
                  .scale(0.72)
                  .rotate(0.06)
                  .step(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOut,
                  )
                  // Burn-out: gone.
                  .translateXY(0, -400)
                  .scale(0.45)
                  .opacity(0)
                  .timeline(controller: controller),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Play',
                icon: const Icon(Icons.play_arrow),
                onPressed: () => unawaited(controller.play()),
              ),
              IconButton(
                tooltip: 'Pause',
                icon: const Icon(Icons.pause),
                onPressed: controller.pause,
              ),
              IconButton(
                tooltip: 'Reverse',
                icon: const Icon(Icons.fast_rewind),
                onPressed: () => unawaited(controller.reverse()),
              ),
              IconButton(
                tooltip: 'Restart',
                icon: const Icon(Icons.replay),
                onPressed: () {
                  controller.seek(0);
                  unawaited(controller.play());
                },
              ),
            ],
          ),
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final progress =
                  controller.isAttached ? controller.progress : 0.0;
              return SizedBox(
                width: 400,
                child: Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: progress,
                        onChanged: controller.seek,
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text('${(progress * 100).round()}%'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
