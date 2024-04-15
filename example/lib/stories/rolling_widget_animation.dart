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
            // clipBehavior: Clip.none,
            child: (counter % 9 == 8
                    ? null
                    : Stack(
                        key: ValueKey(counter),
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            'assets/fashion/fashion_${counter % 9}.jpg',
                            height: 500 + (counter % 2 == 0 ? 0 : 100),
                            cacheHeight: 500 + (counter % 2 == 0 ? 0 : 100),
                          ),
                          const Positioned.fill(
                              child:
                                  Center(child: CircularProgressIndicator())),
                        ],
                      ))
                .roll(
                  slideInDirection: AxisDirection.up,
                  slideOutDirection: AxisDirection.left,
                )
                .animate(
                  trigger: counter,
                  curve: Curves.easeInOutQuart,
                  duration: const Duration(milliseconds: 500),
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
