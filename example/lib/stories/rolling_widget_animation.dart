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
          ClipRect(
            child: Stack(
              key: ValueKey(counter),
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/fashion/fashion_${counter % 8}.jpg',
                  height: 500,
                  cacheHeight: 500,
                ),
                // const Positioned.fill(child: Center(child: CircularProgressIndicator())),
              ],
            )
                .rollWidget(
                  slideInDirection: SlideDirection.left,
                  slideOutDirection: SlideDirection.left,
                )
                .animate(
                  trigger: counter,
                  curve: Curves.easeInOutQuart,
                  duration: Duration(milliseconds: 500),
                ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                counter++;
              });
            },
            child: const Text('Roll'),
          ),
        ],
      ),
    );
  }
}
