import 'package:hyper_effects/hyper_effects.dart';
import 'package:material_ui/material_ui.dart';

import 'story_scaffold.dart';

class SpringLifecycleStory extends StatefulWidget {
  const SpringLifecycleStory({super.key});

  @override
  State<SpringLifecycleStory> createState() => _SpringLifecycleStoryState();
}

class _SpringLifecycleStoryState extends State<SpringLifecycleStory> {
  final animationKey = GlobalKey<AnimatedEffectState>();

  int trigger = 0;
  bool right = false;
  int repeat = 0;
  bool reverse = false;
  String status = 'AT START · RESTING';
  int _statusGeneration = 0;

  void _playReverse() {
    final generation = ++_statusGeneration;
    setState(() {
      right = true;
      repeat = 1;
      reverse = true;
      trigger++;
      status = 'FORWARD → FRESH REVERSE';
    });
    _settleLabel(generation, 'AT START · RESTING');
  }

  void _retarget() {
    final generation = ++_statusGeneration;
    setState(() {
      right = !right;
      repeat = 0;
      reverse = false;
      trigger++;
      status = 'RETARGET · MOMENTUM CARRIED';
    });
    _settleLabel(
        generation, right ? 'AT RIGHT · RESTING' : 'AT START · RESTING');
  }

  void _reset() {
    _statusGeneration++;
    animationKey.currentState?.reset();
    setState(() {
      status = 'AT START · RESTING';
    });
  }

  void _replay() {
    final generation = ++_statusGeneration;
    setState(() {
      repeat = 0;
      reverse = false;
      trigger++;
      status = 'REPLAY · ZERO INITIAL VELOCITY';
    });
    _settleLabel(
        generation, right ? 'AT RIGHT · RESTING' : 'AT START · RESTING');
  }

  Future<void> _settleLabel(int generation, String label) async {
    await Future<void>.delayed(const Duration(milliseconds: 1700));
    if (!mounted || generation != _statusGeneration) return;
    setState(() => status = label);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return StoryScaffold(
      title: 'Spring Lifecycle',
      description: 'Reverse settles forward through physical time. Retargets '
          'carry live momentum; completed replays and resets start clean.',
      children: [
        const SizedBox(height: 24),
        Chip(
          avatar: const Icon(Icons.monitor_heart_outlined, size: 18),
          label: Text(status),
        ),
        const SizedBox(height: 24),
        Container(
          width: 460,
          height: 112,
          padding: const EdgeInsets.symmetric(horizontal: 44),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Center(
            child: Container(
              key: const Key('spring-lifecycle-marker'),
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.primary, colors.tertiary],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.bolt_rounded, color: colors.onPrimary),
            ).translateX(right ? 155 : -155, from: -155).animate(
                  key: animationKey,
                  trigger: trigger,
                  motion: const CupertinoMotion.bouncy(),
                  repeat: repeat,
                  reverse: reverse,
                ),
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: _playReverse,
              icon: const Icon(Icons.sync_alt_rounded),
              label: const Text('Play + reverse'),
            ),
            OutlinedButton(
              onPressed: _retarget,
              child: const Text('Retarget now'),
            ),
            OutlinedButton(
              onPressed: _reset,
              child: const Text('Reset mid-reverse'),
            ),
            OutlinedButton(
              onPressed: _replay,
              child: const Text('Replay from rest'),
            ),
          ],
        ),
      ],
    );
  }
}
