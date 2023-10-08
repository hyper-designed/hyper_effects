import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

class ScrollWheelTransition extends StatefulWidget {
  const ScrollWheelTransition({super.key});

  @override
  State<ScrollWheelTransition> createState() => _ScrollWheelTransitionState();
}

class _ScrollWheelTransitionState extends State<ScrollWheelTransition> {
  Color randomColor(int index) {
    final r = Random(index * 100).nextInt(255);
    final g = Random(index * 200).nextInt(255);
    final b = Random(index * 300).nextInt(255);
    return Color.fromARGB(255, r, g, b);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) {
        return Container(
          width: 350,
          height: 100,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: randomColor(index),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Item $index',
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
            ),
          ),
        ).scrollTransition((context, widget, event) => TransformEffect(
              rotateX: -90 * event.screenOffsetFraction * pi / 180,
              translateY: (event.screenOffsetFraction * -1) * 200,
              translateZ: event.screenOffsetFraction.abs() * 100,
              scaleX: 1 - (event.screenOffsetFraction.abs() / 2),
              depth: 0.002,
            ).apply(context, widget));
      },
    );
  }
}
