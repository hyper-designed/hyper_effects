import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

class OneShotResetAnimation extends StatefulWidget {
  const OneShotResetAnimation({super.key});

  @override
  State<OneShotResetAnimation> createState() => _OneShotResetAnimationState();
}

class _OneShotResetAnimationState extends State<OneShotResetAnimation> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset('assets/pin_ball_256x.png', width: 150, height: 150)
          // Step 1
          .translateX(100, from: -100)
          .oneShot()
          // Step 2
          .slideOutToBottom()
          .animateAfter()
          // Step 3
          .slideOutToLeft(value: -200)
          .animateAfter()
          // Step 4
          .slideOutToTop()
          .animateAfter()
          .resetAll(),
    );
  }
}
