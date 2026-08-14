import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

/// SIMPLE: one effect type, four keyframes, one controller.
///
/// Every tap restarts the timeline — a trigger is an identity signal.
class TimelinePulseButton extends StatefulWidget {
  const TimelinePulseButton({super.key});

  @override
  State<TimelinePulseButton> createState() => _TimelinePulseButtonState();
}

class _TimelinePulseButtonState extends State<TimelinePulseButton> {
  int taps = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'The simplest timeline: scale keyframes 1 → 0.9 → 1.06 → 1.\n'
            'Every tap restarts it from the beginning.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          FilledButton(
            onPressed: () => setState(() => taps++),
            child: Text('Saved $taps times'),
          )
              .scale(1)
              .step(
                duration: const Duration(milliseconds: 90),
                curve: Curves.easeOut,
              )
              .scale(0.9)
              .step(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutBack,
              )
              .scale(1.06)
              .step(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeInOut,
              )
              .scale(1)
              .timeline(trigger: taps),
        ],
      ),
    );
  }
}
