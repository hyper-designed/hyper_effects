import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

class OneShotAnimation extends StatefulWidget {
  const OneShotAnimation({super.key});

  @override
  State<OneShotAnimation> createState() => _OneShotAnimationState();
}

class _OneShotAnimationState extends State<OneShotAnimation> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset('assets/pin_ball_256x.png', width: 150, height: 150)
          .fadeIn()
          .slideInFromLeft()
          .blurIn()
          .oneShot() // child

          // Then 1
          .slideOutToBottom()
          .animateAfter()

          // // Then 2
          .slideOutToBottom()
          .animateAfter()

          // // Then 2
          .slideOutToBottom()
          .animateAfter()
          .resetAll()
    );
  }
}
