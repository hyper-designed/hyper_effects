// This file pins the LEGACY (TextRenderMode.independentCharacters) path.
// Scenario names saying "currently broken" refer to legacy-path output —
// v0.4's default (contextualCharacters) renders these scripts correctly.

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

import '../../helpers/alchemist_config.dart';
import '../../helpers/test_app.dart';

void main() => withTextRendering(() {
  goldenTest(
    'rolling_complex_scripts_baseline',
    fileName: 'rolling_complex_scripts_goldens',
    builder: () => GoldenTestGroup(
      scenarioConstraints: const BoxConstraints(maxWidth: 400),
      children: [
        GoldenTestScenario(
          name: 'arabic (currently broken — isolated forms, logical order)',
          child: const _Scene(
            text: 'مرحبا',
            fontFamily: 'TestArabic',
            textDirection: TextDirection.rtl,
          ),
        ),
        GoldenTestScenario(
          name: 'japanese (LTR hiragana)',
          child: const _Scene(
            text: 'さよなら',
            fontFamily: 'TestJapanese',
            textDirection: TextDirection.ltr,
          ),
        ),
        GoldenTestScenario(
          name: 'devanagari (currently broken — no conjunct shaping)',
          child: const _Scene(
            text: 'नमस्ते',
            fontFamily: 'TestDevanagari',
            textDirection: TextDirection.ltr,
          ),
        ),
        GoldenTestScenario(
          name: 'mixed bidi (currently logical order, no reordering)',
          child: const _Scene(
            text: 'Hi مرحبا',
            fontFamily: 'TestLatin',
            textDirection: TextDirection.ltr,
          ),
        ),
      ],
    ),
  );
});

class _Scene extends StatelessWidget {
  const _Scene({
    required this.text,
    required this.fontFamily,
    required this.textDirection,
  });
  final String text;
  final String fontFamily;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: textDirection,
      child: DefaultTextStyle(
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: 48,
          color: const Color(0xFF111111),
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
