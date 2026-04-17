import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

import '../../helpers/alchemist_config.dart';
import '../../helpers/test_app.dart';

void main() => withTextRendering(() {
  goldenTest(
    'rolling_stagger_baseline',
    fileName: 'rolling_stagger_goldens',
    builder: () => GoldenTestGroup(
      scenarioConstraints: const BoxConstraints(maxWidth: 400),
      children: [
        GoldenTestScenario(
          name: 'stagger up',
          child: const _Scene(direction: TextTapeSlideDirection.up),
        ),
        GoldenTestScenario(
          name: 'stagger down',
          child: const _Scene(direction: TextTapeSlideDirection.down),
        ),
        GoldenTestScenario(
          name: 'alternating',
          child: const _Scene(direction: TextTapeSlideDirection.alternating),
        ),
        GoldenTestScenario(
          name: 'staggerTapes disabled',
          child: const _Scene(
            direction: TextTapeSlideDirection.up,
            staggerTapes: false,
          ),
        ),
        GoldenTestScenario(
          name: 'staggerSoftness 50',
          child: const _Scene(
            direction: TextTapeSlideDirection.up,
            staggerSoftness: 50,
          ),
        ),
      ],
    ),
  );
});

class _Scene extends StatelessWidget {
  const _Scene({
    required this.direction,
    this.staggerTapes = true,
    this.staggerSoftness = 10,
  });
  final TextTapeSlideDirection direction;
  final bool staggerTapes;
  final int staggerSoftness;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: 'TestLatin',
          fontSize: 48,
          color: Color(0xFF111111),
        ),
        child: Container(
          color: const Color(0xFFFFFFFF),
          padding: const EdgeInsets.all(16),
          child: const Text('abcd')
              .roll(
                renderMode: kLegacyRenderMode,
                tapeSlideDirection: direction,
                staggerTapes: staggerTapes,
                staggerSoftness: staggerSoftness,
              )
              .animate(
                trigger: 1,
                duration: const Duration(milliseconds: 400),
              ),
        ),
      ),
    );
  }
}
