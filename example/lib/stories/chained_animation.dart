import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

class ChainedAnimation extends StatefulWidget {
  const ChainedAnimation({super.key});

  @override
  State<ChainedAnimation> createState() => _ChainedAnimationState();
}

class _ChainedAnimationState extends State<ChainedAnimation> {
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
            .translateY(selected ? 300 : 0)
            .animate(
                toggle: selected,
                curve: selected ? Curves.easeOutQuart : Curves.elasticOut,
                duration: Duration(milliseconds: selected ? 1000 : 450),
                onEnd: () {
                  if (selected) {
                    setState(() {
                      selected = false;
                    });
                  }
                }),
      ),
    );
  }
}
