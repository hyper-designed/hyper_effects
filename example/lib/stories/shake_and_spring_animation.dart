import 'package:material_ui/material_ui.dart';
import 'package:hyper_effects/hyper_effects.dart';

class SpringAnimation extends StatefulWidget {
  const SpringAnimation({super.key});

  @override
  State<SpringAnimation> createState() => _SpringAnimationState();
}

class _SpringAnimationState extends State<SpringAnimation> {
  /// Whether the drop-and-spring timeline is currently running.
  bool dropping = false;

  /// Counts drops; the timeline's identity trigger.
  int drops = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          if (dropping) return;
          setState(() {
            dropping = true;
            drops++;
          });
        },
        child: Image.asset('assets/pin_ball_256x.png', width: 150, height: 150)
            // The idle shake stays on .animate: ShakeEffect reads its
            // animation value from EffectQuery, which timelines do not
            // provide.
            .shake()
            // #immediate starts the idle shake on mount; each `dropping`
            // flip re-drives it, with playIf silencing it during the drop.
            .animate(
              trigger: dropping ? true : #immediate,
              delay: const Duration(seconds: 1),
              repeat: -1,
              playIf: () => !dropping,
            )
            // The drop-and-spring is one timeline: fall to 300, then spring
            // back to an absolute 0 — no -300 counter-translation needed.
            .translateY(0)
            .step(
              duration: const Duration(milliseconds: 2000),
              curve: Curves.easeOutQuart,
            )
            .translateY(300)
            .step(
              duration: const Duration(milliseconds: 450),
              curve: Curves.elasticOut,
            )
            .translateY(0)
            .timeline(
              trigger: drops,
              onEnd: () => setState(() => dropping = false),
            ),
      ),
    );
  }
}
