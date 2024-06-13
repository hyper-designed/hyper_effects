import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

class SuccessCardAnimation extends StatefulWidget {
  const SuccessCardAnimation({super.key});

  @override
  State<SuccessCardAnimation> createState() => _SuccessCardAnimationState();
}

class _SuccessCardAnimationState extends State<SuccessCardAnimation> {
  bool isCompleted = true;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 350,
        maxHeight: 200,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            setState(() {
              isCompleted = !isCompleted;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              constraints: const BoxConstraints(minHeight: 148),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  alignment: Alignment.center,
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/fashion/fashion_0.jpg',
                      fit: BoxFit.cover,
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0x3A079455),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.check_circle,
                          size: 74,
                        )
                            .translateY(
                              isCompleted ? 0 : 100,
                              from: isCompleted ? 100 : 0,
                            )
                            .animate(
                              trigger: isCompleted,
                              startState:
                                  AnimationStartState.useCurrentValues,
                              curve: !isCompleted
                                  ? Curves.easeInBack
                                  : Curves.easeOutBack,
                              duration: const Duration(
                                milliseconds: 400,
                              ),
                            ),
                      )
                          .opacity(
                            isCompleted ? 1 : 0,
                            from: isCompleted ? 0 : 1,
                          )
                          .animate(
                            trigger: isCompleted,
                            startState:
                                AnimationStartState.useCurrentValues,
                            curve: Curves.easeInOutSine,
                            duration: const Duration(
                              milliseconds: 400,
                            ),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
