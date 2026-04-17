import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

import '../../helpers/alchemist_config.dart';
import '../../helpers/test_app.dart';

void main() => withTextRendering(() {
  goldenTest(
    'rolling_latin_baseline',
    fileName: 'rolling_latin_goldens',
    builder: () => GoldenTestGroup(
      scenarioConstraints: const BoxConstraints(maxWidth: 400),
      children: [
        GoldenTestScenario(
          name: 'hello settled at trigger 0',
          child: const _Scene(text: 'Hello', trigger: 0),
        ),
        GoldenTestScenario(
          name: 'hello settled at trigger 1',
          child: const _Scene(text: 'Hello', trigger: 1),
        ),
        GoldenTestScenario(
          name: 'number counter 999 to 1000',
          child: const _Scene(text: '1000', trigger: 1),
        ),
        GoldenTestScenario(
          name: 'with padding',
          child: const _Scene(
            text: 'abcd',
            padding: EdgeInsets.symmetric(horizontal: 6),
            trigger: 1,
          ),
        ),
        GoldenTestScenario(
          name: 'clip none',
          child: const _Scene(
            text: 'abcd',
            clipBehavior: Clip.none,
            trigger: 1,
          ),
        ),
        GoldenTestScenario(
          name: 'symbol distance multiplier 2',
          child: const _Scene(
            text: 'abcd',
            symbolDistanceMultiplier: 2,
            trigger: 1,
          ),
        ),
      ],
    ),
  );
});

class _Scene extends StatelessWidget {
  const _Scene({
    required this.text,
    this.trigger = 0,
    this.padding = EdgeInsets.zero,
    this.clipBehavior = Clip.hardEdge,
    this.symbolDistanceMultiplier = 1,
  });
  final String text;
  final int trigger;
  final EdgeInsets padding;
  final Clip clipBehavior;
  final double symbolDistanceMultiplier;

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
          child: Text(text)
              .roll(
                renderMode: kLegacyRenderMode,
                padding: padding,
                clipBehavior: clipBehavior,
                symbolDistanceMultiplier: symbolDistanceMultiplier,
              )
              .animate(
                trigger: trigger,
                duration: const Duration(milliseconds: 400),
              ),
        ),
      ),
    );
  }
}
