import 'package:hyper_effects/hyper_effects.dart';
import 'package:material_ui/material_ui.dart';

/// PHYSICS: real spring motion on both tiers — a `.animate(motion:)` toggle
/// that retargets with a bouncy spring, and a timeline step driven by
/// spring physics instead of a curve.
class SpringMotionStory extends StatefulWidget {
  const SpringMotionStory({super.key});

  @override
  State<SpringMotionStory> createState() => _SpringMotionStoryState();
}

class _SpringMotionStoryState extends State<SpringMotionStory> {
  bool right = false;
  int pops = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Springs are Motions: no duration, no curve — physics.\n'
            'The slider retargets with a bouncy spring; the badge pops\n'
            'on a spring-driven timeline step.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: 320,
            height: 72,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(36),
              ),
              child: Center(
                child: const CircleAvatar(radius: 24, child: Icon(Icons.bolt))
                    // .animate(motion:) retargets with spring physics:
                    // each toggle springs from the captured current
                    // position toward the new anchor.
                    .translateX(right ? 120 : -120)
                    .animate(
                      trigger: right,
                      motion: const CupertinoMotion.bouncy(),
                    ),
              ),
            ),
          ),
          const SizedBox(height: 48),
          Badge(
            isLabelVisible: pops > 0,
            label: Text('$pops'),
            child: const Icon(Icons.celebration, size: 56),
          )
              // A timeline step needs no duration or curve when a spring
              // drives it: the segment's length IS the settling time.
              .scale(0)
              .step(motion: const CupertinoMotion.bouncy())
              .scale(1)
              .timeline(trigger: pops),
          const SizedBox(height: 48),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: () => setState(() => right = !right),
                child: const Text('Toggle'),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () => setState(() => pops++),
                child: const Text('Pop'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
