import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

import '../../../helpers/alchemist_config.dart';

void main() => withTextRendering(() {
      goldenTest(
        'blur_reveal — Latin progress snapshots',
        fileName: 'blur_reveal_progress_goldens',
        builder: () => GoldenTestGroup(
          scenarioConstraints: const BoxConstraints(maxWidth: 500),
          children: [
            for (final p in const [0.0, 0.25, 0.5, 0.75, 1.0])
              GoldenTestScenario(
                name: 'progress ${p.toStringAsFixed(2)}',
                child: _ProgressScene(
                  progress: p,
                  text: 'Hello, World!',
                  fontFamily: 'TestLatin',
                  direction: TextDirection.ltr,
                ),
              ),
          ],
        ),
      );

      goldenTest(
        'blur_reveal — scripts & speeds',
        fileName: 'blur_reveal_scripts_goldens',
        builder: () => GoldenTestGroup(
          scenarioConstraints: const BoxConstraints(maxWidth: 500),
          children: [
            GoldenTestScenario(
              name: 'arabic mid-reveal',
              child: const _ProgressScene(
                progress: 0.5,
                text: 'مرحبا',
                fontFamily: 'TestArabic',
                direction: TextDirection.rtl,
              ),
            ),
            GoldenTestScenario(
              name: 'arabic settled',
              child: const _ProgressScene(
                progress: 1.0,
                text: 'مرحبا',
                fontFamily: 'TestArabic',
                direction: TextDirection.rtl,
              ),
            ),
            GoldenTestScenario(
              name: 'devanagari mid-reveal',
              child: const _ProgressScene(
                progress: 0.5,
                text: 'नमस्ते',
                fontFamily: 'TestDevanagari',
                direction: TextDirection.ltr,
              ),
            ),
            GoldenTestScenario(
              name: 'fast speedReveal = 3.0 at mid-progress',
              child: const _ProgressScene(
                progress: 0.4,
                text: 'Hello',
                fontFamily: 'TestLatin',
                direction: TextDirection.ltr,
                speedReveal: 3.0,
              ),
            ),
            GoldenTestScenario(
              name: 'slow speedReveal = 0.75 at mid-progress',
              child: const _ProgressScene(
                progress: 0.4,
                text: 'Hello',
                fontFamily: 'TestLatin',
                direction: TextDirection.ltr,
                speedReveal: 0.75,
              ),
            ),
            GoldenTestScenario(
              name: 'no rise — riseFrom Offset.zero at mid-progress',
              child: const _ProgressScene(
                progress: 0.5,
                text: 'Hello',
                fontFamily: 'TestLatin',
                direction: TextDirection.ltr,
                riseFrom: Offset.zero,
              ),
            ),
          ],
        ),
      );
    });

class _ProgressScene extends StatelessWidget {
  const _ProgressScene({
    required this.progress,
    required this.text,
    required this.fontFamily,
    required this.direction,
    this.speedReveal = 1.0,
    this.riseFrom = const Offset(0, 12),
  });

  final double progress;
  final String text;
  final String fontFamily;
  final TextDirection direction;
  final double speedReveal;
  final Offset riseFrom;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: direction,
      child: DefaultTextStyle(
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: 48,
          color: const Color(0xFF111111),
        ),
        child: Container(
          color: const Color(0xFFFFFFFF),
          padding: const EdgeInsets.all(24),
          child: EffectQuery(
            linearValue: progress,
            curvedValue: progress,
            isTransition: false,
            child: Text(text).blurReveal(
              speedReveal: speedReveal,
              riseFrom: riseFrom,
            ),
          ),
        ),
      ),
    );
  }
}
