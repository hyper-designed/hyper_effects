import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

import '../../../../helpers/alchemist_config.dart';

void main() => withTextRendering(() {
      goldenTest(
        'shaped_rolling_latin',
        fileName: 'shaped_rolling_latin',
        builder: () => GoldenTestGroup(
          scenarioConstraints: const BoxConstraints(maxWidth: 500),
          children: [
            GoldenTestScenario(
              name: 'Hello — settled',
              child: const _Scene(
                text: 'Hello',
                progress: 1.0,
                fontFamily: 'TestLatin',
                direction: TextDirection.ltr,
              ),
            ),
            GoldenTestScenario(
              name: 'Hello — mid-reveal',
              child: const _Scene(
                text: 'Hello',
                progress: 0.5,
                fontFamily: 'TestLatin',
                direction: TextDirection.ltr,
              ),
            ),
            GoldenTestScenario(
              name: 'number counter — settled',
              child: const _Scene(
                text: '1000',
                progress: 1.0,
                fontFamily: 'TestLatin',
                direction: TextDirection.ltr,
              ),
            ),
          ],
        ),
      );

      goldenTest(
        'shaped_rolling_complex_scripts',
        fileName: 'shaped_rolling_complex_scripts',
        builder: () => GoldenTestGroup(
          scenarioConstraints: const BoxConstraints(maxWidth: 500),
          children: [
            GoldenTestScenario(
              name: 'arabic مرحبا settled',
              child: const _Scene(
                text: 'مرحبا',
                progress: 1.0,
                fontFamily: 'TestArabic',
                direction: TextDirection.rtl,
              ),
            ),
            GoldenTestScenario(
              name: 'arabic mid-reveal',
              child: const _Scene(
                text: 'مرحبا',
                progress: 0.5,
                fontFamily: 'TestArabic',
                direction: TextDirection.rtl,
              ),
            ),
            GoldenTestScenario(
              name: 'japanese さよなら settled',
              child: const _Scene(
                text: 'さよなら',
                progress: 1.0,
                fontFamily: 'TestJapanese',
                direction: TextDirection.ltr,
              ),
            ),
            GoldenTestScenario(
              name: 'devanagari settled',
              child: const _Scene(
                text: 'नमस्ते',
                progress: 1.0,
                fontFamily: 'TestDevanagari',
                direction: TextDirection.ltr,
              ),
            ),
          ],
        ),
      );
    });

class _Scene extends StatelessWidget {
  const _Scene({
    required this.text,
    required this.progress,
    required this.fontFamily,
    required this.direction,
  });

  final String text;
  final double progress;
  final String fontFamily;
  final TextDirection direction;

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
          padding: const EdgeInsets.all(16),
          child: EffectQuery(
            linearValue: progress,
            curvedValue: progress,
            isTransition: false,
            child: Text(text).roll(
              renderMode: TextRenderMode.contextualCharacters,
            ),
          ),
        ),
      ),
    );
  }
}
