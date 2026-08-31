import 'dart:async';
import 'dart:math';

import 'package:hyper_effects/hyper_effects.dart';
import 'package:material_ui/material_ui.dart';

class SuccessCardAnimation extends StatefulWidget {
  const SuccessCardAnimation({super.key});

  @override
  State<SuccessCardAnimation> createState() => _SuccessCardAnimationState();
}

class _SuccessCardAnimationState extends State<SuccessCardAnimation> {
  bool isCompleted = false;

  /// The completion state the first card is animating away from.
  ///
  /// Before the first tap there is no previous state, so this matches
  /// [isCompleted] and every effect's `from` equals its target. The card
  /// therefore mounts at rest, hidden, rather than animating on its first
  /// frame. After a tap it holds the state just left behind, which is what
  /// makes the slide and fade reverse cleanly without snapping.
  bool previouslyCompleted = false;

  /// Drives the stamp card. The timeline plays forward on completion and
  /// reverses on un-completion; direction is imperative, not trigger-based.
  final TimelineController stampController = TimelineController();

  @override
  void dispose() {
    stampController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      previouslyCompleted = isCompleted;
      isCompleted = !isCompleted;
    });
    if (isCompleted) {
      unawaited(stampController.play());
    } else {
      unawaited(stampController.reverse());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 350,
            maxHeight: 200,
          ),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _toggle,
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
                                  from: previouslyCompleted ? 0 : 100,
                                )
                                .animate(
                                  trigger: isCompleted,
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
                                from: previouslyCompleted ? 1 : 0,
                              )
                              .animate(
                                trigger: isCompleted,
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
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 350,
            maxHeight: 200,
          ),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _toggle,
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
                                // A "stamp": slam in overshooting at 1.5x
                                // and tilted, hold, then settle to rest.
                                // Keyframe values are absolute — the settle
                                // targets 1.0 directly, no reciprocals.
                                child: const Icon(
                                  Icons.check_circle,
                                  size: 74,
                                )
                                    .scale(0)
                                    .rotate(0)
                                    .step(
                                      duration:
                                          const Duration(milliseconds: 350),
                                      curve: Curves.easeOutQuart,
                                    )
                                    .scale(1.5)
                                    .rotate(15 * pi / 180)
                                    .step(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeOutBack,
                                      delay: const Duration(milliseconds: 150),
                                    )
                                    .scale(1)
                                    .rotate(0)
                                    .timeline(controller: stampController))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
