import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

class WindowsSettingsTransition extends StatefulWidget {
  const WindowsSettingsTransition({super.key});

  @override
  State<WindowsSettingsTransition> createState() =>
      _WindowsSettingsTransitionState();
}

class _WindowsSettingsTransitionState extends State<WindowsSettingsTransition> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, i) => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                color: Color(0xFF404040),
              ),
              child: Transform.scale(
                scale: 2,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      focalRadius: 10000,
                      colors: [
                        Colors.white.withOpacity(0.5),
                        Colors.white.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ).pointerTransition(
                transitionBetweenBounds: false,
                resetOnExitBounds: false,
                (context, child, event) => child
                    .opacity(
                      event.isInsideBounds ? 1 : 0,
                    )
                    .animate(
                      trigger: event.isInsideBounds,
                      duration: const Duration(milliseconds: 150),
                    )
                    .translateXY(
                      event.valueOffset.dx / 2,
                      event.valueOffset.dy / 2,
                      fractional: true,
                    ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(1),
              decoration: const BoxDecoration(
                color: Color(0xFF404040),
              ),
              clipBehavior: Clip.antiAlias,
              child: Transform.scale(
                scale: 2,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ).pointerTransition(
                transitionBetweenBounds: false,
                resetOnExitBounds: false,
                (context, child, event) => child
                    .opacity(
                      event.isInsideBounds ? 1 : 0,
                    )
                    .animate(
                      trigger: event.isInsideBounds,
                      duration: const Duration(milliseconds: 150),
                    )
                    .translateXY(
                      event.valueOffset.dx / 2,
                      event.valueOffset.dy / 2,
                      fractional: true,
                    ),
              ),
            ),
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$i',
                style: const TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
