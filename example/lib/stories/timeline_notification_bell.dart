import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

/// MEDIUM: a damped bell swing — many keyframes of one type plus a second
/// track (scale pop), restarted by a counting trigger.
class TimelineNotificationBell extends StatefulWidget {
  const TimelineNotificationBell({super.key});

  @override
  State<TimelineNotificationBell> createState() =>
      _TimelineNotificationBellState();
}

class _TimelineNotificationBellState extends State<TimelineNotificationBell> {
  int notifications = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'A damped swing: five rotation keyframes and a scale pop,\n'
            'restarted by every new notification.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          // The timeline wraps the Badge (not the other way around): Badge
          // reparents its child when the label first appears, which would
          // dispose a timeline nested inside it.
          Badge(
            isLabelVisible: notifications > 0,
            label: Text('$notifications'),
            child: const Icon(Icons.notifications, size: 64),
          )
              .rotate(0, alignment: Alignment.topCenter)
              .scale(1)
              .step(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
              )
              .rotate(0.35, alignment: Alignment.topCenter)
              .scale(1.15)
              .step(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeInOut,
              )
              .rotate(-0.25, alignment: Alignment.topCenter)
              .scale(1)
              .step(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeInOut,
              )
              .rotate(0.12, alignment: Alignment.topCenter)
              .step(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutBack,
              )
              .rotate(0, alignment: Alignment.topCenter)
              .timeline(trigger: notifications),
          const SizedBox(height: 48),
          OutlinedButton(
            onPressed: () => setState(() => notifications++),
            child: const Text('Notify'),
          ),
        ],
      ),
    );
  }
}
