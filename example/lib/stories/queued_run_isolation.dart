import 'package:hyper_effects/hyper_effects.dart';
import 'package:material_ui/material_ui.dart';

import 'story_scaffold.dart';

class QueuedRunIsolationStory extends StatefulWidget {
  const QueuedRunIsolationStory({super.key});

  @override
  State<QueuedRunIsolationStory> createState() =>
      _QueuedRunIsolationStoryState();
}

class _QueuedRunIsolationStoryState extends State<QueuedRunIsolationStory> {
  int trigger = 0;
  Duration duration = const Duration(milliseconds: 450);
  int repeat = 0;
  bool reverse = false;
  String label = 'Quick';
  final completed = <String>[];

  void _enqueue({
    required String nextLabel,
    required Duration nextDuration,
    required int nextRepeat,
    required bool nextReverse,
  }) {
    setState(() {
      label = nextLabel;
      duration = nextDuration;
      repeat = nextRepeat;
      reverse = nextReverse;
      trigger++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final completionLabel = label;
    return StoryScaffold(
      title: 'Queued Run Isolation',
      description: 'Queue contrasting non-interruptible runs. The active run '
          'keeps its own timing, repeat, direction, and completion label.',
      maxWidth: 680,
      children: [
        const SizedBox(height: 32),
        Container(
          width: 460,
          height: 92,
          padding: const EdgeInsets.symmetric(horizontal: 42),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              key: const Key('queue-marker'),
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.layers_rounded, color: colors.onPrimary),
            ).translateX(320, from: 0).animate(
                  trigger: trigger,
                  duration: duration,
                  curve: Curves.easeInOutCubic,
                  repeat: repeat,
                  reverse: reverse,
                  interruptable: false,
                  onEnd: () => setState(() {
                    completed.add(completionLabel);
                  }),
                ),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton(
              onPressed: () => _enqueue(
                nextLabel: 'Quick',
                nextDuration: const Duration(milliseconds: 450),
                nextRepeat: 0,
                nextReverse: false,
              ),
              child: const Text('Quick · once'),
            ),
            OutlinedButton(
              onPressed: () => _enqueue(
                nextLabel: 'Bounce',
                nextDuration: const Duration(milliseconds: 700),
                nextRepeat: 1,
                nextReverse: true,
              ),
              child: const Text('Bounce · reverse'),
            ),
            OutlinedButton(
              onPressed: () => _enqueue(
                nextLabel: 'Slow',
                nextDuration: const Duration(milliseconds: 900),
                nextRepeat: 1,
                nextReverse: false,
              ),
              child: const Text('Slow · repeat'),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Completion order',
              style: Theme.of(context).textTheme.titleMedium),
        ),
        const SizedBox(height: 10),
        if (completed.isEmpty)
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('No runs completed yet'),
          )
        else
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < completed.length; i++)
                  Chip(label: Text('${i + 1} · ${completed[i]}')),
              ],
            ),
          ),
      ],
    );
  }
}
