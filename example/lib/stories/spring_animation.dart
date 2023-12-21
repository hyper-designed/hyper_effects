import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

class SpringAnimation extends StatefulWidget {
  const SpringAnimation({super.key});

  @override
  State<SpringAnimation> createState() => _SpringAnimationState();
}

class _SpringAnimationState extends State<SpringAnimation> {
  bool selected = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selected = !selected;
          });
        },
        child: Image.asset('assets/pin_ball_256x.png', width: 150, height: 150)
            .translateY(300, from: 0)
            .animate(
              toggle: selected,
              curve: Curves.easeOutQuart,
              duration: const Duration(milliseconds: 1000),
            )
            .slideOut(const Offset(0, -300))
            .animateAfter(
              curve: Curves.elasticOut,
              duration: const Duration(milliseconds: 450),
            )
            .resetAll(),
      ),
    );
  }
}
