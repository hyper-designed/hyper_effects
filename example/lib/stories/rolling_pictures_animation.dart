import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

class RollingWidgetAnimation extends StatefulWidget {
  const RollingWidgetAnimation({super.key});

  @override
  State<RollingWidgetAnimation> createState() => _RollingWidgetAnimationState();
}

class _RollingWidgetAnimationState extends State<RollingWidgetAnimation> {
  int counter = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          (counter % 9 == 8
                  ? null
                  : Image.asset(
                      'assets/fashion/fashion_${counter % 9}.jpg',
                      key: ValueKey(counter),
                      height: 500 + (counter % 2 == 0 ? 0 : 100),
                      cacheHeight: 500 + (counter % 2 == 0 ? 0 : 100),
                    ))
              .roll(
                slideInDirection: AxisDirection.up,
                slideOutDirection: AxisDirection.left,
              )
              .clip(0)
              .animate(
                trigger: counter,
                curve: Curves.easeInOutQuart,
                duration: const Duration(milliseconds: 500),
              ),
          Align(
            alignment: Alignment.topCenter,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  counter++;
                });
              },
              child: const Text('Roll'),
            ),
          ),
        ],
      ),
    );
  }
}
