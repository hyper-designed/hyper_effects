import 'package:example/stories/scroll_phase_transition.dart';
import 'package:example/stories/scroll_wheel_transition.dart';
import 'package:flutter/material.dart';
import 'package:storybook_flutter/storybook_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hyper Effects Story Book',
      debugShowCheckedModeBanner: false,
      home: Storybook(
        stories: [
          Story(
            name: 'Scroll Phase Offset',
            description: 'Offsetting elements based on the phase of the scroll',
            builder: (context) => const ScrollPhaseTransition(),
          ),
          Story(
            name: 'Scroll Wheel Transition',
            description: 'Warping elements to mimic a cylindrical effect.',
            builder: (context) => const ScrollWheelTransition(),
          ),
        ],
      ),
    );
  }
}
