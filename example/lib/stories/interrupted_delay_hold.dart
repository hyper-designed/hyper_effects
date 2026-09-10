import 'package:hyper_effects/hyper_effects.dart';
import 'package:material_ui/material_ui.dart';

import 'story_scaffold.dart';

class InterruptedDelayHoldStory extends StatefulWidget {
  const InterruptedDelayHoldStory({super.key});

  @override
  State<InterruptedDelayHoldStory> createState() =>
      _InterruptedDelayHoldStoryState();
}

class _InterruptedDelayHoldStoryState extends State<InterruptedDelayHoldStory> {
  static const _delay = Duration(milliseconds: 700);

  int trigger = 0;
  bool right = false;
  bool holding = false;
  int _statusGeneration = 0;

  Future<void> _drive({required bool retarget}) async {
    final generation = ++_statusGeneration;
    setState(() {
      if (retarget) right = !right;
      trigger++;
      holding = true;
    });
    await Future<void>.delayed(_delay);
    if (!mounted || generation != _statusGeneration) return;
    setState(() => holding = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return StoryScaffold(
      title: 'Interrupted Delay Hold',
      description: 'Retrigger mid-flight. The marker freezes exactly where it '
          'was interrupted, waits, then continues without a snap.',
      maxWidth: 620,
      children: [
        const SizedBox(height: 32),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color:
                holding ? colors.tertiaryContainer : colors.secondaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(holding ? 'HOLDING · 700 MS' : 'READY'),
        ),
        const SizedBox(height: 28),
        Container(
          width: 420,
          height: 96,
          padding: const EdgeInsets.symmetric(horizontal: 36),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(48),
          ),
          child: Center(
            child: Container(
              key: const Key('delay-hold-marker'),
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.32),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(Icons.pause_rounded, color: colors.onPrimary),
            ).translateX(right ? 150 : -150).animate(
                  trigger: trigger,
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeInOutCubic,
                  delay: _delay,
                ),
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () => _drive(retarget: false),
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Retrigger same target'),
            ),
            OutlinedButton.icon(
              onPressed: () => _drive(retarget: true),
              icon: const Icon(Icons.swap_horiz_rounded),
              label: const Text('Retarget opposite side'),
            ),
          ],
        ),
      ],
    );
  }
}
