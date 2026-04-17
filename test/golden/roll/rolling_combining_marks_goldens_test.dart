import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

import '../../helpers/alchemist_config.dart';
import '../../helpers/test_app.dart';

void main() => withTextRendering(() {
  goldenTest(
    'rolling_combining_marks_baseline',
    fileName: 'rolling_combining_marks_goldens',
    builder: () => GoldenTestGroup(
      scenarioConstraints: const BoxConstraints(maxWidth: 400),
      children: [
        GoldenTestScenario(
          name: 'precomposed (NFC) cafe',
          child: const _Scene(text: 'café'),
        ),
        GoldenTestScenario(
          name: 'decomposed (NFD) cafe + acute',
          child: const _Scene(text: 'cafe\u0301'),
        ),
        GoldenTestScenario(
          name: 'diaeresis on i',
          child: const _Scene(text: 'naïve'),
        ),
      ],
    ),
  );
});

class _Scene extends StatelessWidget {
  const _Scene({required this.text});
  final String text;
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
          child: Text(text).roll(renderMode: kLegacyRenderMode).animate(
                trigger: 1,
                duration: const Duration(milliseconds: 400),
              ),
        ),
      ),
    );
  }
}
