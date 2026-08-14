import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

/// COMPLEX: multi-track entrance choreography (slide + fade + scale with
/// distinct curves), driven imperatively — dismissal is the same timeline
/// played in reverse via a [TimelineController].
class TimelineToast extends StatefulWidget {
  const TimelineToast({super.key});

  @override
  State<TimelineToast> createState() => _TimelineToastState();
}

class _TimelineToastState extends State<TimelineToast> {
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
            'Three tracks — slide, fade, scale — choreographed on one\n'
            'timeline. Dismiss plays the same timeline backwards.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.inverseSurface,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              child: Text(
                'Changes saved',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onInverseSurface,
                ),
              ),
            ),
          )
              // Keyframe 0: parked below, invisible, slightly shrunken.
              .translateY(80)
              .opacity(0)
              .scale(0.92)
              .step(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutQuart,
              )
              // Keyframe 1: overshoots a touch above its seat, fully
              // opaque. Opacity is absent from keyframe 2 and carries
              // forward automatically.
              .translateY(-8)
              .opacity(1)
              .scale(1.03)
              .step(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutBack,
              )
              // Keyframe 2: seated.
              .translateY(0)
              .scale(1)
              .timeline(controller: controller),
          const SizedBox(height: 48),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: () => unawaited(controller.play()),
                child: const Text('Show'),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () => unawaited(controller.reverse()),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
