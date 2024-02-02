import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

class SpringAnimation extends StatefulWidget {
  const SpringAnimation({super.key});

  @override
  State<SpringAnimation> createState() => _SpringAnimationState();
}

class _SpringAnimationState extends State<SpringAnimation> {
  bool trigger = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          setState(() {
            trigger = !trigger;
          });
        },
        child: Image.asset('assets/pin_ball_256x.png', width: 150, height: 150)
            .shake()
            .animate(
              trigger: trigger,
              startImmediately: true,
              delay: const Duration(seconds: 1),
              repeat: -1,
              playIf: () => !trigger,
            )
            .translateY(300, from: 0)
            .animate(
              trigger: trigger,
              curve: Curves.easeOutQuart,
              duration: const Duration(milliseconds: 2000),
              playIf: () => trigger,
            )
            .translateY(-300, from: 0)
            .animateAfter(
              curve: Curves.elasticOut,
              duration: const Duration(milliseconds: 450),
              onEnd: () => setState(() => trigger = false),
            )
            .resetAll(),
      ),
    );
  }
}
