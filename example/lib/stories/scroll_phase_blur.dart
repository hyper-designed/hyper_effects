import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

class ScrollWheelBlurTransition extends StatefulWidget {
  const ScrollWheelBlurTransition({super.key});

  @override
  State<ScrollWheelBlurTransition> createState() =>
      _ScrollWheelBlurTransitionState();
}

class _ScrollWheelBlurTransitionState extends State<ScrollWheelBlurTransition> {
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
        ).scrollTransition(
          (context, widget, event) => widget
              .blur(
                switch (event.phase) {
                  ScrollPhase.identity => 0,
                  ScrollPhase.topLeading => 10,
                  ScrollPhase.bottomTrailing => 10,
                },
              )
              .scale(
                switch (event.phase) {
                  ScrollPhase.identity => 1,
                  ScrollPhase.topLeading => 0.9,
                  ScrollPhase.bottomTrailing => 0.9,
                },
              ),
        );
      },
    );
  }
}
