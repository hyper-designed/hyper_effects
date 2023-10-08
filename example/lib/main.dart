import 'package:example/stories/windows_settings_transition.dart';
import 'package:example/stories/scroll_phase_transition.dart';
import 'package:example/stories/scroll_wheel_transition.dart';
import 'package:flutter/material.dart';
import 'package:storybook_flutter/storybook_flutter.dart';

import 'stories/scroll_wheel_blur.dart';

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
          Story(
            name: 'Scroll Phase Blur',
            description:
                'A focus effect where elements outside the view are blurred',
            builder: (context) => const ScrollWheelBlurTransition(),
          ),
          Story(
            name: 'Pointer Transition',
            description: 'Moves elements slightly with the pointer',
            builder: (context) => const WindowsSettingsTransition(),
          ),
        ],
      ),
    );
  }
}
