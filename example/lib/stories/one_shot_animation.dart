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
          .slideInFromBottom()
          .blurIn()
          .oneShot(
            duration: const Duration(milliseconds: 1000),
          ).then(context).slideOutToLeft().oneShot(),
    );
  }
}
